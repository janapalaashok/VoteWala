// Seeds the Andhra Pradesh constituency directory (idempotent).
//   npm run db:seed          directory only
//   npm run db:seed:demo     directory + clearly-labelled demonstration data
//
// Demo data uses fictional names ("Demo Candidate A", "Sample Party A") and is
// flagged isDemo so the UI marks it. Never run --demo against production.

import { PrismaClient } from "@prisma/client";
import { ASSEMBLY, DIRECTORY_SOURCE_URL, PARLIAMENTARY, acId, pcId } from "../src/data/constituencies";
import { addDays, dailyWindow, dateOnly, istDateString } from "../src/lib/time";

const prisma = new PrismaClient();

async function seedDirectory() {
  for (const pc of PARLIAMENTARY) {
    const data = { type: "PARLIAMENTARY" as const, number: pc.no, nameEn: pc.en, nameTe: pc.te, reservation: pc.res, district: "", sourceUrl: DIRECTORY_SOURCE_URL };
    await prisma.constituency.upsert({ where: { id: pcId(pc.no) }, update: data, create: { id: pcId(pc.no), ...data } });
  }
  const pcDistricts = new Map<number, Set<string>>();
  for (const ac of ASSEMBLY) {
    const data = {
      type: "ASSEMBLY" as const,
      number: ac.no,
      nameEn: ac.en,
      nameTe: ac.te,
      reservation: ac.res,
      district: ac.district,
      parentId: pcId(ac.pc),
      sourceUrl: DIRECTORY_SOURCE_URL,
    };
    await prisma.constituency.upsert({ where: { id: acId(ac.no) }, update: data, create: { id: acId(ac.no), ...data } });
    if (!pcDistricts.has(ac.pc)) pcDistricts.set(ac.pc, new Set());
    pcDistricts.get(ac.pc)!.add(ac.district);
  }
  // A Lok Sabha constituency's "district" lists the districts its segments fall in.
  for (const [pc, ds] of pcDistricts) {
    await prisma.constituency.update({ where: { id: pcId(pc) }, data: { district: [...ds].join(" / ") } });
  }
  console.log(`✔ ${PARLIAMENTARY.length} Lok Sabha + ${ASSEMBLY.length} Assembly constituencies`);
}

const DEMO_SOURCE = "https://eci.gov.in/";
const DEMO_LABEL = "Demonstration record — not a real candidate";
const DEMO_PARTIES = [
  ["Sample Party A", "నమూనా పార్టీ ఎ"],
  ["Sample Party B", "నమూనా పార్టీ బి"],
  ["Sample Party C", "నమూనా పార్టీ సి"],
  ["Independent", "స్వతంత్ర"],
];
const LETTERS = ["A", "B", "C", "D"];
const LETTERS_TE = ["ఎ", "బి", "సి", "డి"];

async function seedDemo() {
  if (process.env.NODE_ENV === "production" && !process.argv.includes("--force")) {
    throw new Error("Refusing to seed demo data in production (pass --force to override)");
  }
  const targets = ["AC-079", "AC-021", "AC-094", "AC-167", "PC-12", "PC-04"];
  const today = istDateString();
  const voters = await Promise.all(
    Array.from({ length: 160 }, (_, i) =>
      prisma.user.upsert({
        where: { email: `demo-voter-${i}@votewala.invalid` },
        update: {},
        create: { email: `demo-voter-${i}@votewala.invalid`, name: `Demo voter ${i}`, phoneVerifiedAt: new Date() },
      }),
    ),
  );

  for (const [ti, cid] of targets.entries()) {
    const c = await prisma.constituency.findUniqueOrThrow({ where: { id: cid } });
    const cands = [];
    for (let i = 0; i < 4; i++) {
      const nameEn = `Demo Candidate ${LETTERS[i]} (${c.nameEn})`;
      const cand = await prisma.candidate.upsert({
        where: { constituencyId_electionYear_nameEn: { constituencyId: cid, electionYear: 2029, nameEn } },
        update: {},
        create: {
          constituencyId: cid,
          nameEn,
          nameTe: `డెమో అభ్యర్థి ${LETTERS_TE[i]} (${c.nameTe})`,
          partyEn: DEMO_PARTIES[i][0],
          partyTe: DEMO_PARTIES[i][1],
          electionYear: 2029,
          sourceUrl: DEMO_SOURCE,
          sourceLabel: DEMO_LABEL,
          status: "VERIFIED",
          verifiedAt: new Date(),
          isDemo: true,
        },
      });
      cands.push(cand);
    }
    const office = c.type === "ASSEMBLY" ? "MLA" : "MP";
    const officeTe = c.type === "ASSEMBLY" ? "ఎమ్మెల్యే" : "ఎంపీ";
    const policies = ["LIVE", "AFTER_CLOSE", "DELAYED"] as const;
    for (const [offset, label] of [[-2, "past"], [-1, "past"], [0, "today"], [1, "future"]] as const) {
      const date = addDays(today, offset);
      const exists = await prisma.poll.findFirst({ where: { constituencyId: cid, pollDate: dateOnly(date), isDemo: true } });
      if (exists) continue;
      const { opensAt, closesAt } = dailyWindow(date);
      const policy = policies[ti % 3];
      const poll = await prisma.poll.create({
        data: {
          constituencyId: cid,
          questionEn: `Who do you prefer as the ${office} for ${c.nameEn}?`,
          questionTe: `${c.nameTe} ${officeTe}గా మీరు ఎవరిని ఇష్టపడతారు?`,
          pollDate: dateOnly(date),
          opensAt,
          closesAt,
          status: "PUBLISHED",
          resultPolicy: policy,
          publishDelayMinutes: policy === "DELAYED" ? 60 : 0,
          isDemo: true,
          options: {
            create: [
              ...cands.map((cd, i) => ({ candidateId: cd.id, sortOrder: i })),
              { labelEn: "None of these", labelTe: "పైవేవీ కాదు", sortOrder: 999 },
            ],
          },
        },
        include: { options: true },
      });
      if (label === "future") continue;
      // Synthetic votes. The vote guard trigger only admits votes inside the poll
      // window by DB clock, so it is bypassed for back-dated demo rows.
      const weights = [0.34, 0.29, 0.21, 0.09, 0.07].map((w, i) => w + ((ti + i + offset + 5) % 3) * 0.03);
      const n = label === "today" ? 45 + ti * 7 : 80 + ti * 12 + (offset + 2) * 9;
      const sum = weights.reduce((a, b) => a + b, 0);
      const rows = voters.slice(0, Math.min(n, voters.length)).map((v, k) => {
        let r = ((k * 9301 + 49297 + ti * 233) % 233280) / 233280 * sum;
        let idx = 0;
        while (r > weights[idx] && idx < weights.length - 1) r -= weights[idx++];
        const createdAt = label === "today" ? new Date(Math.min(Date.now() - 1000, opensAt.getTime() + k * 60_000)) : new Date(opensAt.getTime() + k * 300_000);
        return { pollId: poll.id, optionId: poll.options[idx].id, userId: v.id, createdAt };
      });
      await prisma.$transaction([
        prisma.$executeRawUnsafe('ALTER TABLE "Vote" DISABLE TRIGGER "Vote_guard"'),
        prisma.vote.createMany({ data: rows, skipDuplicates: true }),
        prisma.$executeRawUnsafe('ALTER TABLE "Vote" ENABLE TRIGGER "Vote_guard"'),
      ]);
    }
  }
  console.log(`✔ Demo data for ${targets.length} constituencies (fictional candidates, flagged isDemo)`);
}

async function main() {
  await seedDirectory();
  if (process.argv.includes("--demo")) {
    await seedDemo();
    const { finalizeClosedPolls } = await import("../src/lib/finalize");
    const done = await finalizeClosedPolls();
    console.log(`✔ Finalized ${done.length} closed demo polls`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
