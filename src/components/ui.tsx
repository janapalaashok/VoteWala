import type { Reservation } from "@prisma/client";
import type { Dictionary } from "@/i18n";
import type { PollPhase } from "@/lib/results";

export function SectionHeading({ eyebrow, title, sub, action }: { eyebrow?: string; title: string; sub?: string; action?: React.ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        {eyebrow && <p className="eyebrow mb-1.5">{eyebrow}</p>}
        <h2 className="text-2xl font-bold tracking-tight sm:text-[28px]">{title}</h2>
        {sub && <p className="mt-1.5 max-w-2xl text-[15px] text-muted">{sub}</p>}
      </div>
      {action}
    </div>
  );
}

export function PageHeader({ title, sub, children }: { title: string; sub?: string; children?: React.ReactNode }) {
  return (
    <div className="border-b border-line bg-surface">
      <div className="container-page py-10 sm:py-12">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">{title}</h1>
        {sub && <p className="mt-3 max-w-3xl text-[15px] leading-relaxed text-muted sm:text-base">{sub}</p>}
        {children}
      </div>
    </div>
  );
}

export function PhaseBadge({ phase, t }: { phase: PollPhase; t: Dictionary }) {
  const styles: Record<PollPhase, string> = {
    open: "bg-brand-green/10 text-brand-green-ink",
    upcoming: "bg-brand-navy/5 text-brand-navy",
    closed: "bg-slate-100 text-slate-600",
    cancelled: "bg-red-50 text-red-700",
    draft: "bg-amber-50 text-amber-800",
  };
  return (
    <span className={`chip ${styles[phase]}`}>
      {phase === "open" && (
        <span className="relative flex h-2 w-2" aria-hidden>
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand-green opacity-60" />
          <span className="relative inline-flex h-2 w-2 rounded-full bg-brand-green" />
        </span>
      )}
      {t.poll[phase]}
    </span>
  );
}

export function TypeBadge({ type, t }: { type: "ASSEMBLY" | "PARLIAMENTARY"; t: Dictionary }) {
  return (
    <span className="chip border border-line bg-surface text-ink">
      {type === "ASSEMBLY" ? t.poll.mla : t.poll.mp}
    </span>
  );
}

export function ReservationTag({ r, t }: { r: Reservation; t: Dictionary }) {
  if (r === "GEN") return null;
  return <span className="chip bg-page text-muted">{r === "SC" ? t.common.sc : t.common.st}</span>;
}

export function VerifiedIcon({ className = "" }: { className?: string }) {
  return (
    <svg className={className} width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 2l2.4 2.1 3.2-.3.9 3.1 2.8 1.6-1.2 3 1.2 3-2.8 1.6-.9 3.1-3.2-.3L12 22l-2.4-2.1-3.2.3-.9-3.1-2.8-1.6 1.2-3-1.2-3 2.8-1.6.9-3.1 3.2.3zM10.6 15.6l6-6-1.4-1.4-4.6 4.6-2-2-1.4 1.4z" />
    </svg>
  );
}

export function ExternalIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden>
      <path d="M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 01-1 1H5a1 1 0 01-1-1V7a1 1 0 011-1h5" />
    </svg>
  );
}

export function EmptyState({ children }: { children: React.ReactNode }) {
  return <div className="card px-6 py-12 text-center text-[15px] text-muted">{children}</div>;
}
