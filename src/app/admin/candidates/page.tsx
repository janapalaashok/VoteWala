import Link from "next/link";
import type { CandidateStatus, Prisma } from "@prisma/client";
import { prisma } from "@/lib/db";
import { ImportCandidatesForm } from "@/components/admin/ImportCandidatesForm";
import { setCandidateStatusAction } from "../actions";

const STATUSES: CandidateStatus[] = ["PENDING", "VERIFIED", "REJECTED"];

export default async function AdminCandidates({ searchParams }: { searchParams: Promise<{ status?: string; q?: string }> }) {
  const sp = await searchParams;
  const status = STATUSES.includes(sp.status as CandidateStatus) ? (sp.status as CandidateStatus) : "PENDING";
  const q = (sp.q ?? "").trim();
  const where: Prisma.CandidateWhereInput = { status };
  if (q) where.OR = [{ nameEn: { contains: q, mode: "insensitive" } }, { constituencyId: { contains: q.toUpperCase() } }, { constituency: { nameEn: { contains: q, mode: "insensitive" } } }];
  const rows = await prisma.candidate.findMany({ where, include: { constituency: true }, orderBy: [{ constituencyId: "asc" }, { nameEn: "asc" }], take: 300 });

  const button = (id: string, s: CandidateStatus, label: string, cls: string) => (
    <form action={setCandidateStatusAction}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="status" value={s} />
      <button className={`rounded-lg px-3 py-1.5 text-xs font-semibold ${cls}`}>{label}</button>
    </form>
  );

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Candidates</h1>
      <ImportCandidatesForm />
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex gap-1 text-sm">
          {STATUSES.map((s) => (
            <Link key={s} href={`/admin/candidates?status=${s}`} className={`rounded-lg px-3 py-1.5 font-semibold ${s === status ? "bg-brand-navy text-white" : "text-muted hover:bg-surface"}`}>
              {s}
            </Link>
          ))}
        </div>
        <form method="get" className="flex gap-2">
          <input type="hidden" name="status" value={status} />
          <input name="q" defaultValue={q} placeholder="Name or AC-001" className="input min-h-[38px] w-56" aria-label="Search" />
        </form>
      </div>
      <div className="card overflow-x-auto">
        <table className="w-full min-w-[860px] text-left text-sm">
          <thead className="text-muted">
            <tr className="border-b border-line">
              <th className="px-4 py-3">Candidate</th>
              <th className="px-4 py-3">Constituency</th>
              <th className="px-4 py-3">Party</th>
              <th className="px-4 py-3">Year</th>
              <th className="px-4 py-3">Source</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((c) => (
              <tr key={c.id} className="border-b border-line/70">
                <td className="px-4 py-3">
                  <span className="font-semibold">{c.nameEn}</span>
                  <span lang="te" className="block text-xs text-muted">{c.nameTe}</span>
                  {c.isDemo && <span className="chip mt-1 bg-amber-50 text-amber-800">demo</span>}
                </td>
                <td className="px-4 py-3">{c.constituency.nameEn} <span className="text-xs text-muted">{c.constituencyId}</span></td>
                <td className="px-4 py-3">{c.partyEn}</td>
                <td className="px-4 py-3">{c.electionYear}</td>
                <td className="px-4 py-3">
                  <a href={c.sourceUrl} target="_blank" rel="noopener noreferrer" className="link text-xs">{c.sourceLabel}</a>
                </td>
                <td className="px-4 py-3">
                  <div className="flex gap-2">
                    {c.status !== "VERIFIED" && button(c.id, "VERIFIED", "Verify", "bg-brand-green-ink text-white")}
                    {c.status !== "REJECTED" && button(c.id, "REJECTED", "Reject", "border border-line text-red-700 hover:bg-red-50")}
                    {c.status !== "PENDING" && button(c.id, "PENDING", "Reset", "border border-line hover:bg-page")}
                  </div>
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr><td colSpan={6} className="px-4 py-10 text-center text-muted">No {status.toLowerCase()} candidates.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
