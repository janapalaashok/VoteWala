import { prisma } from "./db";
import { tallyVotes } from "./results";
import { audit } from "./audit";

/**
 * Freezes the end-of-day result of every published poll that has closed and
 * has no report yet. Idempotent: safe to run from cron as often as you like.
 */
export async function finalizeClosedPolls(now = new Date(), actorId: string | null = null): Promise<string[]> {
  const due = await prisma.poll.findMany({
    where: { status: "PUBLISHED", closesAt: { lte: now }, report: null },
    select: { id: true, closesAt: true },
  });
  const done: string[] = [];
  for (const poll of due) {
    const tallies = await tallyVotes(poll.id, poll.closesAt);
    const totalVotes = tallies.reduce((s, t) => s + t.votes, 0);
    const created = await prisma.pollReport.createMany({
      data: [{ pollId: poll.id, totalVotes, tallies: tallies as unknown as object[], generatedAt: now }],
      skipDuplicates: true,
    });
    if (created.count === 1) {
      await audit({ actorId, action: "poll.finalized", entityType: "Poll", entityId: poll.id, metadata: { totalVotes } });
      done.push(poll.id);
    }
  }
  return done;
}
