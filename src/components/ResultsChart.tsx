import { fmt, formatNumber, type Dictionary, type Locale } from "@/i18n";

export interface ChartRow {
  id: string;
  label: string;
  sublabel?: string;
  votes: number;
  share: number;
}

/**
 * Horizontal bar chart of vote share. One neutral hue for every option: colour
 * never signals a leader or a party. Labels are direct; a table view is provided.
 */
export function ResultsChart({
  rows,
  total,
  belowMinSample,
  minSample,
  locale,
  t,
  compact = false,
}: {
  rows: ChartRow[];
  total: number;
  belowMinSample: boolean;
  minSample: number;
  locale: Locale;
  t: Dictionary;
  compact?: boolean;
}) {
  const sorted = [...rows].sort((a, b) => b.votes - a.votes);
  const max = Math.max(...sorted.map((r) => r.share), 0.0001);
  const pct = (s: number) => `${(s * 100).toFixed(1)}%`;
  return (
    <div>
      {belowMinSample && (
        <p className="mb-4 rounded-xl bg-page px-4 py-3 text-[13px] leading-relaxed text-muted">
          {fmt(t.results.smallSample, { n: minSample })}
        </p>
      )}
      <ul className={compact ? "space-y-3" : "space-y-4"} aria-label={t.results.title}>
        {sorted.map((r) => (
          <li
            key={r.id}
            className="group rounded-lg"
            title={`${r.label}${r.sublabel ? ` (${r.sublabel})` : ""}: ${formatNumber(r.votes, locale)} ${t.poll.votes}${belowMinSample ? "" : ` · ${pct(r.share)}`}`}
          >
            <div className="flex items-baseline justify-between gap-3">
              <span className="min-w-0 truncate text-[14px] font-semibold">
                {r.label}
                {r.sublabel && <span className="ml-1.5 font-normal text-muted">{r.sublabel}</span>}
              </span>
              <span className="shrink-0 text-[14px] tabular-nums">
                {!belowMinSample && <span className="font-bold">{pct(r.share)}</span>}
                <span className="ml-2 text-muted">{formatNumber(r.votes, locale)}</span>
              </span>
            </div>
            {!belowMinSample && (
              <div className="mt-1.5 h-2.5 overflow-hidden rounded-full bg-page" aria-hidden>
                <div
                  className="h-full origin-left animate-[growX_.7s_cubic-bezier(.2,.8,.2,1)] rounded-full bg-brand-navy transition-[filter] group-hover:brightness-150"
                  style={{ width: `${(r.share / max) * 100}%` }}
                />
              </div>
            )}
          </li>
        ))}
      </ul>
      <div className="mt-4 flex flex-wrap items-center justify-between gap-2 text-[13px] text-muted">
        <span>
          {t.results.totalVotes}: <span className="font-semibold text-ink tabular-nums">{formatNumber(total, locale)}</span>
        </span>
        <details className="group/table">
          <summary className="cursor-pointer font-semibold text-brand-navy hover:underline">{t.results.tableView}</summary>
          <table className="mt-3 w-full min-w-[260px] text-left text-[13px]">
            <thead>
              <tr className="border-b border-line text-muted">
                <th className="py-1.5 pr-3 font-semibold">{t.results.option}</th>
                <th className="py-1.5 pr-3 text-right font-semibold">{t.poll.votes}</th>
                {!belowMinSample && <th className="py-1.5 text-right font-semibold">{t.results.share}</th>}
              </tr>
            </thead>
            <tbody>
              {sorted.map((r) => (
                <tr key={r.id} className="border-b border-line/70 text-ink">
                  <td className="py-1.5 pr-3">{r.label}</td>
                  <td className="py-1.5 pr-3 text-right tabular-nums">{formatNumber(r.votes, locale)}</td>
                  {!belowMinSample && <td className="py-1.5 text-right tabular-nums">{pct(r.share)}</td>}
                </tr>
              ))}
            </tbody>
          </table>
        </details>
      </div>
    </div>
  );
}
