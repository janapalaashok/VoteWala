"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { requestOtpAction, verifyOtpAction } from "@/app/actions";
import type { Dictionary } from "@/i18n";
import { fmt } from "@/i18n";

export function PhoneVerifyForm({ t, callbackUrl, welcome }: { t: Dictionary["auth"]; callbackUrl: string; welcome: React.ReactNode }) {
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [sentTo, setSentTo] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [pending, start] = useTransition();
  const router = useRouter();
  const err = (k?: string) => (t.errors as Record<string, string>)[k ?? ""] ?? t.errors.send_failed;

  if (done) {
    return (
      <div className="text-center" aria-live="polite">
        {welcome}
        <h2 className="mt-6 text-2xl font-bold">{t.welcome}</h2>
        <p className="mt-2 text-muted">{t.welcomeBody}</p>
        <Link href={callbackUrl} className="btn-primary mt-7 w-full" onClick={() => router.refresh()}>
          {t.goToPolls}
        </Link>
      </div>
    );
  }

  return (
    <div>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          setError(null);
          start(async () => {
            const r = await requestOtpAction(phone);
            if (r.ok) setSentTo(r.phone ?? phone);
            else setError(err(r.error));
          });
        }}
      >
        <label htmlFor="phone" className="label">{t.mobile}</label>
        <div className="flex gap-2">
          <span className="flex min-h-[44px] items-center rounded-xl border border-line bg-page px-3 text-[15px] font-semibold text-muted">+91</span>
          <input
            id="phone"
            name="phone"
            type="tel"
            inputMode="numeric"
            autoComplete="tel-national"
            required
            maxLength={14}
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="98765 43210"
            className="input"
            disabled={pending}
          />
        </div>
        <button type="submit" className={`${sentTo ? "btn-secondary" : "btn-primary"} mt-3 w-full`} disabled={pending || phone.length < 10}>
          {sentTo ? t.resend : t.sendCode}
        </button>
      </form>

      {sentTo && (
        <form
          className="mt-6 border-t border-line pt-6"
          onSubmit={(e) => {
            e.preventDefault();
            setError(null);
            start(async () => {
              const r = await verifyOtpAction(code);
              if (r.ok) setDone(true);
              else setError(err(r.error));
            });
          }}
        >
          <p className="mb-3 text-sm text-brand-green-ink" aria-live="polite">{fmt(t.codeSent, { phone: sentTo })}</p>
          <label htmlFor="code" className="label">{t.code}</label>
          <input
            id="code"
            name="code"
            inputMode="numeric"
            autoComplete="one-time-code"
            pattern="\d{6}"
            maxLength={6}
            required
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
            className="input text-center font-mono text-2xl tracking-[0.5em]"
            disabled={pending}
          />
          <button type="submit" className="btn-primary mt-3 w-full" disabled={pending || code.length !== 6}>
            {t.verify}
          </button>
        </form>
      )}
      {error && (
        <p role="alert" className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-800">
          {error}
        </p>
      )}
    </div>
  );
}
