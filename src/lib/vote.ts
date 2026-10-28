import { Prisma } from "@prisma/client";
import { prisma } from "./db";
import { pollPhase } from "./results";

export type VoteResult =
  | { ok: true }
  | { ok: false; error: "not_found" | "not_open" | "invalid_option" | "phone_not_verified" | "already_voted" };

/**
 * Records a vote. Application checks give friendly errors; the database is the
 * final authority (unique (pollId, userId), option/poll composite foreign key,
 * and a trigger that rejects votes outside the poll window by DB clock).
 */
export async function castVote(userId: string, pollId: string, optionId: string, now = new Date()): Promise<VoteResult> {
  const [user, poll] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId }, select: { phoneVerifiedAt: true } }),
    prisma.poll.findUnique({ where: { id: pollId }, include: { options: { select: { id: true } } } }),
  ]);
  if (!user?.phoneVerifiedAt) return { ok: false, error: "phone_not_verified" };
  if (!poll) return { ok: false, error: "not_found" };
  if (pollPhase(poll, now) !== "open") return { ok: false, error: "not_open" };
  if (!poll.options.some((o) => o.id === optionId)) return { ok: false, error: "invalid_option" };

  try {
    await prisma.vote.create({ data: { pollId, optionId, userId } });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError) {
      if (err.code === "P2002") return { ok: false, error: "already_voted" };
      if (err.code === "P2003") return { ok: false, error: "invalid_option" };
    }
    if (err instanceof Error && /poll is not (open|published)/.test(err.message)) {
      return { ok: false, error: "not_open" };
    }
    throw err;
  }
  return { ok: true };
}

export async function userVote(userId: string, pollId: string) {
  return prisma.vote.findUnique({ where: { pollId_userId: { pollId, userId } }, select: { optionId: true, createdAt: true } });
}
