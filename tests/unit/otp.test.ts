import { describe, expect, it } from "vitest";
import { generateOtp, hashOtp, otpMatches } from "@/lib/otp";

describe("OTP codes", () => {
  it("are six digits", () => {
    for (let i = 0; i < 200; i++) expect(generateOtp()).toMatch(/^\d{6}$/);
  });

  it("are stored as keyed hashes bound to the phone number", () => {
    const h = hashOtp("+919876543210", "123456", "secret");
    expect(h).not.toContain("123456");
    expect(otpMatches("+919876543210", "123456", h, "secret")).toBe(true);
    expect(otpMatches("+919876543210", "123457", h, "secret")).toBe(false);
    expect(otpMatches("+919876543211", "123456", h, "secret")).toBe(false);
    expect(otpMatches("+919876543210", "123456", h, "other-secret")).toBe(false);
  });
});
