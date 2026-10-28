"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { prisma } from "@/lib/db";
import { assertAdmin } from "@/lib/session";
import { audit } from "@/lib/audit";
import { addDays, dailyWindow, dateOnly } from "@/lib/time";
import { parseCandidateCsv } from "@/lib/candidates-import";
import { finalizeClosedPolls } from "@/lib/finalize";

// ---------- Candidates ----------

export type ImportState = { done: boolean; created?: number; updated?: number; errors?: { line: number; message: string }[] };

export async function importCandidatesAction(_prev: ImportState, form: FormData): Promise<ImportState> {
  const admin = await assertAdmin();
  const file = form.get("file");
  let text = String(form.get("csv") ?? "");
  if (file instanceof File && file.size > 0) {
    if (file.size > 2_000_000) return { done: true, errors: [{ line: 0, message: "File larger than 2 MB" }] };
    text = await file.text();
  }
  if (!text.trim()) return { done: true, errors: [{ line: 0, message: "No CSV provided" }] };
  const known = new Set((await prisma.constituency.findMany({ select: { id: true } })).map((c) => c.id));
  const { rows, errors } = parseCandidateCsv(text, known);
  if (errors.length) return { done: true, errors };

  let created = 0;
  let updated = 0;
  await prisma.$transaction(async (tx) => {
    for (const r of rows) {
      const key = { constituencyId_electionYear_nameEn: { constituencyId: r.constituencyId, electionYear: r.electionYear, nameEn: r.nameEn } };
      const existing = await tx.candidate.findUnique({ where: key });
      if (existing) {
        // Any change to an imported record sends it back for re-verification.
        await tx.candidate.update({ where: { id: existing.id }, data: { ...r, status: "PENDING", verifiedAt: null, verifiedById: null } });
        updated++;
      } else {
        await tx.candidate.create({ data: { ...r, status: "PENDING" } });
        created++;
      }
    }
    await audit({ actorId: admin.id, action: "candidates.imported", entityType: "Candidate", metadata: { created, updated } }, tx);
  });
  revalidatePath("/admin/candidates");
  return { done: true, created, updated, errors: [] };
}

export async function setCandidateStatusAction(form: FormData) {
  const admin = await assertAdmin();
  const id = String(form.get("id"));
  const status = String(form.get("status"));
  if (status !== "VERIFIED" && status !== "REJECTED" && status !== "PENDING") throw new Error("Invalid status");
  await prisma.$transaction(async (tx) => {
    await tx.candidate.update({
      where: { id },
      data: status === "VERIFIED" ? { status, verifiedAt: new Date(), verifiedById: admin.id } : { status, verifiedAt: null, verifiedById: null },
    });
    await audit({ actorId: admin.id, action: `candidate.${status.toLowerCase()}`, entityType: "Candidate", entityId: id }, tx);
  });
  revalidatePath("/admin/candidates");
  revalidatePath("/candidates");
}

// ---------- Polls ----------

const pollSchema = z.object({
  constituencyId: z.string().regex(/^(AC-\d{3}|PC-\d{2})$/),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  days: z.coerce.number().int().min(1).max(31),
  openTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  closeTime: z.string().regex(/^(([01]\d|2[0-3]):[0-5]\d|24:00)$/),
  resultPolicy: z.enum(["LIVE", "DELAYED", "AFTER_CLOSE"]),
  publishDelayMinutes: z.coerce.number().int().min(0).max(1440),
  questionEn: z.string().trim().min(5).max(300),
  questionTe: z.string().trim().min(2).max(300),
  candidateIds: z.array(z.string().min(1)).min(1).max(30),
  includeNone: z.boolean(),
  publish: z.boolean(),
});

export type CreatePollState = { error?: string };

export async function createPollsAction(_prev: CreatePollState, form: FormData): Promise<CreatePollState> {
  const admin = await assertAdmin();
  const parsed = pollSchema.safeParse({
    constituencyId: form.get("constituencyId"),
    startDate: form.get("startDate"),
    days: form.get("days"),
    openTime: form.get("openTime"),
    closeTime: form.get("closeTime"),
    resultPolicy: form.get("resultPolicy"),
    publishDelayMinutes: form.get("publishDelayMinutes") || 0,
    questionEn: form.get("questionEn"),
    questionTe: form.get("questionTe"),
    candidateIds: form.getAll("candidateIds").map(String),
    includeNone: form.get("includeNone") === "on",
    publish: form.get("publish") === "on",
  });
  if (!parsed.success) return { error: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ") };
  const d = parsed.data;
  if (d.resultPolicy === "DELAYED" && d.publishDelayMinutes < 1) return { error: "Delayed results need a delay of at least 1 minute" };
  if (d.candidateIds.length + (d.includeNone ? 1 : 0) < 2) return { error: "A poll needs at least two options" };

  const candidates = await prisma.candidate.findMany({
    where: { id: { in: d.candidateIds }, constituencyId: d.constituencyId, status: "VERIFIED" },
    orderBy: { nameEn: "asc" },
  });
  if (candidates.length !== new Set(d.candidateIds).size) {
    return { error: "Every candidate must be verified and belong to the selected constituency" };
  }

  let windows: { date: string; opensAt: Date; closesAt: Date }[];
  try {
    windows = Array.from({ length: d.days }, (_, i) => {
      const date = addDays(d.startDate, i);
      return { date, ...dailyWindow(date, d.openTime, d.closeTime) };
    });
  } catch (e) {
    return { error: (e as Error).message };
  }
  if (d.publish && windows[0].closesAt <= new Date()) return { error: "Cannot publish a poll that has already closed" };

  const ids: string[] = [];
  await prisma.$transaction(async (tx) => {
    for (const w of windows) {
      const poll = await tx.poll.create({
        data: {
          constituencyId: d.constituencyId,
          questionEn: d.questionEn,
          questionTe: d.questionTe,
          pollDate: dateOnly(w.date),
          opensAt: w.opensAt,
          closesAt: w.closesAt,
          resultPolicy: d.resultPolicy,
          publishDelayMinutes: d.resultPolicy === "DELAYED" ? d.publishDelayMinutes : 0,
          status: d.publish ? "PUBLISHED" : "DRAFT",
          createdById: admin.id,
          options: {
            create: [
              ...candidates.map((c, i) => ({ candidateId: c.id, sortOrder: i })),
              ...(d.includeNone ? [{ labelEn: "None of these", labelTe: "పైవేవీ కాదు", sortOrder: 999 }] : []),
            ],
          },
        },
      });
      ids.push(poll.id);
      await audit(
        { actorId: admin.id, action: "poll.created", entityType: "Poll", entityId: poll.id, metadata: { date: w.date, status: poll.status, resultPolicy: d.resultPolicy } },
        tx,
      );
    }
  });
  revalidatePath("/admin/polls");
  redirect("/admin/polls");
}

export async function setPollStatusAction(form: FormData) {
  const admin = await assertAdmin();
  const id = String(form.get("id"));
  const status = String(form.get("status"));
  const poll = await prisma.poll.findUniqueOrThrow({ where: { id } });
  if (status === "PUBLISHED") {
    if (poll.status !== "DRAFT") throw new Error("Only drafts can be published");
    if (poll.closesAt <= new Date()) throw new Error("Poll has already closed");
  } else if (status === "CANCELLED") {
    if (poll.status === "CANCELLED") return;
  } else {
    throw new Error("Invalid status");
  }
  await prisma.$transaction(async (tx) => {
    await tx.poll.update({ where: { id }, data: { status: status as "PUBLISHED" | "CANCELLED" } });
    await audit({ actorId: admin.id, action: `poll.${status.toLowerCase()}`, entityType: "Poll", entityId: id }, tx);
  });
  revalidatePath("/admin/polls");
  revalidatePath("/");
}

export async function runFinalizerAction() {
  const admin = await assertAdmin();
  await finalizeClosedPolls(new Date(), admin.id);
  revalidatePath("/admin");
  revalidatePath("/results");
}
