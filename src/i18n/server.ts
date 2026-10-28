import { cookies, headers } from "next/headers";
import { dictionaries, isLocale, LOCALE_COOKIE, type Locale } from "./index";

export async function getLocale(): Promise<Locale> {
  const c = (await cookies()).get(LOCALE_COOKIE)?.value;
  if (isLocale(c)) return c;
  const accept = (await headers()).get("accept-language") ?? "";
  return /^te\b/i.test(accept.trim()) ? "te" : "en";
}

export async function getI18n() {
  const locale = await getLocale();
  return { locale, t: dictionaries[locale] };
}
