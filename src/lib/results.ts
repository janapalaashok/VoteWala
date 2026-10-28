import type { Poll, PollStatus, ResultPolicy } from "@prisma/client";
import { prisma } from "./db";

export type PollPhase = "upcoming" | "open" | "closed" | "cancelled" | "draft";

export function pollPhase(poll: Pick<Poll, "status" | "opensAt" | "closesAt">, now = new Date()): PollPhase {
  if (poll.status === "CANCELLED") return "cancelled";
  if (poll.status === "DRAFT") return "draft";
  if (now < poll.opensAt) return "upcoming";
  if (now < poll.closesAt) return "open";
  return "closed";
}

export type Visibility =
  | { visible: false; reason: "not_started" | "hidden_until_close" | "unavailable" | "blackout"; revealAt: Date | null }
  | { visible: true; reason: "live" | "delayed" | "final"; cutoff: Date };

/** Decides what a member of the public may see of a poll's results at `now`. */
export function resultVisibility(
  poll: { status: PollStatus; opensAt: Date; closesAt: Date; resultPolicy: ResultPolicy; publishDelayMinutes: number },
  now = new Date(),
): Visibility {
  if (poll.status !== "PUBLISHED") return { visible: false, reason: "unavailable", revealAt: null };
  if (now < poll.opensAt) return { visible: false, reason: "not_started", revealAt: null };
  if (now >= poll.closesAt) return { visible: true, reason: "final", cutoff: poll.closesAt };
  switch (poll.resultPolicy) {
    case "LIVE":
      return { visible: true, reason: "live", cutoff: now };
    case "DELAYED":
      return { visible: true, reason: "delayed", cutoff: new Date(now.getTime() - poll.publishDelayMinutes * 60_000) };
    case "AFTER_CLOSE":
      return { visible: false, reason: "hidden_until_close", revealAt: poll.closesAt };
  }
}

/**
 * Legal results blackout windows, e.g. the 48 hours before polling (RP Act 1951,
 * s.126) or exit-poll periods notified under s.126A. Configured as
 * RESULTS_BLACKOUT="2029-04-09T18:00+05:30/2029-04-11T18:00+05:30,..."
 * Returns the end of the active window, or null.
 */
export function activeBlackout(now = new Date(), spec = process.env.RESULTS_BLACKOUT ?? ""): Date | null {
  for (const range of spec.split(",").map((r) => r.trim()).filter(Boolean)) {
    const [a, b] = range.split("/").map((x) => new Date(x));
    if (Number.isNaN(a?.getTime()) || Number.isNaN(b?.getTime())) continue;
    if (now >= a && now < b) return b;
  }
  return null;
}

export function minSample(): number {
  const n = Number(process.env.RESULTS_MIN_SAMPLE ?? 30);
  return Number.isFinite(n) && n >= 0 ? n : 30;
}

export interface Tally {
  optionId: string;
  votes: number;
}

export interface ResultRow extends Tally {
  share: number; // 0..1
}

/** Shares rounded to one decimal place using largest-remainder so they total 100%. */
export function withShares(tallies: Tally[]): ResultRow[] {
  const total = tallies.reduce((s, t) => s + t.votes, 0);
  if (total === 0) return tallies.map((t) => ({ ...t, share: 0 }));
  const units = 1000;
  const raw = tallies.map((t) => (t.votes / total) * units);
  const floors = raw.map(Math.floor);
  let remaining = units - floors.reduce((a, b) => a + b, 0);
  const order = raw.map((r, i) => ({ i, rem: r - floors[i] })).sort((a, b) => b.rem - a.rem);
  for (const { i } of order) {
    if (remaining <= 0) break;
    floors[i] += 1;
    remaining -= 1;
  }
  return tallies.map((t, i) => ({ ...t, share: floors[i] / units }));
}

export async function tallyVotes(pollId: string, cutoff: Date): Promise<Tally[]> {
  const options = await prisma.pollOption.findMany({ where: { pollId }, select: { id: true }, orderBy: { sortOrder: "asc" } });
  const grouped = await prisma.vote.groupBy({
    by: ["optionId"],
    where: { pollId, createdAt: { lt: cutoff } },
    _count: { _all: true },
  });
  const counts = new Map(grouped.map((g) => [g.optionId, g._count._all]));
  return options.map((o) => ({ optionId: o.id, votes: counts.get(o.id) ?? 0 }));
}

export interface PublicResults {
  visibility: Visibility;
  rows: ResultRow[];
  total: number;
  belowMinSample: boolean;
  finalized: boolean;
  asOf: Date | null;
}

export async function getPublicResults(pollId: string, now = new Date()): Promise<PublicResults> {
  const poll = await prisma.poll.findUniqueOrThrow({ where: { id: pollId }, include: { report: true } });
  const blackoutEnd = activeBlackout(now);
  const visibility: Visibility = blackoutEnd
    ? { visible: false, reason: "blackout", revealAt: blackoutEnd }
    : resultVisibility(poll, now);
  if (!visibility.visible) {
    return { visibility, rows: [], total: 0, belowMinSample: false, finalized: false, asOf: null };
  }
  let tallies: Tally[];
  let finalized = false;
  if (poll.report) {
    tallies = poll.report.tallies as unknown as Tally[];
    finalized = true;
  } else {
    tallies = await tallyVotes(pollId, visibility.cutoff);
  }
  const total = tallies.reduce((s, t) => s + t.votes, 0);
  return {
    visibility,
    rows: withShares(tallies),
    total,
    belowMinSample: total < minSample(),
    finalized,
    asOf: visibility.cutoff,
  };
}
