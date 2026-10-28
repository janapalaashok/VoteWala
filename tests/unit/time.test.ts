import { describe, expect, it } from "vitest";
import { addDays, dailyWindow, istDateString, istToUtc } from "@/lib/time";

describe("IST scheduling", () => {
  it("converts IST wall-clock time to UTC", () => {
    expect(istToUtc("2026-10-28", "00:00").toISOString()).toBe("2026-10-27T18:30:00.000Z");
    expect(istToUtc("2026-10-28", "18:30").toISOString()).toBe("2026-10-28T13:00:00.000Z");
  });

  it("finds the IST calendar day of an instant", () => {
    expect(istDateString(new Date("2026-10-27T18:29:59Z"))).toBe("2026-10-27");
    expect(istDateString(new Date("2026-10-27T18:30:00Z"))).toBe("2026-10-28");
  });

  it("builds a full-day window ending at midnight IST", () => {
    const w = dailyWindow("2026-12-31");
    expect(w.opensAt.toISOString()).toBe("2026-12-30T18:30:00.000Z");
    expect(w.closesAt.toISOString()).toBe("2026-12-31T18:30:00.000Z");
  });

  it("rejects invalid dates and inverted windows", () => {
    expect(() => istToUtc("2026-02-30", "00:00")).toThrow();
    expect(() => istToUtc("2026-01-01", "25:00")).toThrow();
    expect(() => dailyWindow("2026-01-01", "18:00", "09:00")).toThrow();
  });

  it("adds days across month and year boundaries", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
    expect(addDays("2028-02-28", 1)).toBe("2028-02-29");
  });
});
