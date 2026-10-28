import { describe, expect, it } from "vitest";
import { activeBlackout, pollPhase, resultVisibility, withShares } from "@/lib/results";

const opensAt = new Date("2026-10-27T18:30:00Z");
const closesAt = new Date("2026-10-28T18:30:00Z");
const during = new Date("2026-10-28T06:00:00Z");
const after = new Date("2026-10-28T19:00:00Z");
const before = new Date("2026-10-27T10:00:00Z");
const base = { status: "PUBLISHED" as const, opensAt, closesAt, publishDelayMinutes: 0 };

describe("result publication policy", () => {
  it("LIVE shows running counts while open", () => {
    const v = resultVisibility({ ...base, resultPolicy: "LIVE" }, during);
    expect(v).toEqual({ visible: true, reason: "live", cutoff: during });
  });

  it("DELAYED lags by the configured minutes", () => {
    const v = resultVisibility({ ...base, resultPolicy: "DELAYED", publishDelayMinutes: 60 }, during);
    expect(v.visible && v.cutoff.toISOString()).toBe("2026-10-28T05:00:00.000Z");
  });

  it("AFTER_CLOSE hides results until the poll closes", () => {
    const v = resultVisibility({ ...base, resultPolicy: "AFTER_CLOSE" }, during);
    expect(v).toEqual({ visible: false, reason: "hidden_until_close", revealAt: closesAt });
  });

  it("every policy shows the final result after close, cut at closing time", () => {
    for (const resultPolicy of ["LIVE", "DELAYED", "AFTER_CLOSE"] as const) {
      expect(resultVisibility({ ...base, resultPolicy }, after)).toEqual({ visible: true, reason: "final", cutoff: closesAt });
    }
  });

  it("nothing is shown before opening or for unpublished polls", () => {
    expect(resultVisibility({ ...base, resultPolicy: "LIVE" }, before).visible).toBe(false);
    expect(resultVisibility({ ...base, status: "CANCELLED", resultPolicy: "LIVE" }, after).visible).toBe(false);
    expect(resultVisibility({ ...base, status: "DRAFT", resultPolicy: "LIVE" }, during).visible).toBe(false);
  });

  it("computes poll phase from server time", () => {
    expect(pollPhase({ ...base }, before)).toBe("upcoming");
    expect(pollPhase({ ...base }, during)).toBe("open");
    expect(pollPhase({ ...base }, closesAt)).toBe("closed");
    expect(pollPhase({ ...base, status: "CANCELLED" }, during)).toBe("cancelled");
  });
});

describe("vote shares", () => {
  it("sum to exactly 100% after rounding", () => {
    const rows = withShares([
      { optionId: "a", votes: 1 },
      { optionId: "b", votes: 1 },
      { optionId: "c", votes: 1 },
    ]);
    expect(rows.reduce((s, r) => s + r.share, 0)).toBeCloseTo(1, 10);
    expect(rows.map((r) => r.share).sort()).toEqual([0.333, 0.333, 0.334]);
  });

  it("are zero when there are no votes", () => {
    expect(withShares([{ optionId: "a", votes: 0 }])[0].share).toBe(0);
  });
});

describe("results blackout", () => {
  const spec = "2029-04-09T18:00+05:30/2029-04-11T18:00+05:30, bad/also-bad";
  it("is active inside a configured window and returns its end", () => {
    expect(activeBlackout(new Date("2029-04-10T00:00:00Z"), spec)?.toISOString()).toBe("2029-04-11T12:30:00.000Z");
  });
  it("is inactive outside windows and ignores malformed ranges", () => {
    expect(activeBlackout(new Date("2029-04-11T12:30:00Z"), spec)).toBeNull();
    expect(activeBlackout(new Date("2029-04-01T00:00:00Z"), spec)).toBeNull();
    expect(activeBlackout(new Date(), "")).toBeNull();
  });
});
