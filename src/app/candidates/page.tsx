import type { Prisma } from "@prisma/client";
import { getI18n } from "@/i18n/server";
import { prisma } from "@/lib/db";
import { CandidateCard } from "@/components/CandidateCard";
import { EmptyState, PageHeader } from "@/components/ui";

export const dynamic = "force-dynamic";
export const metadata = { title: "Candidates" };

export default async function CandidatesPage({ searchParams }: { searchParams: Promise<{ q?: string; type?: string }> }) {
  const sp = await searchParams;
  const q = (sp.q ?? "").trim().slice(0, 80);
  const { locale, t } = await getI18n();
  const where: Prisma.CandidateWhereInput = { status: "VERIFIED" };
  if (q) {
    where.OR = [
      { nameEn: { contains: q, mode: "insensitive" } },
      { nameTe: { contains: q } },
      { partyEn: { contains: q, mode: "insensitive" } },
      { constituency: { nameEn: { contains: q, mode: "insensitive" } } },
      { constituency: { nameTe: { contains: q } } },
      { constituency: { district: { contains: q, mode: "insensitive" } } },
    ];
  }
  if (sp.type === "mla" || sp.type === "mp") {
    where.constituency = { type: sp.type === "mla" ? "ASSEMBLY" : "PARLIAMENTARY" };
  }
  const candidates = await prisma.candidate.findMany({
    where,
    include: { constituency: { select: { nameEn: true, nameTe: true, type: true } } },
    orderBy: [{ constituencyId: "asc" }, { nameEn: "asc" }],
    take: 120,
  });

  return (
    <>
      <PageHeader title={t.candidates.title} sub={t.candidates.sub}>
        <form method="get" role="search" className="mt-6 flex max-w-2xl gap-2">
          <label htmlFor="cq" className="sr-only">{t.candidates.search}</label>
          <input id="cq" name="q" type="search" defaultValue={q} placeholder={t.candidates.search} className="input" />
          <select name="type" defaultValue={sp.type ?? ""} aria-label={t.candidates.constituency} className="input w-auto">
            <option value="">{t.constituencies.all}</option>
            <option value="mla">{t.poll.mla}</option>
            <option value="mp">{t.poll.mp}</option>
          </select>
          <button className="btn-navy" type="submit">{t.home.searchButton}</button>
        </form>
      </PageHeader>
      <div className="container-page py-10">
        {candidates.length === 0 ? (
          <EmptyState>{t.candidates.none}</EmptyState>
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {candidates.map((c) => (
              <CandidateCard key={c.id} c={c} locale={locale} t={t} />
            ))}
          </div>
        )}
      </div>
    </>
  );
}
