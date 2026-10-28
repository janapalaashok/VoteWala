import { describe, expect, it } from "vitest";
import { maskPhone, normalizeIndianMobile } from "@/lib/phone";

describe("Indian mobile numbers", () => {
  it.each(["9876543210", "+91 98765 43210", "+91-98765-43210", "09876543210", "919876543210", "(98765) 43210"])("accepts %s", (input) => {
    expect(normalizeIndianMobile(input)).toBe("+919876543210");
  });

  it.each(["5876543210", "987654321", "+1 9876543210", "98765432101", "abcdefghij", ""])("rejects %s", (input) => {
    expect(normalizeIndianMobile(input)).toBeNull();
  });

  it("masks numbers for display and logs", () => {
    expect(maskPhone("+919876543210")).toBe("+91 98XXXXXX10");
  });
});
