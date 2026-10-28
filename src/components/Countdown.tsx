"use client";

import { useEffect, useState } from "react";

/** Live countdown to a server-provided instant. Purely informational: the server decides when a poll closes. */
export function Countdown({ to, serverNow }: { to: string; serverNow: string }) {
  const target = new Date(to).getTime();
  const [offset] = useState(() => new Date(serverNow).getTime() - Date.now());
  const [now, setNow] = useState(() => Date.now() + offset);
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now() + offset), 1000);
    return () => clearInterval(id);
  }, [offset]);
  const ms = Math.max(0, target - now);
  const h = Math.floor(ms / 3_600_000);
  const m = Math.floor((ms % 3_600_000) / 60_000);
  const s = Math.floor((ms % 60_000) / 1000);
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    <time dateTime={to} className="font-mono tabular-nums" suppressHydrationWarning>
      {h}:{pad(m)}:{pad(s)}
    </time>
  );
}
