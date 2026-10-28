import type { Dictionary } from "@/i18n";

export function ConstituencySearch({ t, defaultValue = "", compact = false }: { t: Dictionary; defaultValue?: string; compact?: boolean }) {
  return (
    <form action="/constituencies" method="get" role="search" className="w-full">
      <label htmlFor="constituency-q" className={compact ? "sr-only" : "label"}>
        {t.home.searchLabel}
      </label>
      <div className="flex gap-2">
        <div className="relative flex-1">
          <svg className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
            <circle cx="11" cy="11" r="7" />
            <path d="M20 20l-3.5-3.5" />
          </svg>
          <input
            id="constituency-q"
            name="q"
            type="search"
            defaultValue={defaultValue}
            placeholder={t.home.searchPlaceholder}
            autoComplete="off"
            className="input pl-10"
          />
        </div>
        <button type="submit" className="btn-navy shrink-0">
          {t.home.searchButton}
        </button>
      </div>
    </form>
  );
}
