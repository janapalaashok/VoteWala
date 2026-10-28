import Link from "next/link";
import { pick, type Dictionary, type Locale } from "@/i18n";
import type { PollWithDetails } from "@/lib/queries";
import { pollPhase } from "@/lib/results";
import { formatIst } from "@/lib/time";
import { CandidateAvatar } from "./CandidateAvatar";
import { PhaseBadge, ReservationTag, TypeBadge } from "./ui";
import { Countdown } from "./Countdown";

export function PollCard({ poll, locale, t, now = new Date() }: { poll: PollWithDetails; locale: Locale; t: Dictionary; now?: Date }) {
  const phase = pollPhase(poll, now);
  const c = poll.constituency;
  const candidates = poll.options.filter((o) => o.candidate).map((o) => o.candidate!);
  return (
    <article className="card-interactive group relative flex h-full flex-col p-5">
      <div className="flex flex-wrap items-center gap-2">
        <TypeBadge type={c.type} t={t} />
        <PhaseBadge phase={phase} t={t} />
        <ReservationTag r={c.reservation} t={t} />
        {poll.isDemo && <span className="chip bg-amber-50 text-amber-800">{t.poll.demo}</span>}
      </div>
      <h3 className="mt-3.5 text-lg font-bold leading-snug">
        <Link href={`/polls/${poll.id}`} className="after:absolute after:inset-0 after:rounded-2xl focus-visible:outline-none">
          {pick(locale, c.nameEn, c.nameTe)}
        </Link>
        <span className="ml-2 text-sm font-medium text-muted">#{c.number}</span>
      </h3>
      <p className="text-[13px] text-muted">{c.district}</p>
      <p className="mt-3 line-clamp-2 text-[15px] leading-relaxed">{pick(locale, poll.questionEn, poll.questionTe)}</p>

      <div className="mt-4 flex items-center gap-3">
        <div className="flex -space-x-2.5">
          {candidates.slice(0, 4).map((cand) => (
            <span key={cand.id} className="rounded-full ring-2 ring-surface">
              <CandidateAvatar name={cand.nameEn} photoUrl={cand.photoUrl} size={34} />
            </span>
          ))}
        </div>
        <span className="text-[13px] text-muted">
          {candidates.length} {t.nav.candidates.toLowerCase()}
        </span>
      </div>

      <div className="mt-auto flex items-center justify-between gap-3 border-t border-line pt-4">
        <div className="text-[13px] text-muted">
          {phase === "open" && (
            <>
              {t.poll.closes} <span className="font-semibold text-ink"><Countdown to={poll.closesAt.toISOString()} serverNow={now.toISOString()} /></span>
            </>
          )}
          {phase === "upcoming" && <>{t.poll.opens} {formatIst(poll.opensAt, locale)}</>}
          {phase === "closed" && <>{t.poll.closed_at} {formatIst(poll.closesAt, locale)}</>}
        </div>
        <span
          aria-hidden
          className={`relative z-10 rounded-lg px-3 py-1.5 text-sm font-semibold transition ${
            phase === "open" ? "bg-brand-orange-ink text-white group-hover:brightness-95" : "bg-page text-ink group-hover:bg-line"
          }`}
        >
          {phase === "open" ? t.poll.voteNow : phase === "closed" ? t.poll.viewResults : t.poll.viewPoll}
        </span>
      </div>
    </article>
  );
}
