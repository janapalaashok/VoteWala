import type { Prisma } from "@prisma/client";
import { prisma } from "./db";
import { dateOnly, istDateString } from "./time";

export const pollCardInclude = {
  constituency: { select: { id: true, type: true, number: true, nameEn: true, nameTe: true, district: true, reservation: true } },
  options: {
    orderBy: { sortOrder: "asc" },
    include: {
      candidate: {
        select: { id: true, nameEn: true, nameTe: true, partyEn: true, partyTe: true, photoUrl: true, sourceUrl: true, sourceLabel: true, electionYear: true, status: true, isDemo: true },
      },
    },
  },
  report: { select: { totalVotes: true, generatedAt: true } },
} satisfies Prisma.PollInclude;

export type PollWithDetails = Prisma.PollGetPayload<{ include: typeof pollCardInclude }>;

export type PhaseFilter = "all" | "open" | "upcoming" | "closed";

export async function listPolls(opts: {
  type?: "ASSEMBLY" | "PARLIAMENTARY";
  phase?: PhaseFilter;
  district?: string;
  constituencyId?: string;
  candidateId?: string;
  take?: number;
  now?: Date;
}) {
  const now = opts.now ?? new Date();
  const where: Prisma.PollWhereInput = { status: "PUBLISHED" };
  if (opts.type || opts.district) {
    where.constituency = { ...(opts.type ? { type: opts.type } : {}), ...(opts.district ? { district: opts.district } : {}) };
  }
  if (opts.constituencyId) where.constituencyId = opts.constituencyId;
  if (opts.candidateId) where.options = { some: { candidateId: opts.candidateId } };
  if (opts.phase === "open") Object.assign(where, { opensAt: { lte: now }, closesAt: { gt: now } });
  if (opts.phase === "upcoming") Object.assign(where, { opensAt: { gt: now } });
  if (opts.phase === "closed") Object.assign(where, { closesAt: { lte: now } });
  return prisma.poll.findMany({
    where,
    include: pollCardInclude,
    orderBy: opts.phase === "closed" ? [{ closesAt: "desc" }] : [{ opensAt: "asc" }, { constituencyId: "asc" }],
    take: opts.take ?? 60,
  });
}

export async function todaysPolls(now = new Date()) {
  return prisma.poll.findMany({
    where: { status: "PUBLISHED", pollDate: dateOnly(istDateString(now)) },
    include: pollCardInclude,
    orderBy: [{ constituency: { type: "asc" } }, { constituencyId: "asc" }],
  });
}

export async function getPoll(id: string) {
  return prisma.poll.findUnique({ where: { id }, include: pollCardInclude });
}

export async function participationStats() {
  const [votes, polls, voters, constituencies] = await Promise.all([
    prisma.vote.count(),
    prisma.poll.count({ where: { status: "PUBLISHED", opensAt: { lte: new Date() } } }),
    prisma.user.count({ where: { phoneVerifiedAt: { not: null } } }),
    prisma.poll.findMany({ where: { status: "PUBLISHED" }, distinct: ["constituencyId"], select: { constituencyId: true } }),
  ]);
  return { votes, polls, voters, constituencies: constituencies.length };
}

export async function districts(): Promise<string[]> {
  const rows = await prisma.constituency.findMany({ distinct: ["district"], select: { district: true }, orderBy: { district: "asc" } });
  return rows.map((r) => r.district);
}
