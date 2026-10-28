import Link from "next/link";
import { prisma } from "@/lib/db";
import { participationStats } from "@/lib/queries";
import { istDateString, formatIst, dateOnly } from "@/lib/time";
import { runFinalizerAction } from "./actions";

export default async function AdminDashboard() {
  const today = istDateString();
  const [stats, pending, todays, unfinalized] = await Promise.all([
    participationStats(),
    prisma.candidate.count({ where: { status: "PENDING" } }),
    prisma.poll.findMany({
      where: { pollDate: dateOnly(today) },
      include: { constituency: true, _count: { select: { votes: true } } },
      orderBy: { constituencyId: "asc" },
    }),
    prisma.poll.count({ where: { status: "PUBLISHED", closesAt: { lte: new Date() }, report: null } }),
  ]);
  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <dl className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[
          ["Votes recorded", stats.votes],
          ["Verified participants", stats.voters],
          ["Candidates awaiting verification", pending],
          ["Closed polls awaiting final report", unfinalized],
        ].map(([l, v]) => (
          <div key={l as string} className="card px-4 py-4">
            <dt className="text-xs font-medium text-muted">{l}</dt>
            <dd className="mt-1 text-2xl font-bold tabular-nums">{v}</dd>
          </div>
        ))}
      </dl>

      <section className="card p-5">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-lg font-bold">Today ({today}, IST)</h2>
          <div className="flex flex-wrap gap-2">
            <a href={`/api/admin/reports/daily?date=${today}`} className="btn-secondary min-h-[38px] text-sm">Daily report CSV</a>
            <form action={runFinalizerAction}>
              <button className="btn-navy min-h-[38px] text-sm" type="submit">Finalize closed polls now</button>
            </form>
          </div>
        </div>
        {todays.length === 0 ? (
          <p className="text-sm text-muted">
            No polls today. <Link href="/admin/polls/new" className="link">Schedule polls</Link>
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="text-muted">
                <tr className="border-b border-line">
                  <th className="py-2 pr-4">Constituency</th>
                  <th className="py-2 pr-4">Status</th>
                  <th className="py-2 pr-4">Window (IST)</th>
                  <th className="py-2 pr-4">Policy</th>
                  <th className="py-2 text-right">Votes</th>
                </tr>
              </thead>
              <tbody>
                {todays.map((p) => (
                  <tr key={p.id} className="border-b border-line/70">
                    <td className="py-2 pr-4 font-semibold"><Link href={`/polls/${p.id}`} className="hover:underline">{p.constituency.nameEn}</Link></td>
                    <td className="py-2 pr-4">{p.status}</td>
                    <td className="py-2 pr-4">{formatIst(p.opensAt, "en", false)} – {formatIst(p.closesAt, "en", false)}</td>
                    <td className="py-2 pr-4">{p.resultPolicy}</td>
                    <td className="py-2 text-right tabular-nums">{p._count.votes}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
