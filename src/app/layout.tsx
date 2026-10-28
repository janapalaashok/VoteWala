import type { Metadata, Viewport } from "next";
import "./globals.css";
import { getI18n } from "@/i18n/server";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { MobileTabBar } from "@/components/MobileTabBar";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getI18n();
  return {
    metadataBase: new URL(process.env.NEXTAUTH_URL ?? "http://localhost:3000"),
    title: { default: `VoteWala — ${t.brand.tagline}`, template: "%s · VoteWala" },
    description: t.brand.descriptor,
    applicationName: "VoteWala",
    openGraph: {
      siteName: "VoteWala",
      title: `VoteWala — ${t.brand.tagline}`,
      description: t.brand.descriptor,
      images: [{ url: "/brand/votewala-logo.png" }],
      locale: "en_IN",
      alternateLocale: ["te_IN"],
    },
  };
}

export const viewport: Viewport = {
  themeColor: "#ffffff",
  width: "device-width",
  initialScale: 1,
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const { locale, t } = await getI18n();
  return (
    <html lang={locale === "te" ? "te" : "en-IN"}>
      <body className="flex min-h-screen flex-col">
        <a href="#main" className="sr-only focus:not-sr-only focus:fixed focus:left-3 focus:top-3 focus:z-50 focus:rounded-lg focus:bg-surface focus:px-4 focus:py-2 focus:shadow-lift">
          {t.nav.skipToContent}
        </a>
        <SiteHeader />
        <main id="main" className="flex-1">
          {children}
        </main>
        <SiteFooter />
        <MobileTabBar
          items={[
            { href: "/", label: t.nav.home, icon: "home" },
            { href: "/polls/mla", label: t.nav.mlaPolls, icon: "mla" },
            { href: "/polls/mp", label: t.nav.mpPolls, icon: "mp" },
            { href: "/candidates", label: t.nav.candidates, icon: "candidates" },
            { href: "/results", label: t.nav.results, icon: "results" },
          ]}
        />
      </body>
    </html>
  );
}
