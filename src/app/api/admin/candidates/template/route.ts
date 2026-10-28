import { getCurrentUser } from "@/lib/session";
import { toCsv } from "@/lib/csv";
import { CANDIDATE_CSV_HEADERS } from "@/lib/candidates-import";
import { csvResponse } from "@/lib/exports";

export async function GET() {
  const user = await getCurrentUser();
  if (user?.role !== "ADMIN") return new Response("Forbidden", { status: 403 });
  return csvResponse(toCsv([[...CANDIDATE_CSV_HEADERS]]), "votewala-candidates-template.csv");
}
