import { prisma } from "@/lib/db";
import { getCurrentUser } from "@/lib/session";
import { toCsv } from "@/lib/csv";
import { auditExport, csvResponse } from "@/lib/exports";

export const dynamic = "force-dynamic";

export async function GET() {
  const user = await getCurrentUser();
  if (user?.role !== "ADMIN") return new Response("Forbidden", { status: 403 });
  const rows = await prisma.auditLog.findMany({ include: { actor: { select: { email: true } } }, orderBy: { createdAt: "desc" }, take: 50_000 });
  await auditExport(user.id, "audit_log", { rows: String(rows.length) });
  return csvResponse(
    toCsv([
      ["time_utc", "actor", "action", "entity_type", "entity_id", "ip", "metadata"],
      ...rows.map((r) => [r.createdAt.toISOString(), r.actor?.email ?? "system", r.action, r.entityType, r.entityId ?? "", r.ip ?? "", r.metadata ? JSON.stringify(r.metadata) : ""]),
    ]),
    "votewala-audit-log.csv",
  );
}
