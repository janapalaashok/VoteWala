import { describe, expect, it } from "vitest";
import en from "@/i18n/en";
import te from "@/i18n/te";
import { fmt, pick } from "@/i18n";

function leaves(o: unknown, prefix = ""): Record<string, string> {
  if (typeof o === "string") return { [prefix]: o };
  return Object.entries(o as object).reduce((acc, [k, v]) => ({ ...acc, ...leaves(v, prefix ? `${prefix}.${k}` : k) }), {});
}

describe("localisation", () => {
  const e = leaves(en);
  const t = leaves(te);

  it("Telugu covers every English key and nothing else", () => {
    expect(Object.keys(t).sort()).toEqual(Object.keys(e).sort());
  });

  it("has no empty strings", () => {
    for (const [k, v] of Object.entries({ ...e, ...t })) expect(v.trim(), k).not.toBe("");
  });

  it("keeps placeholders consistent", () => {
    for (const k of Object.keys(e)) {
      const ph = (s: string) => (s.match(/\{\w+\}/g) ?? []).sort();
      expect(ph(t[k]), k).toEqual(ph(e[k]));
    }
  });

  it("uses the official brand name and tagline in both languages", () => {
    expect(en.brand.name).toBe("VoteWala");
    expect(en.home.heroTitle).toBe("Your Voice. Your Choice.");
    expect(te.home.heroTitleTe).toBe("మీ అభిప్రాయం. మీ ఎంపిక.");
  });

  it("formats and picks", () => {
    expect(fmt("{n} votes", { n: 3 })).toBe("3 votes");
    expect(pick("te", "Guntur", "గుంటూరు")).toBe("గుంటూరు");
    expect(pick("te", "Guntur", "")).toBe("Guntur");
    expect(pick("en", "Guntur", "గుంటూరు")).toBe("Guntur");
  });
});
