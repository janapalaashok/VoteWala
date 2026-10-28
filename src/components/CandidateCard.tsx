import Link from "next/link";
import { pick, type Dictionary, type Locale } from "@/i18n";
import { CandidateAvatar } from "./CandidateAvatar";
import { ExternalIcon, VerifiedIcon } from "./ui";

export interface CandidateCardData {
  id: string;
  nameEn: string;
  nameTe: string;
  partyEn: string;
  partyTe: string;
  electionYear: number;
  photoUrl: string | null;
  sourceUrl: string;
  sourceLabel: string;
  status: string;
  isDemo: boolean;
  constituency?: { nameEn: string; nameTe: string; type: "ASSEMBLY" | "PARLIAMENTARY" };
}

export function CandidateCard({ c, locale, t }: { c: CandidateCardData; locale: Locale; t: Dictionary }) {
  const name = pick(locale, c.nameEn, c.nameTe);
  return (
    <article className="card-interactive flex h-full flex-col p-5">
      <div className="flex items-start gap-4">
        <CandidateAvatar name={c.nameEn} photoUrl={c.photoUrl} size={56} />
        <div className="min-w-0 flex-1">
          <h3 className="text-[17px] font-bold leading-snug">
            <Link href={`/candidates/${c.id}`} className="hover:underline">
              {name}
            </Link>
          </h3>
          <p className="mt-0.5 text-sm text-muted">{pick(locale, c.partyEn, c.partyTe)}</p>
          {c.constituency && (
            <p className="mt-1 text-sm font-medium">
              {pick(locale, c.constituency.nameEn, c.constituency.nameTe)}{" "}
              <span className="text-muted">· {c.constituency.type === "ASSEMBLY" ? t.poll.mla : t.poll.mp} {c.electionYear}</span>
            </p>
          )}
        </div>
      </div>
      <div className="mt-auto flex flex-wrap items-center justify-between gap-2 pt-4">
        {c.status === "VERIFIED" && (
          <span className="chip bg-brand-green/10 text-brand-green-ink">
            <VerifiedIcon /> {t.candidates.verified}
          </span>
        )}
        {c.isDemo && <span className="chip bg-amber-50 text-amber-800">{t.poll.demo}</span>}
        <a
          href={c.sourceUrl}
          target="_blank"
          rel="noopener noreferrer nofollow"
          className="inline-flex items-center gap-1 text-[13px] font-semibold text-brand-navy underline-offset-4 hover:underline"
          title={c.sourceLabel}
        >
          {t.poll.officialSource} <ExternalIcon />
        </a>
      </div>
    </article>
  );
}
