import Link from "next/link";
import { notFound } from "next/navigation";
import { pick } from "@/i18n";
import { getI18n } from "@/i18n/server";
import { prisma } from "@/lib/db";
import { listPolls } from "@/lib/queries";
import { CandidateAvatar } from "@/components/CandidateAvatar";
import { PollCard } from "@/components/PollCard";
import { ExternalIcon, TypeBadge, VerifiedIcon } from "@/components/ui";

export const dynamic = "force-dynamic";

export default async function CandidatePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [{ locale, t }, c] = await Promise.all([
    getI18n(),
    prisma.candidate.findUnique({ where: { id }, include: { constituency: true } }),
  ]);
  if (!c || c.status !== "VERIFIED") notFound();
  const polls = await listPolls({ candidateId: c.id, phase: "all", take: 12 });
  const now = new Date();
  return (
    <div className="container-page py-10">
      <nav aria-label="Breadcrumb" className="mb-5 text-sm text-muted">
        <Link href="/candidates" className="hover:text-ink">← {t.nav.candidates}</Link>
      </nav>
      <section className="card flex flex-col gap-6 p-6 sm:flex-row sm:items-center sm:p-8">
        <CandidateAvatar name={c.nameEn} photoUrl={c.photoUrl} size={104} />
        <div className="flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <TypeBadge type={c.constituency.type} t={t} />
            <span className="chip bg-brand-green/10 text-brand-green-ink"><VerifiedIcon /> {t.candidates.verified}</span>
            {c.isDemo && <span className="chip bg-amber-50 text-amber-800">{t.poll.demo}</span>}
          </div>
          <h1 className="mt-3 text-3xl font-bold tracking-tight">{pick(locale, c.nameEn, c.nameTe)}</h1>
          <p className="mt-1 text-muted">{locale === "te" ? c.nameEn : c.nameTe}</p>
          <dl className="mt-5 grid gap-4 text-sm sm:grid-cols-3">
            <div>
              <dt className="eyebrow">{t.candidates.party}</dt>
              <dd className="mt-1 font-semibold">{pick(locale, c.partyEn, c.partyTe)}</dd>
            </div>
            <div>
              <dt className="eyebrow">{t.candidates.constituency}</dt>
              <dd className="mt-1 font-semibold">
                <Link href={`/constituencies/${c.constituency.id}`} className="hover:underline">
                  {pick(locale, c.constituency.nameEn, c.constituency.nameTe)}
                </Link>
              </dd>
            </div>
            <div>
              <dt className="eyebrow">{t.candidates.electionYear}</dt>
              <dd className="mt-1 font-semibold">{c.electionYear}</dd>
            </div>
          </dl>
          <a href={c.sourceUrl} target="_blank" rel="noopener noreferrer nofollow" className="btn-secondary mt-6 min-h-[40px] text-sm">
            {t.poll.officialSource}: {c.sourceLabel} <ExternalIcon />
          </a>
        </div>
      </section>
      {polls.length > 0 && (
        <section className="mt-10">
          <h2 className="mb-5 text-xl font-bold">{t.candidates.polls}</h2>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {polls.map((p) => <PollCard key={p.id} poll={p} locale={locale} t={t} now={now} />)}
          </div>
        </section>
      )}
    </div>
  );
}
