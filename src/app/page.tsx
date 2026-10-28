import Link from "next/link";
import { formatNumber, pick } from "@/i18n";
import { getI18n } from "@/i18n/server";
import { listPolls, participationStats, todaysPolls, type PollWithDetails } from "@/lib/queries";
import { resultVisibility } from "@/lib/results";
import { formatIstDate } from "@/lib/time";
import { PollCard } from "@/components/PollCard";
import { CandidateCard, type CandidateCardData } from "@/components/CandidateCard";
import { ResultsPanel } from "@/components/ResultsPanel";
import { ConstituencySearch } from "@/components/ConstituencySearch";
import { EmptyState, SectionHeading, TypeBadge, VerifiedIcon } from "@/components/ui";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const now = new Date();
  const [{ locale, t }, today, recentClosed, stats] = await Promise.all([
    getI18n(),
    todaysPolls(now),
    listPolls({ phase: "closed", take: 8, now }),
    participationStats(),
  ]);

  // Results to feature: open polls whose policy allows live/delayed results, then the latest closed polls.
  const featured: PollWithDetails[] = [
    ...today.filter((p) => {
      const v = resultVisibility(p, now);
      return v.visible && v.reason !== "final";
    }),
    ...recentClosed,
  ].slice(0, 2);

  const seen = new Set<string>();
  const candidates: CandidateCardData[] = [];
  for (const p of today)
    for (const o of p.options)
      if (o.candidate && o.candidate.status === "VERIFIED" && !seen.has(o.candidate.id) && candidates.length < 6) {
        seen.add(o.candidate.id);
        candidates.push({ ...o.candidate, constituency: p.constituency });
      }

  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden border-b border-line bg-surface">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-[0.5]"
          style={{
            backgroundImage: "radial-gradient(rgb(var(--brand-navy) / 0.07) 1px, transparent 1px)",
            backgroundSize: "22px 22px",
            maskImage: "linear-gradient(to bottom, black, transparent 85%)",
          }}
        />
        <div className="container-page relative grid gap-10 py-12 sm:py-16 lg:grid-cols-[1.15fr_1fr] lg:items-center lg:gap-14 lg:py-20">
          <div>
            <p className="eyebrow">{t.brand.descriptor}</p>
            <h1 className="mt-4 text-[40px] font-extrabold leading-[1.05] tracking-tight sm:text-6xl">
              {t.home.heroTitle.split(" ").slice(0, 2).join(" ")}
              <br />
              <span className="text-brand-orange-ink">{t.home.heroTitle.split(" ").slice(2).join(" ")}</span>
            </h1>
            <p lang="te" className="mt-3 font-telugu text-2xl font-bold text-brand-navy/90 sm:text-[32px] sm:leading-tight">
              {t.home.heroTitleTe}
            </p>
            <p className="mt-6 max-w-xl text-base leading-relaxed text-muted sm:text-lg">{t.home.heroBody}</p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link href="/polls/mla" className="btn-primary min-h-[52px] px-7 text-base">
                {t.home.exploreMla}
                <span aria-hidden>→</span>
              </Link>
              <Link href="/polls/mp" className="btn-secondary min-h-[52px] px-7 text-base">
                {t.home.exploreMp}
              </Link>
            </div>
            <ul className="mt-8 flex flex-wrap gap-x-6 gap-y-2 text-sm font-medium text-ink/80">
              {[t.home.trustVerified, t.home.trustOneVote, t.home.trustOfficial].map((x) => (
                <li key={x} className="flex items-center gap-1.5">
                  <VerifiedIcon className="text-brand-green" />
                  {x}
                </li>
              ))}
            </ul>
          </div>

          <div className="card p-6 sm:p-7">
            <ConstituencySearch t={t} />
            <div className="mt-4 flex flex-wrap gap-2 text-[13px]">
              {["Vijayawada", "Visakhapatnam", "Guntur", "Tirupati", "Kurnool"].map((q) => (
                <Link key={q} href={`/constituencies?q=${q}`} className="rounded-full border border-line px-3 py-1 text-muted hover:border-brand-navy/30 hover:text-ink">
                  {q}
                </Link>
              ))}
            </div>
            <dl className="mt-6 grid grid-cols-2 gap-3">
              {[
                [t.home.statVotes, stats.votes],
                [t.home.statVoters, stats.voters],
                [t.home.statPolls, stats.polls],
                [t.home.statConstituencies, stats.constituencies],
              ].map(([label, value]) => (
                <div key={label as string} className="rounded-xl bg-page px-4 py-3">
                  <dt className="text-[12px] font-medium text-muted">{label}</dt>
                  <dd className="mt-0.5 text-2xl font-bold tabular-nums">{formatNumber(value as number, locale)}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </section>

      {/* Today's polls */}
      <section className="container-page py-14">
        <SectionHeading
          eyebrow={formatIstDate(now, locale)}
          title={t.home.todaysPolls}
          sub={t.home.todaysPollsSub}
          action={<Link href="/polls/mla" className="link text-sm">{t.home.viewAll} →</Link>}
        />
        {today.length === 0 ? (
          <EmptyState>{t.home.noPollsToday}</EmptyState>
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {today.slice(0, 6).map((p) => (
              <PollCard key={p.id} poll={p} locale={locale} t={t} now={now} />
            ))}
          </div>
        )}
      </section>

      {/* Results */}
      {featured.length > 0 && (
        <section className="border-y border-line bg-surface py-14">
          <div className="container-page">
            <SectionHeading
              title={t.home.resultsTitle}
              sub={t.home.resultsSub}
              action={<Link href="/results" className="link text-sm">{t.home.viewAll} →</Link>}
            />
            <div className="grid gap-5 lg:grid-cols-2">
              {featured.map((p) => (
                <article key={p.id} className="rounded-2xl border border-line p-5 sm:p-6">
                  <div className="mb-4 flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <TypeBadge type={p.constituency.type} t={t} />
                        <span className="text-[13px] text-muted">{formatIstDate(p.opensAt, locale)}</span>
                      </div>
                      <h3 className="mt-2 text-lg font-bold">
                        <Link href={`/polls/${p.id}`} className="hover:underline">
                          {pick(locale, p.constituency.nameEn, p.constituency.nameTe)}
                        </Link>
                      </h3>
                    </div>
                  </div>
                  <ResultsPanel poll={p} locale={locale} t={t} compact now={now} />
                </article>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* Candidates */}
      {candidates.length > 0 && (
        <section className="container-page py-14">
          <SectionHeading
            title={t.home.candidatesTitle}
            sub={t.home.candidatesSub}
            action={<Link href="/candidates" className="link text-sm">{t.home.viewAll} →</Link>}
          />
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {candidates.map((c) => (
              <CandidateCard key={c.id} c={c} locale={locale} t={t} />
            ))}
          </div>
        </section>
      )}

      {/* Previous polls + participation */}
      <section className="container-page py-14">
        <SectionHeading title={t.home.previousTitle} action={<Link href="/results" className="link text-sm">{t.home.viewAll} →</Link>} />
        {recentClosed.length === 0 ? (
          <EmptyState>{t.results.noResults}</EmptyState>
        ) : (
          <div className="card divide-y divide-line overflow-hidden">
            {recentClosed.map((p) => (
              <Link key={p.id} href={`/polls/${p.id}`} className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 transition hover:bg-page">
                <div className="flex min-w-0 items-center gap-3">
                  <TypeBadge type={p.constituency.type} t={t} />
                  <span className="truncate font-semibold">{pick(locale, p.constituency.nameEn, p.constituency.nameTe)}</span>
                  <span className="hidden text-[13px] text-muted sm:inline">{p.constituency.district}</span>
                </div>
                <div className="flex items-center gap-4 text-[13px] text-muted">
                  <span>{formatIstDate(p.opensAt, locale)}</span>
                  {p.report && (
                    <span className="font-semibold text-ink tabular-nums">
                      {formatNumber(p.report.totalVotes, locale)} {t.poll.votes}
                    </span>
                  )}
                  <span aria-hidden>→</span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>

      {/* Neutrality */}
      <section className="container-page">
        <div className="card flex flex-col gap-6 border-l-4 border-l-brand-green p-6 sm:flex-row sm:items-center sm:p-8">
          <div className="flex-1">
            <h2 className="text-xl font-bold">{t.home.neutralityTitle}</h2>
            <p className="mt-2 max-w-3xl text-[15px] leading-relaxed text-muted">{t.home.neutralityBody}</p>
          </div>
          <Link href="/methodology" className="btn-secondary shrink-0">
            {t.home.readMethodology}
          </Link>
        </div>
      </section>
    </>
  );
}
