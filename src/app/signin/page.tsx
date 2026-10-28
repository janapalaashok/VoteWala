import { redirect } from "next/navigation";
import { getI18n } from "@/i18n/server";
import { getCurrentUser } from "@/lib/session";
import { devLoginEnabled } from "@/lib/auth";
import { safeCallback } from "@/lib/safe-url";
import { Logo } from "@/components/Logo";
import { DevSignInForm, GoogleSignInButton } from "@/components/SignInButtons";

export const dynamic = "force-dynamic";
export const metadata = { title: "Sign in" };

export default async function SignInPage({ searchParams }: { searchParams: Promise<{ callbackUrl?: string; error?: string }> }) {
  const sp = await searchParams;
  const callbackUrl = safeCallback(sp.callbackUrl);
  const [{ t }, user] = await Promise.all([getI18n(), getCurrentUser()]);
  if (user) redirect(user.phoneVerifiedAt ? callbackUrl : `/verify-phone?callbackUrl=${encodeURIComponent(callbackUrl)}`);
  const afterLogin = `/verify-phone?callbackUrl=${encodeURIComponent(callbackUrl)}`;

  return (
    <div className="container-page flex min-h-[calc(100vh-180px)] items-center justify-center py-12">
      <div className="w-full max-w-md">
        <div className="card overflow-hidden">
          <div className="flex justify-center border-b border-line bg-surface px-8 pb-6 pt-10">
            <Logo height={120} priority />
          </div>
          <div className="p-7 sm:p-8">
            <h1 className="text-center text-2xl font-bold">{t.auth.signInTitle}</h1>
            <p className="mt-2 text-center text-[15px] leading-relaxed text-muted">{t.auth.signInBody}</p>
            {sp.error && (
              <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-800" role="alert">
                {t.poll.errors.generic}
              </p>
            )}
            <div className="mt-7">
              <GoogleSignInButton label={t.auth.google} callbackUrl={afterLogin} />
            </div>
            {devLoginEnabled() && <DevSignInForm label={t.auth.dev} callbackUrl={afterLogin} />}
            <ol className="mt-8 grid gap-3 text-sm">
              {[t.auth.step1, t.auth.step2, t.auth.step3].map((s, i) => (
                <li key={s} className="flex items-center gap-3">
                  <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-bold ${i === 0 ? "bg-brand-orange-ink text-white" : "bg-page text-muted"}`}>
                    {i + 1}
                  </span>
                  <span className={i === 0 ? "font-semibold" : "text-muted"}>{s}</span>
                </li>
              ))}
            </ol>
          </div>
        </div>
        <p className="mt-5 px-2 text-center text-[13px] leading-relaxed text-muted">{t.auth.privacy}</p>
      </div>
    </div>
  );
}
