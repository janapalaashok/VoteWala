import Link from "next/link";
import { getI18n } from "@/i18n/server";
import { getCurrentUser } from "@/lib/session";
import { Logo } from "./Logo";
import { NavLinks } from "./NavLinks";
import { LanguageSwitcher } from "./LanguageSwitcher";
import { MobileMenu } from "./MobileMenu";
import { SignOutButton } from "./SignOutButton";

export async function SiteHeader() {
  const [{ locale, t }, user] = await Promise.all([getI18n(), getCurrentUser()]);
  const items = [
    { href: "/", label: t.nav.home },
    { href: "/polls/mla", label: t.nav.mlaPolls },
    { href: "/polls/mp", label: t.nav.mpPolls },
    { href: "/candidates", label: t.nav.candidates },
    { href: "/results", label: t.nav.results },
  ];
  const extra = [
    { href: "/constituencies", label: t.nav.constituencies },
    { href: "/methodology", label: t.nav.methodology },
    ...(user && !user.phoneVerifiedAt ? [{ href: "/verify-phone", label: t.nav.verifyMobile }] : []),
    ...(user?.role === "ADMIN" ? [{ href: "/admin", label: t.nav.admin }] : []),
  ];
  const initials = (user?.name ?? user?.email ?? "?").slice(0, 1).toUpperCase();

  return (
    <header className="sticky top-0 z-40 border-b border-line bg-surface/95 backdrop-blur supports-[backdrop-filter]:bg-surface/85">
      <div className="container-page flex h-16 items-center gap-4 lg:h-[76px]">
        <Link href="/" className="flex shrink-0 items-center rounded-lg" aria-label="VoteWala — home">
          <Logo height={40} className="lg:hidden" priority />
          <Logo height={52} className="hidden lg:block" priority />
        </Link>

        <nav aria-label="Main" className="ml-4 hidden lg:block">
          <NavLinks items={items} />
        </nav>

        <div className="ml-auto flex items-center gap-2 lg:gap-3">
          <LanguageSwitcher locale={locale} label={t.nav.language} />
          {user ? (
            <details className="group relative hidden lg:block">
              <summary className="flex h-11 cursor-pointer list-none items-center gap-2 rounded-xl border border-line px-2 pr-3 hover:bg-page">
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-navy text-sm font-bold text-white">
                  {initials}
                </span>
                <span className="max-w-[140px] truncate text-sm font-semibold">{user.name ?? user.email}</span>
                {user.phoneVerifiedAt && (
                  <span title="Verified" className="text-brand-green" aria-label="Verified">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                      <path d="M12 2l2.4 2.1 3.2-.3.9 3.1 2.8 1.6-1.2 3 1.2 3-2.8 1.6-.9 3.1-3.2-.3L12 22l-2.4-2.1-3.2.3-.9-3.1-2.8-1.6 1.2-3-1.2-3 2.8-1.6.9-3.1 3.2.3zM10.6 15.6l6-6-1.4-1.4-4.6 4.6-2-2-1.4 1.4z" />
                    </svg>
                  </span>
                )}
              </summary>
              <div className="absolute right-0 mt-2 w-56 rounded-xl border border-line bg-surface p-1.5 shadow-lift">
                {!user.phoneVerifiedAt && (
                  <Link href="/verify-phone" className="block rounded-lg px-3 py-2 text-sm font-semibold text-brand-orange-ink hover:bg-page">
                    {t.nav.verifyMobile}
                  </Link>
                )}
                {user.role === "ADMIN" && (
                  <Link href="/admin" className="block rounded-lg px-3 py-2 text-sm font-semibold hover:bg-page">
                    {t.nav.admin}
                  </Link>
                )}
                <SignOutButton label={t.nav.signOut} className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold hover:bg-page" />
              </div>
            </details>
          ) : (
            <Link href="/signin" className="btn-primary hidden min-h-[42px] px-4 lg:inline-flex">
              {t.nav.signIn}
            </Link>
          )}
          <div className="lg:hidden">
            <MobileMenu items={items} extra={extra} labels={{ menu: t.nav.menu, close: t.nav.closeMenu }}>
              {user ? (
                <div className="flex items-center justify-between gap-3 px-1">
                  <span className="truncate text-sm font-semibold">{user.name ?? user.email}</span>
                  <SignOutButton label={t.nav.signOut} className="btn-secondary min-h-[40px] px-3 text-sm" />
                </div>
              ) : (
                <Link href="/signin" className="btn-primary w-full">
                  {t.nav.signIn}
                </Link>
              )}
            </MobileMenu>
          </div>
        </div>
      </div>
    </header>
  );
}
