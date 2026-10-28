"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { usePathname } from "next/navigation";
import { isActive, type NavItem } from "./NavLinks";

export function MobileMenu({
  items,
  extra,
  labels,
  children,
}: {
  items: NavItem[];
  extra: NavItem[];
  labels: { menu: string; close: string };
  children?: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  const panelRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => setOpen(false), [pathname]);

  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    panelRef.current?.querySelector<HTMLElement>("a,button")?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setOpen(false);
        buttonRef.current?.focus();
      }
      if (e.key === "Tab" && panelRef.current) {
        const f = panelRef.current.querySelectorAll<HTMLElement>("a,button");
        const first = f[0], last = f[f.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
      }
    };
    document.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <>
      <button
        ref={buttonRef}
        type="button"
        aria-expanded={open}
        aria-controls="mobile-menu"
        aria-label={open ? labels.close : labels.menu}
        onClick={() => setOpen((o) => !o)}
        className="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-line bg-surface text-ink"
      >
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
          {open ? <path d="M6 6l12 12M18 6L6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
        </svg>
      </button>
      {open && createPortal(
        // Portalled to <body>: the sticky header uses backdrop-filter, which would
        // otherwise become the containing block for this fixed overlay.
        <div className="fixed inset-0 top-[64px] z-50 lg:hidden">
          <button aria-hidden tabIndex={-1} className="absolute inset-0 bg-brand-navy/30 backdrop-blur-[2px]" onClick={() => setOpen(false)} />
          <div
            id="mobile-menu"
            ref={panelRef}
            role="dialog"
            aria-modal="true"
            aria-label={labels.menu}
            className="relative mx-3 mt-2 rounded-2xl border border-line bg-surface p-3 shadow-lift animate-[fadeIn_.15s_ease-out]"
          >
            <nav>
              <ul className="grid gap-1">
                {[...items, ...extra].map((item) => {
                  const active = isActive(pathname, item.href);
                  return (
                    <li key={item.href}>
                      <Link
                        href={item.href}
                        aria-current={active ? "page" : undefined}
                        className={`flex min-h-[48px] items-center justify-between rounded-xl px-4 text-base font-semibold ${
                          active ? "bg-brand-orange/10 text-ink" : "text-ink hover:bg-page"
                        }`}
                      >
                        {item.label}
                        {active && <span aria-hidden className="h-2 w-2 rounded-full bg-brand-orange" />}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </nav>
            {children && <div className="mt-3 border-t border-line pt-3">{children}</div>}
          </div>
        </div>,
        document.body,
      )}
    </>
  );
}
