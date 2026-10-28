import Link from "next/link";
import { getI18n } from "@/i18n/server";
import { Logo } from "./Logo";

export async function SiteFooter() {
  const { t } = await getI18n();
  const year = new Date().getFullYear();
  return (
    <footer className="mt-20 bg-brand-navy pb-24 text-white/80 lg:pb-0">
      <div className="container-page grid gap-10 py-14 md:grid-cols-[1.4fr_1fr_1fr]">
        <div>
          {/* The logo sits on a white plate so the original artwork is shown on its intended background. */}
          <Link href="/" className="inline-flex rounded-2xl bg-white p-3 shadow-card" aria-label="VoteWala — home">
            <Logo height={56} />
          </Link>
          <p className="mt-5 max-w-sm text-sm leading-relaxed">{t.footer.about}</p>
        </div>
        <nav aria-label={t.footer.platform}>
          <h2 className="text-sm font-bold uppercase tracking-wider text-white">{t.footer.platform}</h2>
          <ul className="mt-4 space-y-2.5 text-sm">
            <li><Link className="hover:text-white" href="/polls/mla">{t.nav.mlaPolls}</Link></li>
            <li><Link className="hover:text-white" href="/polls/mp">{t.nav.mpPolls}</Link></li>
            <li><Link className="hover:text-white" href="/candidates">{t.nav.candidates}</Link></li>
            <li><Link className="hover:text-white" href="/results">{t.nav.results}</Link></li>
            <li><Link className="hover:text-white" href="/constituencies">{t.nav.constituencies}</Link></li>
          </ul>
        </nav>
        <nav aria-label={t.footer.trust}>
          <h2 className="text-sm font-bold uppercase tracking-wider text-white">{t.footer.trust}</h2>
          <ul className="mt-4 space-y-2.5 text-sm">
            <li><Link className="hover:text-white" href="/methodology">{t.nav.methodology}</Link></li>
            <li><Link className="hover:text-white" href="/methodology#privacy">{t.footer.privacy}</Link></li>
          </ul>
        </nav>
      </div>
      <div className="border-t border-white/10">
        <div className="container-page py-6 text-xs leading-relaxed text-white/60">
          <p className="max-w-4xl">{t.footer.disclaimer}</p>
          <p className="mt-3">© {year} VoteWala. {t.footer.rights}</p>
        </div>
      </div>
    </footer>
  );
}
