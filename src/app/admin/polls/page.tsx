import Link from "next/link";
import type { PollStatus } from "@prisma/client";
import { prisma } from "@/lib/db";
import { formatIst } from "@/lib/time";
import { setPollStatusAction } from "../actions";
import { ConfirmButton } from "@/components/admin/ConfirmButton";

const STATUSES: PollStatus[] = ["DRAFT", "PUBLISHED", "CANCELLED"];

export default async function AdminPolls({ searchParams }: { searchParams: Promise<{ status?: string }> }) {
  const sp = await searchParams;
  const status = STATUSES.includes(sp.status as PollStatus) ? (sp.status as PollStatus) : undefined;
  const polls = await prisma.poll.findMany({
    where: status ? { status } : {},
    include: { constituency: true, report: true, _count: { select: { votes: true, options: true } } },
    orderBy: [{ opensAt: "desc" }],
    take: 200,
  });
  const now = new Date();
  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">Polls</h1>
        <Link href="/admin/polls/new" className="btn-primary min-h-[40px] text-sm">Schedule polls</Link>
      </div>
      <div className="mb-4 flex gap-1 text-sm">
        {[undefined, ...STATUSES].map((s) => (
          <Link key={s ?? "all"} href={s ? `/admin/polls?status=${s}` : "/admin/polls"} className={`rounded-lg px-3 py-1.5 font-semibold ${s === status ? "bg-brand-navy text-white" : "text-muted hover:bg-surface"}`}>
            {s ?? "All"}
          </Link>
        ))}
      </div>
      <div className="card overflow-x-auto">
        <table className="w-full min-w-[820px] text-left text-sm">
          <thead className="text-muted">
            <tr className="border-b border-line">
              <th className="px-4 py-3">Constituency</th>
              <th className="px-4 py-3">Opens (IST)</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Policy</th>
              <th className="px-4 py-3 text-right">Options</th>
              <th className="px-4 py-3 text-right">Votes</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {polls.map((p) => (
              <tr key={p.id} className="border-b border-line/70 align-middle">
                <td className="px-4 py-3 font-semibold">
                  {p.status !== "DRAFT" ? <Link href={`/polls/${p.id}`} className="hover:underline">{p.constituency.nameEn}</Link> : p.constituency.nameEn}
                  <span className="ml-1 text-xs font-normal text-muted">{p.constituency.id}</span>
                  {p.isDemo && <span className="chip ml-2 bg-amber-50 text-amber-800">demo</span>}
                </td>
                <td className="px-4 py-3">{formatIst(p.opensAt, "en")}</td>
                <td className="px-4 py-3">
                  {p.status}
                  {p.report && <span className="ml-1 text-xs text-brand-green-ink">· final</span>}
                </td>
                <td className="px-4 py-3">{p.resultPolicy}{p.resultPolicy === "DELAYED" && ` (${p.publishDelayMinutes}m)`}</td>
                <td className="px-4 py-3 text-right tabular-nums">{p._count.options}</td>
                <td className="px-4 py-3 text-right tabular-nums">{p._count.votes}</td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-2">
                    {p.status === "DRAFT" && p.closesAt > now && (
                      <form action={setPollStatusAction}>
                        <input type="hidden" name="id" value={p.id} />
                        <input type="hidden" name="status" value="PUBLISHED" />
                        <button className="rounded-lg bg-brand-green-ink px-3 py-1.5 text-xs font-semibold text-white">Publish</button>
                      </form>
                    )}
                    {p.status !== "CANCELLED" && (
                      <form action={setPollStatusAction}>
                        <input type="hidden" name="id" value={p.id} />
                        <input type="hidden" name="status" value="CANCELLED" />
                        <ConfirmButton message="Cancel this poll? Its results will no longer be shown publicly." className="rounded-lg border border-line px-3 py-1.5 text-xs font-semibold text-red-700 hover:bg-red-50">Cancel</ConfirmButton>
                      </form>
                    )}
                    <a href={`/api/admin/polls/${p.id}/export`} className="rounded-lg border border-line px-3 py-1.5 text-xs font-semibold hover:bg-page">CSV</a>
                  </div>
                </td>
              </tr>
            ))}
            {polls.length === 0 && (
              <tr><td colSpan={7} className="px-4 py-10 text-center text-muted">No polls.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
