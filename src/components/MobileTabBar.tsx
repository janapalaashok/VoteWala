"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { isActive } from "./NavLinks";

const icons: Record<string, React.ReactNode> = {
  home: <path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z" />,
  mla: <path d="M4 20V10l8-5 8 5v10M9 20v-5h6v5" />,
  mp: <path d="M3 20h18M5 20V9m4 11V9m6 11V9m4 11V9M2 9l10-5 10 5z" />,
  results: <path d="M4 20V10m6 10V4m6 16v-7m4 7H2" />,
  candidates: <path d="M16 19v-1a4 4 0 00-4-4H8a4 4 0 00-4 4v1M10 10a3 3 0 100-6 3 3 0 000 6zm10 9v-1a4 4 0 00-3-3.9M15 4.1a3 3 0 010 5.8" />,
};

/** Thumb-reachable voting and results controls on small screens. */
export function MobileTabBar({ items }: { items: { href: string; label: string; icon: keyof typeof icons }[] }) {
  const pathname = usePathname();
  return (
    <nav aria-label="Quick navigation" className="fixed inset-x-0 bottom-0 z-30 border-t border-line bg-surface/95 pb-[env(safe-area-inset-bottom)] backdrop-blur lg:hidden">
      <ul className="grid grid-cols-5">
        {items.map((item) => {
          const active = isActive(pathname, item.href);
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={`flex min-h-[58px] flex-col items-center justify-center gap-0.5 text-[11px] font-semibold ${
                  active ? "text-brand-orange-ink" : "text-muted"
                }`}
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  {icons[item.icon]}
                </svg>
                <span className="max-w-full truncate px-1">{item.label}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
