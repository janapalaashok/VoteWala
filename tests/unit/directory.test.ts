import { describe, expect, it } from "vitest";
import { ASSEMBLY, PARLIAMENTARY } from "@/data/constituencies";

describe("Andhra Pradesh constituency directory", () => {
  it("has 175 Assembly and 25 Lok Sabha constituencies numbered without gaps", () => {
    expect(ASSEMBLY.map((a) => a.no)).toEqual(Array.from({ length: 175 }, (_, i) => i + 1));
    expect(PARLIAMENTARY.map((p) => p.no)).toEqual(Array.from({ length: 25 }, (_, i) => i + 1));
  });

  it("maps exactly seven Assembly segments to each Lok Sabha constituency", () => {
    for (const pc of PARLIAMENTARY) {
      expect(ASSEMBLY.filter((a) => a.pc === pc.no).length, pc.en).toBe(7);
    }
  });

  it("has unique English names and Telugu names for every row", () => {
    expect(new Set(ASSEMBLY.map((a) => a.en)).size).toBe(175);
    for (const row of [...ASSEMBLY, ...PARLIAMENTARY]) expect(row.te).toMatch(/[ఀ-౿]/);
  });

  it("matches the reserved-seat totals of the 2008 delimitation (29 SC, 7 ST; 4 SC + 1 ST Lok Sabha)", () => {
    expect(ASSEMBLY.filter((a) => a.res === "SC").length).toBe(29);
    expect(ASSEMBLY.filter((a) => a.res === "ST").length).toBe(7);
    expect(PARLIAMENTARY.filter((p) => p.res === "SC").length).toBe(4);
    expect(PARLIAMENTARY.filter((p) => p.res === "ST").length).toBe(1);
  });
});
