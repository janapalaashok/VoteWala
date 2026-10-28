import { describe, expect, it } from "vitest";
import { csvCell, toCsv } from "@/lib/csv";

describe("CSV export", () => {
  it("quotes separators and quotes", () => {
    expect(csvCell('a,"b"')).toBe('"a,""b"""');
  });
  it("neutralises spreadsheet formulas", () => {
    expect(csvCell("=HYPERLINK(1)")).toBe("'=HYPERLINK(1)");
    expect(csvCell("+1")).toBe("'+1");
    expect(csvCell("@x")).toBe("'@x");
  });
  it("joins rows with CRLF", () => {
    expect(toCsv([["a", 1], ["b", null]])).toBe("a,1\r\nb,\r\n");
  });
});
