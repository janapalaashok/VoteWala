import Link from "next/link";
import { getI18n } from "@/i18n/server";
import { districts, listPolls, type PhaseFilter } from "@/lib/queries";
import { PollCard } from "./PollCard";
import { EmptyState, PageHeader } from "./ui";

const PHASES: PhaseFilter[] = ["open", "upcoming", "closed", "all"];

export async function PollsListing({
  type,
  basePath,
  searchParams,
}: {
  type: "ASSEMBLY" | "PARLIAMENTARY";
  basePath: string;
  searchParams: { phase?: string; district?: string };
}) {
  const now = new Date();
  const phase = (PHASES as string[]).includes(searchParams.phase ?? "") ? (searchParams.phase as PhaseFilter) : "open";
  const allDistricts = await districts();
  const district = allDistricts.includes(searchParams.district ?? "") ? searchParams.district : undefined;
  const [{ locale, t }, polls] = await Promise.all([getI18n(), listPolls({ type, phase, district, now })]);
  const labels: Record<PhaseFilter, string> = {
    open: t.poll.filterOpen,
    upcoming: t.poll.filterUpcoming,
    closed: t.poll.filterClosed,
    all: t.poll.filterAll,
  };
  const href = (p: PhaseFilter) => `${basePath}?phase=${p}${district ? `&district=${encodeURIComponent(district)}` : ""}`;

  return (
    <>
      <PageHeader
        title={type === "ASSEMBLY" ? t.nav.mlaPolls : t.nav.mpPolls}
        sub={type === "ASSEMBLY" ? t.constituencies.assembly : t.constituencies.parliamentary}
      >
        <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <nav aria-label="Filter" className="-mx-1 flex gap-1 overflow-x-auto px-1 pb-1">
            {PHASES.map((p) => (
              <Link
                key={p}
                href={href(p)}
                aria-current={p === phase ? "page" : undefined}
                className={`flex min-h-[40px] shrink-0 items-center rounded-xl px-4 text-sm font-semibold transition ${
                  p === phase ? "bg-brand-navy text-white" : "border border-line bg-surface text-muted hover:text-ink"
                }`}
              >
                {labels[p]}
              </Link>
            ))}
          </nav>
          <form method="get" action={basePath} className="flex gap-2">
            <input type="hidden" name="phase" value={phase} />
            <label htmlFor="district" className="sr-only">{t.poll.district}</label>
            <select id="district" name="district" defaultValue={district ?? ""} className="input min-h-[40px] py-0 sm:w-56">
              <option value="">{t.poll.district}: {t.constituencies.all}</option>
              {allDistricts.map((d) => (
                <option key={d} value={d}>{d}</option>
              ))}
            </select>
            <button className="btn-secondary min-h-[40px] px-4 text-sm" type="submit">{t.home.searchButton}</button>
          </form>
        </div>
      </PageHeader>
      <div className="container-page py-10">
        {polls.length === 0 ? (
          <EmptyState>{t.poll.noPolls}</EmptyState>
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {polls.map((p) => (
              <PollCard key={p.id} poll={p} locale={locale} t={t} now={now} />
            ))}
          </div>
        )}
      </div>
    </>
  );
}
