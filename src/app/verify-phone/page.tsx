import Link from "next/link";
import { getI18n } from "@/i18n/server";
import { requireUser } from "@/lib/session";
import { safeCallback } from "@/lib/safe-url";
import { maskPhone } from "@/lib/phone";
import { Logo } from "@/components/Logo";
import { PhoneVerifyForm } from "@/components/PhoneVerifyForm";

export const dynamic = "force-dynamic";
export const metadata = { title: "Verify mobile" };

export default async function VerifyPhonePage({ searchParams }: { searchParams: Promise<{ callbackUrl?: string }> }) {
  const sp = await searchParams;
  const callbackUrl = safeCallback(sp.callbackUrl);
  const user = await requireUser(`/verify-phone?callbackUrl=${encodeURIComponent(callbackUrl)}`);
  const { t } = await getI18n();

  return (
    <div className="container-page flex min-h-[calc(100vh-180px)] items-center justify-center py-12">
      <div className="card w-full max-w-md p-7 sm:p-8">
        {user.phoneVerifiedAt && user.phone ? (
          <div className="text-center">
            <div className="flex justify-center"><Logo height={110} /></div>
            <h1 className="mt-6 text-2xl font-bold">{t.auth.welcome}</h1>
            <p className="mt-2 text-muted">{t.auth.welcomeBody}</p>
            <p className="mt-4 inline-flex items-center gap-2 rounded-full bg-brand-green/10 px-3 py-1 text-sm font-semibold text-brand-green-ink">
              {t.auth.verified} <span className="font-mono">{maskPhone(user.phone)}</span>
            </p>
            <Link href={callbackUrl} className="btn-primary mt-7 w-full">{t.auth.goToPolls}</Link>
          </div>
        ) : (
          <>
            <div className="mb-6 flex justify-center"><Logo height={72} /></div>
            <h1 className="text-center text-2xl font-bold">{t.auth.verifyTitle}</h1>
            <p className="mb-7 mt-2 text-center text-[15px] leading-relaxed text-muted">{t.auth.verifyBody}</p>
            <PhoneVerifyForm
              t={t.auth}
              callbackUrl={callbackUrl}
              welcome={<div className="flex justify-center"><Logo height={110} /></div>}
            />
          </>
        )}
      </div>
    </div>
  );
}
