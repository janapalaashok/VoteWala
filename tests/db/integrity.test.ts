import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import { PrismaClient } from "@prisma/client";

const enabled = Boolean(process.env.TEST_DATABASE_URL);
vi.spyOn(console, "info").mockImplementation(() => {});

describe.skipIf(!enabled)("database integrity (PostgreSQL)", async () => {
  const { castVote } = await import("@/lib/vote");
  const { requestOtp, verifyOtp, hashOtp, OTP_MAX_ATTEMPTS } = await import("@/lib/otp");
  const { finalizeClosedPolls } = await import("@/lib/finalize");
  const { getPublicResults } = await import("@/lib/results");
  const prisma = new PrismaClient();
  let seq = 0;

  async function user(verified = true) {
    seq++;
    return prisma.user.create({ data: { email: `u${seq}-${Date.now()}@test.invalid`, phoneVerifiedAt: verified ? new Date() : null } });
  }

  async function poll(opts: { opensAt?: Date; closesAt?: Date; policy?: "LIVE" | "DELAYED" | "AFTER_CLOSE"; status?: "DRAFT" | "PUBLISHED" } = {}) {
    const now = Date.now();
    return prisma.poll.create({
      data: {
        constituencyId: "AC-087",
        questionEn: "Q?",
        questionTe: "ప్ర?",
        pollDate: new Date("2026-01-01"),
        opensAt: opts.opensAt ?? new Date(now - 3_600_000),
        closesAt: opts.closesAt ?? new Date(now + 3_600_000),
        status: opts.status ?? "PUBLISHED",
        resultPolicy: opts.policy ?? "LIVE",
        options: { create: [{ labelEn: "A", sortOrder: 0 }, { labelEn: "B", sortOrder: 1 }] },
      },
      include: { options: true },
    });
  }

  beforeAll(async () => {
    await prisma.constituency.upsert({
      where: { id: "AC-087" },
      update: {},
      create: { id: "AC-087", type: "ASSEMBLY", number: 87, nameEn: "Mangalagiri", nameTe: "మంగళగిరి", district: "Guntur", sourceUrl: "https://eci.gov.in/" },
    });
  });
  afterAll(() => prisma.$disconnect());

  it("allows exactly one vote per user per poll, even under concurrent requests", async () => {
    const u = await user();
    const p = await poll();
    const results = await Promise.all(Array.from({ length: 8 }, (_, i) => castVote(u.id, p.id, p.options[i % 2].id)));
    expect(results.filter((r) => r.ok)).toHaveLength(1);
    expect(results.filter((r) => !r.ok && r.error === "already_voted")).toHaveLength(7);
    expect(await prisma.vote.count({ where: { pollId: p.id } })).toBe(1);
  });

  it("rejects duplicate votes at the database level, bypassing application checks", async () => {
    const u = await user();
    const p = await poll();
    await prisma.vote.create({ data: { pollId: p.id, optionId: p.options[0].id, userId: u.id } });
    await expect(prisma.vote.create({ data: { pollId: p.id, optionId: p.options[1].id, userId: u.id } })).rejects.toMatchObject({ code: "P2002" });
  });

  it("requires a verified mobile number to vote", async () => {
    const u = await user(false);
    const p = await poll();
    expect(await castVote(u.id, p.id, p.options[0].id)).toEqual({ ok: false, error: "phone_not_verified" });
  });

  it("refuses votes outside the poll window using the database clock", async () => {
    const u = await user();
    const closed = await poll({ opensAt: new Date(Date.now() - 7_200_000), closesAt: new Date(Date.now() - 3_600_000) });
    const upcoming = await poll({ opensAt: new Date(Date.now() + 3_600_000), closesAt: new Date(Date.now() + 7_200_000) });
    const draft = await poll({ status: "DRAFT" });
    expect(await castVote(u.id, closed.id, closed.options[0].id)).toEqual({ ok: false, error: "not_open" });
    // Direct inserts are stopped by the trigger even if the app check is skipped.
    for (const p of [closed, upcoming, draft]) {
      await expect(prisma.vote.create({ data: { pollId: p.id, optionId: p.options[0].id, userId: u.id } })).rejects.toThrow(/poll is not (open|published)/);
    }
  });

  it("rejects an option that belongs to a different poll", async () => {
    const u = await user();
    const p1 = await poll();
    const p2 = await poll();
    expect(await castVote(u.id, p1.id, p2.options[0].id)).toEqual({ ok: false, error: "invalid_option" });
    await expect(prisma.vote.create({ data: { pollId: p1.id, optionId: p2.options[0].id, userId: u.id } })).rejects.toThrow();
  });

  it("makes votes immutable and stamps them with database time", async () => {
    const u = await user();
    const p = await poll();
    const before = Date.now();
    const v = await prisma.vote.create({ data: { pollId: p.id, optionId: p.options[0].id, userId: u.id, createdAt: new Date("2000-01-01") } });
    expect(v.createdAt.getTime()).toBeGreaterThan(before - 60_000);
    await expect(prisma.vote.update({ where: { id: v.id }, data: { optionId: p.options[1].id } })).rejects.toThrow(/immutable/);
  });

  it("links each verified mobile number to only one account", async () => {
    const a = await user();
    const b = await user();
    await prisma.user.update({ where: { id: a.id }, data: { phone: "+919000000001" } });
    await expect(prisma.user.update({ where: { id: b.id }, data: { phone: "+919000000001" } })).rejects.toMatchObject({ code: "P2002" });
    await expect(prisma.user.update({ where: { id: b.id }, data: { phone: "12345" } })).rejects.toThrow();
  });

  it("verifies a mobile number with OTP, enforcing attempt limits and resend cooldown", async () => {
    const u = await user(false);
    expect(await requestOtp(u.id, "+919000000002")).toEqual({ ok: true });
    expect(await requestOtp(u.id, "+919000000002")).toEqual({ ok: false, error: "cooldown" });
    // Swap in a known code so the test can complete the flow.
    const ch = await prisma.otpChallenge.findFirstOrThrow({ where: { userId: u.id, consumedAt: null } });
    await prisma.otpChallenge.update({ where: { id: ch.id }, data: { codeHash: hashOtp("+919000000002", "424242") } });
    expect(await verifyOtp(u.id, "000000")).toEqual({ ok: false, error: "invalid_code" });
    expect(await verifyOtp(u.id, "424242")).toEqual({ ok: true });
    const after = await prisma.user.findUniqueOrThrow({ where: { id: u.id } });
    expect(after.phone).toBe("+919000000002");
    expect(after.phoneVerifiedAt).not.toBeNull();
    expect(await verifyOtp(u.id, "424242")).toEqual({ ok: false, error: "no_challenge" });

    const v = await user(false);
    await requestOtp(v.id, "+919000000003");
    for (let i = 0; i < OTP_MAX_ATTEMPTS; i++) await verifyOtp(v.id, "999999");
    expect(await verifyOtp(v.id, "999999")).toEqual({ ok: false, error: "too_many_attempts" });

    const w = await user(false);
    expect(await requestOtp(w.id, "+919000000002")).toEqual({ ok: false, error: "phone_taken" });
  });

  it("hides AFTER_CLOSE results while open and freezes a final report after close", async () => {
    const p = await poll({ policy: "AFTER_CLOSE", closesAt: new Date(Date.now() + 2000) });
    for (let i = 0; i < 3; i++) {
      const u = await user();
      expect((await castVote(u.id, p.id, p.options[i === 0 ? 1 : 0].id)).ok).toBe(true);
    }
    expect((await getPublicResults(p.id)).visibility.visible).toBe(false);
    await new Promise((r) => setTimeout(r, 2200));
    const finalized = await finalizeClosedPolls();
    expect(finalized).toContain(p.id);
    expect(await finalizeClosedPolls()).not.toContain(p.id); // idempotent
    const res = await getPublicResults(p.id);
    expect(res.finalized).toBe(true);
    expect(res.total).toBe(3);
    expect(res.rows.find((r) => r.optionId === p.options[0].id)?.votes).toBe(2);
  });

  it("keeps the audit log append-only", async () => {
    const entry = await prisma.auditLog.create({ data: { action: "test", entityType: "Test" } });
    await expect(prisma.auditLog.update({ where: { id: entry.id }, data: { action: "tampered" } })).rejects.toThrow(/append-only/);
    await expect(prisma.auditLog.delete({ where: { id: entry.id } })).rejects.toThrow(/append-only/);
  });
});
