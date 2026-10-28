import { NextResponse } from "next/server";
import { timingSafeEqual } from "node:crypto";
import { finalizeClosedPolls } from "@/lib/finalize";

export const dynamic = "force-dynamic";

function authorized(req: Request): boolean {
  const secret = process.env.CRON_SECRET;
  if (!secret) return false;
  const given = Buffer.from(req.headers.get("authorization") ?? "");
  const expected = Buffer.from(`Bearer ${secret}`);
  return given.length === expected.length && timingSafeEqual(given, expected);
}

// Freezes end-of-day reports for closed polls. Call every few minutes (Vercel
// Cron, GitHub Actions, or system cron) with "Authorization: Bearer $CRON_SECRET".
async function handle(req: Request) {
  if (!authorized(req)) return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  const finalized = await finalizeClosedPolls();
  return NextResponse.json({ finalized });
}

export { handle as GET, handle as POST };
