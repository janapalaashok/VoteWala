"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { isLocale, LOCALE_COOKIE } from "@/i18n";
import { getCurrentUser } from "@/lib/session";
import { castVote } from "@/lib/vote";
import { requestOtp, verifyOtp } from "@/lib/otp";
import { normalizeIndianMobile, maskPhone } from "@/lib/phone";
import { prisma } from "@/lib/db";

export async function setLocaleAction(locale: string) {
  if (!isLocale(locale)) return;
  (await cookies()).set(LOCALE_COOKIE, locale, { path: "/", maxAge: 60 * 60 * 24 * 365, sameSite: "lax" });
  const user = await getCurrentUser();
  if (user) await prisma.user.update({ where: { id: user.id }, data: { locale } });
  revalidatePath("/", "layout");
}

export type VoteActionState = { ok: boolean; error?: string };

export async function castVoteAction(pollId: string, optionId: string): Promise<VoteActionState> {
  const user = await getCurrentUser();
  if (!user) return { ok: false, error: "signin" };
  if (typeof pollId !== "string" || typeof optionId !== "string") return { ok: false, error: "invalid_option" };
  const result = await castVote(user.id, pollId, optionId);
  if (!result.ok) return { ok: false, error: result.error };
  revalidatePath(`/polls/${pollId}`);
  return { ok: true };
}

export type OtpActionState = { ok: boolean; error?: string; phone?: string };

export async function requestOtpAction(rawPhone: string): Promise<OtpActionState> {
  const user = await getCurrentUser();
  if (!user) return { ok: false, error: "no_challenge" };
  const phone = normalizeIndianMobile(String(rawPhone ?? ""));
  if (!phone) return { ok: false, error: "invalid_phone" };
  const res = await requestOtp(user.id, phone);
  return res.ok ? { ok: true, phone: maskPhone(phone) } : { ok: false, error: res.error };
}

export async function verifyOtpAction(code: string): Promise<OtpActionState> {
  const user = await getCurrentUser();
  if (!user) return { ok: false, error: "no_challenge" };
  const res = await verifyOtp(user.id, String(code ?? "").trim());
  if (res.ok) revalidatePath("/", "layout");
  return res.ok ? { ok: true } : { ok: false, error: res.error };
}
