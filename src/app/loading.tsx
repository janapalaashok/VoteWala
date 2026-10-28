import { Logo } from "@/components/Logo";

// Branded loading screen shown while server components stream in.
export default function Loading() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-6" role="status" aria-live="polite">
      <div className="animate-pulse">
        <Logo height={96} />
      </div>
      <div className="h-1 w-40 overflow-hidden rounded-full bg-line">
        <div className="h-full w-1/2 origin-left animate-[growX_1.2s_ease-in-out_infinite_alternate] rounded-full bg-brand-orange" />
      </div>
      <span className="sr-only">Loading…</span>
    </div>
  );
}
