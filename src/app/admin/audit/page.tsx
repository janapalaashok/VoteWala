import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatIst } from "@/lib/time";

const PAGE = 50;

export default async function AuditPage({ searchParams }: { searchParams: Promise<{ page?: string; action?: string }> }) {
  const sp = await searchParams;
  const page = Math.max(1, Number(sp.page) || 1);
  const where = sp.action ? { action: { startsWith: sp.action } } : {};
  const [rows, total] = await Promise.all([
    prisma.auditLog.findMany({ where, include: { actor: { select: { email: true } } }, orderBy: { createdAt: "desc" }, skip: (page - 1) * PAGE, take: PAGE }),
    prisma.auditLog.count({ where }),
  ]);
  const pages = Math.max(1, Math.ceil(total / PAGE));
  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">Audit log</h1>
        <div className="flex gap-2">
          <form method="get" className="flex gap-2">
            <input name="action" defaultValue={sp.action ?? ""} placeholder="Action prefix, e.g. poll." className="input min-h-[38px] w-56" aria-label="Filter by action" />
          </form>
          <a href="/api/admin/audit/export" className="btn-secondary min-h-[38px] text-sm">Export CSV</a>
        </div>
      </div>
      <p className="text-sm text-muted">Append-only: the database rejects updates and deletes to this table.</p>
      <div className="card overflow-x-auto">
        <table className="w-full min-w-[760px] text-left text-sm">
          <thead className="text-muted">
            <tr className="border-b border-line">
              <th className="px-4 py-3">Time (IST)</th>
              <th className="px-4 py-3">Actor</th>
              <th className="px-4 py-3">Action</th>
              <th className="px-4 py-3">Entity</th>
              <th className="px-4 py-3">Details</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id} className="border-b border-line/70 align-top">
                <td className="whitespace-nowrap px-4 py-2.5">{formatIst(r.createdAt, "en")}</td>
                <td className="px-4 py-2.5">{r.actor?.email ?? "system"}</td>
                <td className="px-4 py-2.5 font-mono text-xs">{r.action}</td>
                <td className="px-4 py-2.5 text-xs">{r.entityType}{r.entityId ? ` · ${r.entityId}` : ""}</td>
                <td className="max-w-[280px] truncate px-4 py-2.5 font-mono text-xs text-muted">{r.metadata ? JSON.stringify(r.metadata) : ""}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="flex items-center justify-between text-sm">
        <span className="text-muted">Page {page} of {pages} · {total} entries</span>
        <div className="flex gap-2">
          {page > 1 && <Link className="btn-secondary min-h-[36px] text-sm" href={`/admin/audit?page=${page - 1}${sp.action ? `&action=${sp.action}` : ""}`}>Previous</Link>}
          {page < pages && <Link className="btn-secondary min-h-[36px] text-sm" href={`/admin/audit?page=${page + 1}${sp.action ? `&action=${sp.action}` : ""}`}>Next</Link>}
        </div>
      </div>
    </div>
  );
}
