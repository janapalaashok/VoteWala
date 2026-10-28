import Link from "next/link";
import { requireAdmin } from "@/lib/session";

export const dynamic = "force-dynamic";
export const metadata = { title: "Admin", robots: { index: false } };

const links = [
  ["/admin", "Dashboard"],
  ["/admin/polls", "Polls"],
  ["/admin/polls/new", "Schedule polls"],
  ["/admin/candidates", "Candidates"],
  ["/admin/audit", "Audit log"],
] as const;

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const admin = await requireAdmin();
  return (
    <div className="container-page py-8">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="eyebrow">Administration</p>
          <p className="text-sm text-muted">Signed in as {admin.email}</p>
        </div>
      </div>
      <div className="grid gap-6 lg:grid-cols-[200px_1fr]">
        <nav aria-label="Admin" className="lg:sticky lg:top-28 lg:self-start">
          <ul className="flex gap-1 overflow-x-auto lg:flex-col">
            {links.map(([href, label]) => (
              <li key={href}>
                <Link href={href} className="block whitespace-nowrap rounded-lg px-3 py-2 text-sm font-semibold text-muted hover:bg-surface hover:text-ink">
                  {label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <div className="min-w-0">{children}</div>
      </div>
    </div>
  );
}
