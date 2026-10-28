import { describe, expect, it } from "vitest";
import { isOfficialSource, parseCandidateCsv } from "@/lib/candidates-import";

const HEADER = "constituency_id,name_en,name_te,party_en,party_te,election_year,source_url,source_label,photo_url";
const known = new Set(["AC-087", "PC-13"]);

describe("official sources", () => {
  it.each([
    "https://affidavit.eci.gov.in/show-profile/abc",
    "https://results.eci.gov.in/x",
    "https://eci.gov.in/",
    "https://ceoandhra.nic.in/list.pdf",
  ])("accepts %s", (u) => expect(isOfficialSource(u)).toBe(true));

  it.each([
    "http://affidavit.eci.gov.in/x",
    "https://eci.gov.in.evil.com/",
    "https://notaeci.gov.in/",
    "https://wikipedia.org/wiki/x",
    "javascript:alert(1)",
  ])("rejects %s", (u) => expect(isOfficialSource(u)).toBe(false));
});

describe("candidate CSV import", () => {
  it("parses valid rows", () => {
    const csv = `${HEADER}\nAC-087,Person One,వ్యక్తి ఒకటి,Party X,పార్టీ ఎక్స్,2029,https://affidavit.eci.gov.in/p/1,Form 26 affidavit,\n`;
    const { rows, errors } = parseCandidateCsv(csv, known);
    expect(errors).toEqual([]);
    expect(rows).toEqual([
      {
        constituencyId: "AC-087",
        nameEn: "Person One",
        nameTe: "వ్యక్తి ఒకటి",
        partyEn: "Party X",
        partyTe: "పార్టీ ఎక్స్",
        electionYear: 2029,
        sourceUrl: "https://affidavit.eci.gov.in/p/1",
        sourceLabel: "Form 26 affidavit",
        photoUrl: null,
      },
    ]);
  });

  it("reports line-numbered errors for bad rows, unknown constituencies and duplicates", () => {
    const csv = [
      HEADER,
      "AC-087,Person One,ఒకటి,Party X,ఎక్స్,2029,https://example.com/x,Label,",
      "AC-999,Person Two,రెండు,Party X,ఎక్స్,2029,https://eci.gov.in/a,Label,",
      "AC-087,Person Three,మూడు,Party X,ఎక్స్,2029,https://eci.gov.in/a,Label,",
      "AC-087,Person Three,మూడు,Party X,ఎక్స్,2029,https://eci.gov.in/a,Label,",
    ].join("\n");
    const { errors } = parseCandidateCsv(csv, known);
    expect(errors.map((e) => e.line)).toEqual([2, 3, 5]);
    expect(errors[0].message).toMatch(/official/);
    expect(errors[1].message).toMatch(/Unknown constituency/);
    expect(errors[2].message).toMatch(/Duplicate/);
  });

  it("rejects files with missing columns", () => {
    const { errors } = parseCandidateCsv("constituency_id,name_en\nAC-087,X\n", known);
    expect(errors[0].message).toMatch(/Missing columns/);
  });
});
