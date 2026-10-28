"use client";

import { signOut } from "next-auth/react";

export function SignOutButton({ label, className = "" }: { label: string; className?: string }) {
  return (
    <button type="button" onClick={() => signOut({ callbackUrl: "/" })} className={className}>
      {label}
    </button>
  );
}
