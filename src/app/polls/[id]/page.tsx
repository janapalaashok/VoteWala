import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { fmt, pick } from "@/i18n";
import { getI18n } from "@/i18n/server";
import { getPoll } from "@/lib/queries";
import { getCurrentUser } from "@/lib/session";
import { pollPhase } from "@/lib/results";
import { userVote } from "@/lib/vote";
import { formatIst, formatIstDate } from "@/lib/time";
import { VoteForm, type VoteOption } from "@/components/VoteForm";
import { ResultsPanel } from "@/components/ResultsPanel";
import { Countdown } from "@/components/Countdown";
import { ExternalIcon, PhaseBadge, ReservationTag, TypeBadge } from "@/components/ui";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const poll = await getPoll((await params).id);
  return poll ? { title: `${poll.constituency.nameEn} — ${poll.constituency.type === "ASSEMBLY" ? "MLA" : "MP"} poll` } : {};
}

export default async function PollPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const now = new Date();
  const [{ locale, t }, poll, user] = await Promise.all([getI18n(), getPoll(id), getCurrentUser()]);
  if (!poll || poll.status === "DRAFT") notFound();
  const phase = pollPhase(poll, now);
  const existing = user ? await userVote(user.id, poll.id) : null;
  const c = poll.constituency;

  const mode = existing
    ? "voted"
    : phase !== "open"
      ? "closed"
      : !user
        ? "signin"
        : !user.phoneVerifiedAt
          ? "verify"
          : "can_vote";

  const options: VoteOption[] = poll.options.map((o) => ({
    id: o.id,
    label: o.candidate ? pick(locale, o.candidate.nameEn, o.candidate.nameTe) : pick(locale, o.labelEn ?? t.poll.noneOfThese, o.labelTe),
    sublabel: o.candidate ? pick(locale, o.candidate.partyEn, o.candidate.partyTe) : undefined,
    photoUrl: o.candidate?.photoUrl ?? null,
    sourceUrl: o.candidate?.sourceUrl,
    isNone: !o.candidate,
  }));

  const policyLabel =
    poll.resultPolicy === "DELAYED"
      ? fmt(t.poll.policyDELAYED, { minutes: poll.publishDelayMinutes })
      : poll.resultPolicy === "LIVE"
        ? t.poll.policyLIVE
        : t.poll.policyAFTER_CLOSE;

  return (
    <div className="container-page py-8 sm:py-10">
      <nav aria-label="Breadcrumb" className="mb-5 text-sm text-muted">
        <Link href={c.type === "ASSEMBLY" ? "/polls/mla" : "/polls/mp"} className="hover:text-ink">
          ← {c.type === "ASSEMBLY" ? t.nav.mlaPolls : t.nav.mpPolls}
        </Link>
      </nav>

      {poll.isDemo && (
        <p className="mb-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-900">{t.poll.demoNote}</p>
      )}

      <div className="grid gap-6 lg:grid-cols-[1.25fr_1fr] lg:gap-8">
        <section className="card p-5 sm:p-8">
          <div className="flex flex-wrap items-center gap-2">
            <TypeBadge type={c.type} t={t} />
            <PhaseBadge phase={phase} t={t} />
            <ReservationTag r={c.reservation} t={t} />
          </div>
          <h1 className="mt-4 text-2xl font-bold tracking-tight sm:text-3xl">
            <Link href={`/constituencies/${c.id}`} className="hover:underline">
              {pick(locale, c.nameEn, c.nameTe)}
            </Link>
            <span className="ml-2 text-base font-medium text-muted">#{c.number} · {c.district}</span>
          </h1>
          <p className="mt-3 text-lg leading-relaxed">{pick(locale, poll.questionEn, poll.questionTe)}</p>

          <div className="mt-8">
            <VoteForm
              pollId={poll.id}
              options={options}
              mode={mode}
              votedOptionId={existing?.optionId}
              labels={{
                chooseOne: t.poll.chooseOne,
                castVote: t.poll.castVote,
                confirmTitle: t.poll.confirmTitle,
                confirmBody: t.poll.confirmBody,
                confirm: t.poll.confirm,
                cancel: t.poll.cancel,
                submitting: t.poll.submitting,
                thanks: t.poll.thanks,
                youVoted: t.poll.youVoted,
                signInToVote: t.poll.signInToVote,
                verifyToVote: t.poll.verifyToVote,
                notOpen: t.poll.notOpen,
                officialSource: t.poll.officialSource,
                errors: t.poll.errors,
              }}
            />
          </div>

          {poll.options.some((o) => o.candidate) && (
            <div className="mt-8 border-t border-line pt-5">
              <h2 className="eyebrow mb-3">{t.poll.officialSource}</h2>
              <ul className="grid gap-2 text-sm sm:grid-cols-2">
                {poll.options
                  .filter((o) => o.candidate)
                  .map((o) => (
                    <li key={o.id}>
                      <a href={o.candidate!.sourceUrl} target="_blank" rel="noopener noreferrer nofollow" className="inline-flex items-center gap-1 text-brand-navy hover:underline">
                        {pick(locale, o.candidate!.nameEn, o.candidate!.nameTe)} <ExternalIcon />
                      </a>
                    </li>
                  ))}
              </ul>
            </div>
          )}
        </section>

        <aside className="space-y-6">
          <section className="card p-5 sm:p-6">
            <dl className="grid gap-4 text-sm">
              <div>
                <dt className="eyebrow">{t.poll.window}</dt>
                <dd className="mt-1 font-semibold">
                  {formatIstDate(poll.opensAt, locale)}
                  <br />
                  <span className="font-normal text-muted">
                    {formatIst(poll.opensAt, locale, false)} – {formatIst(poll.closesAt, locale)}
                  </span>
                </dd>
              </div>
              {phase === "open" && (
                <div>
                  <dt className="eyebrow">{t.poll.closes}</dt>
                  <dd className="mt-1 text-2xl font-bold">
                    <Countdown to={poll.closesAt.toISOString()} serverNow={now.toISOString()} />
                  </dd>
                </div>
              )}
              <div>
                <dt className="eyebrow">{t.poll.resultPolicy}</dt>
                <dd className="mt-1 font-semibold">{policyLabel}</dd>
              </div>
            </dl>
          </section>
          <section id="results" className="card scroll-mt-24 p-5 sm:p-6" aria-labelledby="results-heading">
            <h2 id="results-heading" className="mb-4 text-lg font-bold">{t.results.title}</h2>
            <ResultsPanel poll={poll} locale={locale} t={t} now={now} />
          </section>
          <p className="px-1 text-[13px] leading-relaxed text-muted">
            {t.home.neutralityBody}{" "}
            <Link href="/methodology" className="link">{t.home.readMethodology}</Link>
          </p>
        </aside>
      </div>
    </div>
  );
}
