import { prisma } from "./db";
import { tallyVotes, withShares } from "./results";
import { audit } from "./audit";

/** Aggregated result rows for a poll. Contains totals only — never individual votes. */
export async function pollResultRows(pollId: string, now = new Date()) {
  const poll = await prisma.poll.findUniqueOrThrow({
    where: { id: pollId },
    include: { constituency: true, report: true, options: { include: { candidate: true }, orderBy: { sortOrder: "asc" } } },
  });
  const final = Boolean(poll.report);
  const tallies = poll.report
    ? (poll.report.tallies as unknown as { optionId: string; votes: number }[])
    : await tallyVotes(poll.id, now < poll.closesAt ? now : poll.closesAt);
  const shares = new Map(withShares(tallies).map((r) => [r.optionId, r]));
  const total = tallies.reduce((s, t) => s + t.votes, 0);
  return poll.options.map((o) => {
    const r = shares.get(o.id);
    return [
      poll.id,
      poll.pollDate.toISOString().slice(0, 10),
      poll.constituency.id,
      poll.constituency.nameEn,
      poll.constituency.type,
      poll.status,
      final ? "FINAL" : "PROVISIONAL",
      o.candidate?.nameEn ?? o.labelEn ?? "None of these",
      o.candidate?.partyEn ?? "",
      o.candidate?.sourceUrl ?? "",
      r?.votes ?? 0,
      total ? ((r?.share ?? 0) * 100).toFixed(1) : "0.0",
      total,
    ];
  });
}

export const RESULT_HEADER = [
  "poll_id", "poll_date_ist", "constituency_id", "constituency", "type", "status", "report", "option", "party", "official_source", "votes", "share_pct", "poll_total",
];

export async function auditExport(actorId: string, what: string, metadata: Record<string, string>) {
  await audit({ actorId, action: `export.${what}`, entityType: "Export", metadata });
}

export function csvResponse(body: string, filename: string) {
  return new Response("﻿" + body, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Cache-Control": "no-store",
    },
  });
}
