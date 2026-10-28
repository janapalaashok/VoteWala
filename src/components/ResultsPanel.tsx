import { pick, type Dictionary, type Locale } from "@/i18n";
import type { PollWithDetails } from "@/lib/queries";
import { getPublicResults, minSample } from "@/lib/results";
import { formatIst } from "@/lib/time";
import { ResultsChart, type ChartRow } from "./ResultsChart";

export async function ResultsPanel({
  poll,
  locale,
  t,
  compact = false,
  now = new Date(),
}: {
  poll: PollWithDetails;
  locale: Locale;
  t: Dictionary;
  compact?: boolean;
  now?: Date;
}) {
  const res = await getPublicResults(poll.id, now);
  if (!res.visibility.visible) {
    const v = res.visibility;
    return (
      <div className="flex flex-col items-center justify-center rounded-xl bg-page px-5 py-8 text-center">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-muted" aria-hidden>
          <rect x="4" y="10" width="16" height="11" rx="2" />
          <path d="M8 10V7a4 4 0 118 0v3" />
        </svg>
        <p className="mt-3 text-[15px] font-semibold">
          {v.reason === "blackout" ? t.results.blackout : v.reason === "hidden_until_close" ? t.results.hiddenUntilClose : v.reason === "not_started" ? t.results.notStarted : t.results.unavailable}
        </p>
        {v.revealAt && <p className="mt-1 text-[13px] text-muted">{formatIst(v.revealAt, locale)} IST</p>}
      </div>
    );
  }
  const byOption = new Map(poll.options.map((o) => [o.id, o]));
  const rows: ChartRow[] = res.rows.map((r) => {
    const o = byOption.get(r.optionId);
    const c = o?.candidate;
    return {
      id: r.optionId,
      label: c ? pick(locale, c.nameEn, c.nameTe) : pick(locale, o?.labelEn ?? t.poll.noneOfThese, o?.labelTe),
      sublabel: c ? pick(locale, c.partyEn, c.partyTe) : undefined,
      votes: r.votes,
      share: r.share,
    };
  });
  const status = res.finalized || res.visibility.reason === "final" ? t.results.final : res.visibility.reason === "live" ? t.results.live : t.results.delayed;
  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
        <span
          className={`chip ${res.visibility.reason === "final" ? "bg-brand-navy text-white" : "bg-brand-green/10 text-brand-green-ink"}`}
        >
          {status}
        </span>
        {res.asOf && (
          <span className="text-[12px] text-muted">
            {t.results.asOf} {formatIst(res.asOf, locale)} IST
          </span>
        )}
      </div>
      <ResultsChart rows={rows} total={res.total} belowMinSample={res.belowMinSample} minSample={minSample()} locale={locale} t={t} compact={compact} />
      <p className="mt-4 border-t border-line pt-3 text-[12px] leading-relaxed text-muted">{t.results.notOfficial}</p>
    </div>
  );
}
