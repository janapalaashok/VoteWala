"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import { setLocaleAction } from "@/app/actions";
import type { Locale } from "@/i18n";

export function LanguageSwitcher({ locale, label }: { locale: Locale; label: string }) {
  const [pending, start] = useTransition();
  const router = useRouter();
  const choose = (next: Locale) => {
    if (next === locale) return;
    start(async () => {
      await setLocaleAction(next);
      router.refresh();
    });
  };
  return (
    <div
      role="group"
      aria-label={label}
      className={`inline-flex rounded-xl border border-line bg-page p-0.5 text-[13px] font-semibold ${pending ? "opacity-70" : ""}`}
    >
      {(
        [
          ["te", "తెలుగు", "te"],
          ["en", "English", "en"],
        ] as const
      ).map(([code, text, lang]) => (
        <button
          key={code}
          type="button"
          lang={lang}
          aria-pressed={locale === code}
          onClick={() => choose(code)}
          className={`min-h-[36px] rounded-[10px] px-2.5 transition ${
            locale === code ? "bg-surface text-ink shadow-sm" : "text-muted hover:text-ink"
          }`}
        >
          {text}
        </button>
      ))}
    </div>
  );
}
