import { prisma } from "@/lib/db";
import { getCurrentUser } from "@/lib/session";
import { toCsv } from "@/lib/csv";
import { dateOnly, istDateString } from "@/lib/time";
import { auditExport, csvResponse, pollResultRows, RESULT_HEADER } from "@/lib/exports";

export const dynamic = "force-dynamic";

// End-of-day report: every published poll of one IST calendar day.
export async function GET(req: Request) {
  const user = await getCurrentUser();
  if (user?.role !== "ADMIN") return new Response("Forbidden", { status: 403 });
  const date = new URL(req.url).searchParams.get("date") ?? istDateString();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return new Response("Bad date", { status: 400 });
  const polls = await prisma.poll.findMany({ where: { pollDate: dateOnly(date), status: "PUBLISHED" }, select: { id: true }, orderBy: { constituencyId: "asc" } });
  const rows = (await Promise.all(polls.map((p) => pollResultRows(p.id)))).flat();
  await auditExport(user.id, "daily_report", { date });
  return csvResponse(toCsv([RESULT_HEADER, ...rows]), `votewala-daily-report-${date}.csv`);
}
