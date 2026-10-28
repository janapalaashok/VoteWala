import { parse } from "csv-parse/sync";
import { z } from "zod";

// Candidate records may only cite official election sources.
export const OFFICIAL_SOURCE_HOSTS = [
  "eci.gov.in",
  "affidavit.eci.gov.in",
  "results.eci.gov.in",
  "suvidha.eci.gov.in",
  "ceoandhra.nic.in",
  "ceo.andhra.gov.in",
];

export function isOfficialSource(url: string): boolean {
  try {
    const u = new URL(url);
    if (u.protocol !== "https:") return false;
    const host = u.hostname.toLowerCase();
    return OFFICIAL_SOURCE_HOSTS.some((h) => host === h || host.endsWith(`.${h}`));
  } catch {
    return false;
  }
}

export const CANDIDATE_CSV_HEADERS = [
  "constituency_id",
  "name_en",
  "name_te",
  "party_en",
  "party_te",
  "election_year",
  "source_url",
  "source_label",
  "photo_url",
] as const;

const httpsUrl = z.string().url().refine((u) => u.startsWith("https://"), "must use https");

const rowSchema = z.object({
  constituency_id: z.string().regex(/^(AC-\d{3}|PC-\d{2})$/, "must look like AC-001 or PC-01"),
  name_en: z.string().trim().min(2).max(120),
  name_te: z.string().trim().min(1).max(120),
  party_en: z.string().trim().min(2).max(120),
  party_te: z.string().trim().min(1).max(120),
  election_year: z.coerce.number().int().min(2014).max(2100),
  source_url: httpsUrl.refine(isOfficialSource, "must be an official ECI / CEO Andhra Pradesh link"),
  source_label: z.string().trim().min(2).max(200),
  photo_url: z.union([z.literal(""), httpsUrl]).optional(),
});

export interface CandidateInput {
  constituencyId: string;
  nameEn: string;
  nameTe: string;
  partyEn: string;
  partyTe: string;
  electionYear: number;
  sourceUrl: string;
  sourceLabel: string;
  photoUrl: string | null;
}

export interface ImportError {
  line: number;
  message: string;
}

export function parseCandidateCsv(text: string, knownConstituencies: Set<string>) {
  const rows: CandidateInput[] = [];
  const errors: ImportError[] = [];
  let records: Record<string, string>[];
  try {
    records = parse(text.replace(/^﻿/, ""), { columns: true, skip_empty_lines: true, trim: true });
  } catch (e) {
    return { rows, errors: [{ line: 0, message: `Could not read CSV: ${(e as Error).message}` }] };
  }
  if (records.length > 5000) return { rows, errors: [{ line: 0, message: "At most 5000 rows per import" }] };
  const missing = CANDIDATE_CSV_HEADERS.filter((h) => h !== "photo_url" && records.length > 0 && !(h in records[0]));
  if (missing.length) return { rows, errors: [{ line: 1, message: `Missing columns: ${missing.join(", ")}` }] };

  const seen = new Set<string>();
  records.forEach((rec, i) => {
    const line = i + 2; // header is line 1
    const parsed = rowSchema.safeParse(rec);
    if (!parsed.success) {
      errors.push({ line, message: parsed.error.issues.map((x) => `${x.path.join(".")}: ${x.message}`).join("; ") });
      return;
    }
    const r = parsed.data;
    if (!knownConstituencies.has(r.constituency_id)) {
      errors.push({ line, message: `Unknown constituency ${r.constituency_id}` });
      return;
    }
    const key = `${r.constituency_id}|${r.election_year}|${r.name_en.toLowerCase()}`;
    if (seen.has(key)) {
      errors.push({ line, message: "Duplicate row in file" });
      return;
    }
    seen.add(key);
    rows.push({
      constituencyId: r.constituency_id,
      nameEn: r.name_en,
      nameTe: r.name_te,
      partyEn: r.party_en,
      partyTe: r.party_te,
      electionYear: r.election_year,
      sourceUrl: r.source_url,
      sourceLabel: r.source_label,
      photoUrl: r.photo_url || null,
    });
  });
  return { rows, errors };
}
