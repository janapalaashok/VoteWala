import type { Config } from "tailwindcss";

// Colours resolve to CSS variables defined in src/app/globals.css and
// src/styles/brand-tokens.css (regenerated from the logo by `npm run brand`).
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          orange: "rgb(var(--brand-orange) / <alpha-value>)",
          "orange-ink": "rgb(var(--brand-orange-ink) / <alpha-value>)",
          green: "rgb(var(--brand-green) / <alpha-value>)",
          "green-ink": "rgb(var(--brand-green-ink) / <alpha-value>)",
          navy: "rgb(var(--brand-navy) / <alpha-value>)",
        },
        page: "rgb(var(--page) / <alpha-value>)",
        surface: "rgb(var(--surface) / <alpha-value>)",
        ink: "rgb(var(--ink) / <alpha-value>)",
        muted: "rgb(var(--muted) / <alpha-value>)",
        line: "rgb(var(--line) / <alpha-value>)",
      },
      fontFamily: {
        sans: ["'Inter Variable'", "'Noto Sans Telugu'", "system-ui", "sans-serif"],
        telugu: ["'Noto Sans Telugu'", "'Inter Variable'", "sans-serif"],
      },
      boxShadow: {
        card: "0 1px 2px rgb(20 35 61 / 0.05), 0 4px 16px -4px rgb(20 35 61 / 0.08)",
        lift: "0 2px 4px rgb(20 35 61 / 0.06), 0 12px 32px -8px rgb(20 35 61 / 0.16)",
      },
      borderRadius: { xl2: "1.25rem" },
    },
  },
  plugins: [],
};
export default config;
