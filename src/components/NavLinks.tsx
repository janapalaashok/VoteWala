"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export interface NavItem {
  href: string;
  label: string;
}

export function isActive(pathname: string, href: string) {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function NavLinks({ items }: { items: NavItem[] }) {
  const pathname = usePathname();
  return (
    <ul className="flex items-center gap-1">
      {items.map((item) => {
        const active = isActive(pathname, item.href);
        return (
          <li key={item.href}>
            <Link
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={`relative rounded-lg px-3 py-2 text-[15px] font-semibold transition-colors ${
                active ? "text-ink" : "text-muted hover:text-ink"
              }`}
            >
              {item.label}
              <span
                aria-hidden
                className={`absolute inset-x-3 -bottom-[13px] h-[3px] rounded-full bg-brand-orange transition-opacity ${
                  active ? "opacity-100" : "opacity-0"
                }`}
              />
            </Link>
          </li>
        );
      })}
    </ul>
  );
}
