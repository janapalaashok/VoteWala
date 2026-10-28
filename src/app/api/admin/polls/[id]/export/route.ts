import { getCurrentUser } from "@/lib/session";
import { toCsv } from "@/lib/csv";
import { auditExport, csvResponse, pollResultRows, RESULT_HEADER } from "@/lib/exports";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const user = await getCurrentUser();
  if (user?.role !== "ADMIN") return new Response("Forbidden", { status: 403 });
  const { id } = await params;
  const rows = await pollResultRows(id);
  await auditExport(user.id, "poll_results", { pollId: id });
  return csvResponse(toCsv([RESULT_HEADER, ...rows]), `votewala-poll-${id}.csv`);
}
