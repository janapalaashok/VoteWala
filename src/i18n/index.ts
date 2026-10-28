import en, { type Dictionary } from "./en";
import te from "./te";

export type Locale = "en" | "te";
export const LOCALES: Locale[] = ["en", "te"];
export const LOCALE_COOKIE = "vw_locale";

export const dictionaries: Record<Locale, Dictionary> = { en, te };

export function isLocale(v: unknown): v is Locale {
  return v === "en" || v === "te";
}

/** Replaces {name} placeholders. */
export function fmt(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, k) => String(vars[k] ?? `{${k}}`));
}

/** Picks the Telugu or English field of a bilingual record. */
export function pick(locale: Locale, en: string, te: string | null | undefined): string {
  return locale === "te" && te ? te : en;
}

export function formatNumber(n: number, locale: Locale): string {
  return new Intl.NumberFormat(locale === "te" ? "te-IN" : "en-IN").format(n);
}

export type { Dictionary };
