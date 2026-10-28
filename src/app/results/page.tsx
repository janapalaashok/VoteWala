import Link from "next/link";
import { formatNumber, pick } from "@/i18n";
import { getI18n } from "@/i18n/server";
import { listPolls, participationStats } from "@/lib/queries";
import { formatIstDate } from "@/lib/time";
import { ResultsPanel } from "@/components/ResultsPanel";
import { EmptyState, PageHeader, TypeBadge } from "@/components/ui";

export const dynamic = "force-dynamic";
export const metadata = { title: "Results" };

export default async function ResultsPage({ searchParams }: { searchParams: Promise<{ type?: string }> }) {
  const sp = await searchParams;
  const type = sp.type === "mla" ? "ASSEMBLY" : sp.type === "mp" ? "PARLIAMENTARY" : undefined;
  const now = new Date();
  const [{ locale, t }, open, closed, stats] = await Promise.all([
    getI18n(),
    listPolls({ phase: "open", type, now, take: 24 }),
    listPolls({ phase: "closed", type, now, take: 24 }),
    participationStats(),
  ]);
  // Open polls only appear here when their policy allows live or delayed results.
  const live = open.filter((p) => p.resultPolicy !== "AFTER_CLOSE");
  const polls = [...live, ...closed];
  const tabs = [
    ["", t.poll.filterAll],
    ["mla", t.poll.mla],
    ["mp", t.poll.mp],
  ] as const;

  return (
    <>
      <PageHeader title={t.results.title} sub={t.results.sub}>
        <dl className="mt-8 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            [t.home.statVotes, stats.votes],
            [t.home.statVoters, stats.voters],
            [t.home.statPolls, stats.polls],
            [t.home.statConstituencies, stats.constituencies],
          ].map(([label, value]) => (
            <div key={label as string} className="rounded-xl border border-line bg-page px-4 py-3">
              <dt className="text-[12px] font-medium text-muted">{label}</dt>
              <dd className="mt-0.5 text-2xl font-bold tabular-nums">{formatNumber(value as number, locale)}</dd>
            </div>
          ))}
        </dl>
        <nav aria-label="Filter" className="mt-6 flex gap-1">
          {tabs.map(([k, label]) => (
            <Link
              key={k}
              href={k ? `/results?type=${k}` : "/results"}
              aria-current={(sp.type ?? "") === k ? "page" : undefined}
              className={`flex min-h-[40px] items-center rounded-xl px-4 text-sm font-semibold ${
                (sp.type ?? "") === k ? "bg-brand-navy text-white" : "border border-line bg-surface text-muted hover:text-ink"
              }`}
            >
              {label}
            </Link>
          ))}
        </nav>
      </PageHeader>
      <div className="container-page py-10">
        {polls.length === 0 ? (
          <EmptyState>{t.results.noResults}</EmptyState>
        ) : (
          <div className="grid gap-5 lg:grid-cols-2">
            {polls.map((p) => (
              <article key={p.id} className="card p-5 sm:p-6">
                <div className="mb-4 flex flex-wrap items-center gap-2">
                  <TypeBadge type={p.constituency.type} t={t} />
                  <span className="text-[13px] text-muted">{formatIstDate(p.opensAt, locale)} · {p.constituency.district}</span>
                </div>
                <h2 className="mb-1 text-lg font-bold">
                  <Link href={`/polls/${p.id}`} className="hover:underline">
                    {pick(locale, p.constituency.nameEn, p.constituency.nameTe)}
                  </Link>
                </h2>
                <p className="mb-4 text-sm text-muted">{pick(locale, p.questionEn, p.questionTe)}</p>
                <ResultsPanel poll={p} locale={locale} t={t} compact now={now} />
              </article>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
