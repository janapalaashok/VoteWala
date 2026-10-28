import Link from "next/link";
import type { Prisma } from "@prisma/client";
import { fmt, pick } from "@/i18n";
import { getI18n } from "@/i18n/server";
import { prisma } from "@/lib/db";
import { ConstituencySearch } from "@/components/ConstituencySearch";
import { EmptyState, PageHeader, ReservationTag } from "@/components/ui";

export const dynamic = "force-dynamic";
export const metadata = { title: "Constituencies" };

export default async function ConstituenciesPage({ searchParams }: { searchParams: Promise<{ q?: string; type?: string }> }) {
  const sp = await searchParams;
  const q = (sp.q ?? "").trim().slice(0, 80);
  const { locale, t } = await getI18n();
  const where: Prisma.ConstituencyWhereInput = {};
  if (q) {
    const n = Number(q);
    where.OR = [
      { nameEn: { contains: q, mode: "insensitive" } },
      { nameTe: { contains: q } },
      { district: { contains: q, mode: "insensitive" } },
      { parent: { nameEn: { contains: q, mode: "insensitive" } } },
      ...(Number.isInteger(n) && n > 0 ? [{ number: n }] : []),
    ];
  }
  if (sp.type === "mla") where.type = "ASSEMBLY";
  if (sp.type === "mp") where.type = "PARLIAMENTARY";
  const rows = await prisma.constituency.findMany({
    where,
    include: { parent: { select: { nameEn: true, nameTe: true } }, _count: { select: { polls: { where: { status: "PUBLISHED" } } } } },
    orderBy: [{ type: "asc" }, { number: "asc" }],
  });
  const groups = [
    { key: "PARLIAMENTARY", title: t.constituencies.parliamentary, rows: rows.filter((r) => r.type === "PARLIAMENTARY") },
    { key: "ASSEMBLY", title: t.constituencies.assembly, rows: rows.filter((r) => r.type === "ASSEMBLY") },
  ].filter((g) => g.rows.length);

  return (
    <>
      <PageHeader title={t.constituencies.title} sub={t.constituencies.sub}>
        <div className="mt-6 max-w-2xl">
          <ConstituencySearch t={t} defaultValue={q} compact />
        </div>
        <p className="mt-3 text-[13px] text-muted">
          {fmt(t.constituencies.results, { n: rows.length })} · {t.constituencies.source}
        </p>
      </PageHeader>
      <div className="container-page space-y-10 py-10">
        {groups.length === 0 && <EmptyState>{t.constituencies.none}</EmptyState>}
        {groups.map((g) => (
          <section key={g.key}>
            <h2 className="mb-4 text-xl font-bold">{g.title}</h2>
            <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {g.rows.map((r) => (
                <li key={r.id}>
                  <Link href={`/constituencies/${r.id}`} className="card-interactive flex min-h-[72px] items-center gap-4 px-4 py-3">
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-page text-sm font-bold tabular-nums text-muted">
                      {r.number}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="flex items-center gap-2">
                        <span className="truncate font-semibold">{pick(locale, r.nameEn, r.nameTe)}</span>
                        <ReservationTag r={r.reservation} t={t} />
                      </span>
                      <span className="block truncate text-[13px] text-muted">
                        {r.district}
                        {r.parent && ` · ${pick(locale, r.parent.nameEn, r.parent.nameTe)}`}
                      </span>
                    </span>
                    {r._count.polls > 0 && (
                      <span className="chip bg-brand-green/10 text-brand-green-ink">{r._count.polls}</span>
                    )}
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>
    </>
  );
}
