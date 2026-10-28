import Link from "next/link";
import { getI18n } from "@/i18n/server";

export default async function NotFound() {
  const { t } = await getI18n();
  return (
    <div className="container-page flex min-h-[50vh] flex-col items-center justify-center py-20 text-center">
      <p className="eyebrow">404</p>
      <h1 className="mt-2 text-3xl font-bold">{t.common.notFound}</h1>
      <p className="mt-3 text-muted">{t.common.notFoundBody}</p>
      <Link href="/" className="btn-primary mt-8">{t.common.goHome}</Link>
    </div>
  );
}
