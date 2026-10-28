import Link from "next/link";
import { notFound } from "next/navigation";
import { pick } from "@/i18n";
import { getI18n } from "@/i18n/server";
import { prisma } from "@/lib/db";
import { listPolls } from "@/lib/queries";
import { CandidateCard } from "@/components/CandidateCard";
import { PollCard } from "@/components/PollCard";
import { ExternalIcon, ReservationTag, TypeBadge } from "@/components/ui";

export const dynamic = "force-dynamic";

export default async function ConstituencyPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [{ locale, t }, c] = await Promise.all([
    getI18n(),
    prisma.constituency.findUnique({
      where: { id },
      include: {
        parent: true,
        segments: { orderBy: { number: "asc" } },
        candidates: { where: { status: "VERIFIED" }, orderBy: [{ electionYear: "desc" }, { nameEn: "asc" }] },
      },
    }),
  ]);
  if (!c) notFound();
  const polls = await listPolls({ constituencyId: c.id, phase: "all", take: 12 });
  const now = new Date();

  return (
    <div className="container-page py-10">
      <nav aria-label="Breadcrumb" className="mb-5 text-sm text-muted">
        <Link href="/constituencies" className="hover:text-ink">← {t.constituencies.title}</Link>
      </nav>
      <section className="card p-6 sm:p-8">
        <div className="flex flex-wrap items-center gap-2">
          <TypeBadge type={c.type} t={t} />
          <ReservationTag r={c.reservation} t={t} />
        </div>
        <h1 className="mt-3 text-3xl font-bold tracking-tight">
          {pick(locale, c.nameEn, c.nameTe)} <span className="text-lg font-medium text-muted">#{c.number}</span>
        </h1>
        <p className="mt-1 text-muted">{locale === "te" ? c.nameEn : c.nameTe} · {c.district}</p>
        {c.parent && (
          <p className="mt-4 text-sm">
            {t.constituencies.partOf}:{" "}
            <Link href={`/constituencies/${c.parent.id}`} className="link">
              {pick(locale, c.parent.nameEn, c.parent.nameTe)} ({t.poll.parliamentary})
            </Link>
          </p>
        )}
        {c.segments.length > 0 && (
          <div className="mt-5">
            <h2 className="eyebrow mb-2">{t.constituencies.segments}</h2>
            <ul className="flex flex-wrap gap-2">
              {c.segments.map((s) => (
                <li key={s.id}>
                  <Link href={`/constituencies/${s.id}`} className="inline-flex min-h-[36px] items-center rounded-full border border-line px-3 text-sm hover:border-brand-navy/30">
                    {pick(locale, s.nameEn, s.nameTe)}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        )}
        <a href={c.sourceUrl} target="_blank" rel="noopener noreferrer" className="mt-5 inline-flex items-center gap-1 text-[13px] text-muted hover:text-ink">
          {t.constituencies.source} <ExternalIcon />
        </a>
      </section>

      <section className="mt-10">
        <h2 className="mb-5 text-xl font-bold">{t.constituencies.polls}</h2>
        {polls.length === 0 ? (
          <p className="text-muted">{t.poll.noPolls}</p>
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {polls.map((p) => <PollCard key={p.id} poll={p} locale={locale} t={t} now={now} />)}
          </div>
        )}
      </section>

      {c.candidates.length > 0 && (
        <section className="mt-10">
          <h2 className="mb-5 text-xl font-bold">{t.constituencies.candidates}</h2>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {c.candidates.map((cand) => <CandidateCard key={cand.id} c={cand} locale={locale} t={t} />)}
          </div>
        </section>
      )}
    </div>
  );
}
