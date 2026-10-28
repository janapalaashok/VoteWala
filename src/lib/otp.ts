import { createHmac, randomInt, timingSafeEqual } from "node:crypto";
import { Prisma } from "@prisma/client";
import { prisma } from "./db";
import { getSmsSender } from "./sms";
import { audit } from "./audit";
import { maskPhone } from "./phone";

export const OTP_TTL_MS = 5 * 60_000;
export const OTP_MAX_ATTEMPTS = 5;
export const OTP_RESEND_COOLDOWN_MS = 60_000;
export const OTP_MAX_PER_USER_15MIN = 3;
export const OTP_MAX_PER_PHONE_HOUR = 5;

export function generateOtp(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, "0");
}

function otpSecret(): string {
  const s = process.env.OTP_SECRET;
  if (!s) throw new Error("OTP_SECRET is not configured");
  return s;
}

export function hashOtp(phone: string, code: string, secret = otpSecret()): string {
  return createHmac("sha256", secret).update(`${phone}:${code}`).digest("hex");
}

export function otpMatches(phone: string, code: string, storedHash: string, secret = otpSecret()): boolean {
  const a = Buffer.from(hashOtp(phone, code, secret), "hex");
  const b = Buffer.from(storedHash, "hex");
  return a.length === b.length && timingSafeEqual(a, b);
}

export type SendResult =
  | { ok: true }
  | { ok: false; error: "already_verified" | "phone_taken" | "cooldown" | "rate_limited" | "send_failed" };

export async function requestOtp(userId: string, phone: string, now = new Date()): Promise<SendResult> {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (user.phoneVerifiedAt) return { ok: false, error: "already_verified" };

  const owner = await prisma.user.findUnique({ where: { phone } });
  if (owner && owner.id !== userId) return { ok: false, error: "phone_taken" };

  const last = await prisma.otpChallenge.findFirst({ where: { userId }, orderBy: { createdAt: "desc" } });
  if (last && now.getTime() - last.createdAt.getTime() < OTP_RESEND_COOLDOWN_MS) {
    return { ok: false, error: "cooldown" };
  }
  const [perUser, perPhone] = await Promise.all([
    prisma.otpChallenge.count({ where: { userId, createdAt: { gte: new Date(now.getTime() - 15 * 60_000) } } }),
    prisma.otpChallenge.count({ where: { phone, createdAt: { gte: new Date(now.getTime() - 60 * 60_000) } } }),
  ]);
  if (perUser >= OTP_MAX_PER_USER_15MIN || perPhone >= OTP_MAX_PER_PHONE_HOUR) {
    return { ok: false, error: "rate_limited" };
  }

  const code = generateOtp();
  await prisma.$transaction([
    // Only the newest challenge is ever valid.
    prisma.otpChallenge.updateMany({ where: { userId, consumedAt: null }, data: { consumedAt: now } }),
    prisma.otpChallenge.create({
      data: { userId, phone, codeHash: hashOtp(phone, code), expiresAt: new Date(now.getTime() + OTP_TTL_MS), createdAt: now },
    }),
  ]);
  try {
    await getSmsSender().sendOtp(phone, code);
  } catch (err) {
    console.error("OTP send failed", err);
    return { ok: false, error: "send_failed" };
  }
  await audit({ actorId: userId, action: "otp.requested", entityType: "User", entityId: userId, metadata: { phone: maskPhone(phone) } });
  return { ok: true };
}

export type VerifyResult =
  | { ok: true }
  | { ok: false; error: "no_challenge" | "expired" | "too_many_attempts" | "invalid_code" | "phone_taken" };

export async function verifyOtp(userId: string, code: string, now = new Date()): Promise<VerifyResult> {
  const challenge = await prisma.otpChallenge.findFirst({
    where: { userId, consumedAt: null },
    orderBy: { createdAt: "desc" },
  });
  if (!challenge) return { ok: false, error: "no_challenge" };
  if (challenge.expiresAt <= now) return { ok: false, error: "expired" };

  // Count the attempt atomically before checking, so parallel guesses can't exceed the limit.
  const bumped = await prisma.otpChallenge.updateMany({
    where: { id: challenge.id, consumedAt: null, attempts: { lt: OTP_MAX_ATTEMPTS } },
    data: { attempts: { increment: 1 } },
  });
  if (bumped.count === 0) return { ok: false, error: "too_many_attempts" };

  if (!/^\d{6}$/.test(code) || !otpMatches(challenge.phone, code, challenge.codeHash)) {
    return { ok: false, error: "invalid_code" };
  }

  try {
    await prisma.$transaction(async (tx) => {
      const consumed = await tx.otpChallenge.updateMany({
        where: { id: challenge.id, consumedAt: null },
        data: { consumedAt: now },
      });
      if (consumed.count === 0) throw new Error("challenge already consumed");
      await tx.user.update({ where: { id: userId }, data: { phone: challenge.phone, phoneVerifiedAt: now } });
      await audit(
        { actorId: userId, action: "phone.verified", entityType: "User", entityId: userId, metadata: { phone: maskPhone(challenge.phone) } },
        tx,
      );
    });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return { ok: false, error: "phone_taken" };
    }
    if (err instanceof Error && err.message === "challenge already consumed") return { ok: false, error: "no_challenge" };
    throw err;
  }
  return { ok: true };
}
