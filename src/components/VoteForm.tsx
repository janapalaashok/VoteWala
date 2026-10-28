"use client";

import Link from "next/link";
import { useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { castVoteAction } from "@/app/actions";
import { CandidateAvatar } from "./CandidateAvatar";

export interface VoteOption {
  id: string;
  label: string;
  sublabel?: string;
  photoUrl: string | null;
  sourceUrl?: string;
  isNone: boolean;
}

type Mode = "signin" | "verify" | "can_vote" | "voted" | "closed";

export interface VoteFormLabels {
  chooseOne: string;
  castVote: string;
  confirmTitle: string;
  confirmBody: string;
  confirm: string;
  cancel: string;
  submitting: string;
  thanks: string;
  youVoted: string;
  signInToVote: string;
  verifyToVote: string;
  notOpen: string;
  officialSource: string;
  errors: Record<string, string>;
}

export function VoteForm({
  pollId,
  options,
  mode,
  votedOptionId,
  labels,
}: {
  pollId: string;
  options: VoteOption[];
  mode: Mode;
  votedOptionId?: string;
  labels: VoteFormLabels;
}) {
  const [selected, setSelected] = useState<string | null>(votedOptionId ?? null);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [pending, start] = useTransition();
  const dialogRef = useRef<HTMLDialogElement>(null);
  const router = useRouter();
  const interactive = mode === "can_vote" && !done;

  const submit = () => {
    if (!selected) return;
    setError(null);
    start(async () => {
      const res = await castVoteAction(pollId, selected);
      dialogRef.current?.close();
      if (res.ok) {
        setDone(true);
        router.refresh();
      } else {
        setError(labels.errors[res.error ?? "generic"] ?? labels.errors.generic);
        if (res.error === "already_voted") router.refresh();
      }
    });
  };

  const chosen = options.find((o) => o.id === selected);

  return (
    <div>
      <fieldset disabled={!interactive}>
        <legend className="mb-3 text-sm font-semibold text-muted">{labels.chooseOne}</legend>
        <div className="grid gap-3" role="radiogroup">
          {options.map((o) => {
            const isSel = selected === o.id;
            return (
              <label
                key={o.id}
                className={`relative flex min-h-[68px] items-center gap-4 rounded-2xl border-2 bg-surface px-4 py-3 transition ${
                  isSel ? "border-brand-orange bg-brand-orange/[0.04] shadow-card" : "border-line"
                } ${interactive ? "cursor-pointer hover:border-brand-navy/30" : ""}`}
              >
                <input
                  type="radio"
                  name="option"
                  value={o.id}
                  checked={isSel}
                  onChange={() => setSelected(o.id)}
                  className="peer sr-only"
                />
                {o.isNone ? (
                  <span aria-hidden className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full border border-dashed border-line text-muted">—</span>
                ) : (
                  <CandidateAvatar name={o.label} photoUrl={o.photoUrl} size={48} />
                )}
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold leading-snug">{o.label}</span>
                  {o.sublabel && <span className="block text-sm text-muted">{o.sublabel}</span>}
                </span>
                <span
                  aria-hidden
                  className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 transition peer-focus-visible:ring-4 peer-focus-visible:ring-brand-orange/30 ${
                    isSel ? "border-brand-orange bg-brand-orange text-white" : "border-line"
                  }`}
                >
                  {isSel && (
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M5 12l5 5L20 7" />
                    </svg>
                  )}
                </span>
              </label>
            );
          })}
        </div>
      </fieldset>

      <div className="mt-6" aria-live="polite">
        {error && <p className="mb-4 rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-800">{error}</p>}
        {(done || mode === "voted") && (
          <p className="flex items-center gap-2 rounded-xl bg-brand-green/10 px-4 py-3 text-[15px] font-semibold text-brand-green-ink">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden>
              <path d="M5 12l5 5L20 7" />
            </svg>
            {done ? labels.thanks : labels.youVoted}
          </p>
        )}
        {mode === "can_vote" && !done && (
          <button type="button" className="btn-primary w-full min-h-[52px] text-base sm:w-auto sm:px-10" disabled={!selected || pending} onClick={() => dialogRef.current?.showModal()}>
            {labels.castVote}
          </button>
        )}
        {mode === "signin" && (
          <Link href={`/signin?callbackUrl=${encodeURIComponent(`/polls/${pollId}`)}`} className="btn-primary w-full min-h-[52px] sm:w-auto sm:px-10">
            {labels.signInToVote}
          </Link>
        )}
        {mode === "verify" && (
          <Link href={`/verify-phone?callbackUrl=${encodeURIComponent(`/polls/${pollId}`)}`} className="btn-primary w-full min-h-[52px] sm:w-auto sm:px-10">
            {labels.verifyToVote}
          </Link>
        )}
        {mode === "closed" && <p className="rounded-xl bg-page px-4 py-3 text-sm text-muted">{labels.notOpen}</p>}
      </div>

      <dialog
        ref={dialogRef}
        className="w-[min(92vw,420px)] rounded-2xl border border-line p-0 shadow-lift backdrop:bg-brand-navy/40 backdrop:backdrop-blur-[2px]"
        aria-labelledby="confirm-title"
      >
        <div className="p-6">
          <h2 id="confirm-title" className="text-lg font-bold">{labels.confirmTitle}</h2>
          {chosen && (
            <div className="mt-4 flex items-center gap-3 rounded-xl bg-page p-3">
              {!chosen.isNone && <CandidateAvatar name={chosen.label} photoUrl={chosen.photoUrl} size={40} />}
              <div>
                <p className="font-semibold">{chosen.label}</p>
                {chosen.sublabel && <p className="text-sm text-muted">{chosen.sublabel}</p>}
              </div>
            </div>
          )}
          <p className="mt-4 text-sm text-muted">{labels.confirmBody}</p>
          <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <button type="button" className="btn-secondary" onClick={() => dialogRef.current?.close()} disabled={pending}>
              {labels.cancel}
            </button>
            <button type="button" className="btn-primary" onClick={submit} disabled={pending}>
              {pending ? labels.submitting : labels.confirm}
            </button>
          </div>
        </div>
      </dialog>
    </div>
  );
}
