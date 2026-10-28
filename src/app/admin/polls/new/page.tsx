import { prisma } from "@/lib/db";
import { addDays, istDateString } from "@/lib/time";
import { CreatePollForm } from "@/components/admin/CreatePollForm";

export default async function NewPollPage({ searchParams }: { searchParams: Promise<{ c?: string }> }) {
  const sp = await searchParams;
  const constituencies = await prisma.constituency.findMany({
    orderBy: [{ type: "desc" }, { number: "asc" }],
    select: { id: true, nameEn: true, type: true, _count: { select: { candidates: { where: { status: "VERIFIED" } } } } },
  });
  const selected = sp.c ? await prisma.constituency.findUnique({ where: { id: sp.c } }) : null;
  const candidates = selected
    ? await prisma.candidate.findMany({
        where: { constituencyId: selected.id, status: "VERIFIED" },
        orderBy: [{ electionYear: "desc" }, { nameEn: "asc" }],
        select: { id: true, nameEn: true, partyEn: true, electionYear: true, isDemo: true },
      })
    : [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Schedule daily polls</h1>
      <form method="get" className="card flex flex-col gap-3 p-5 sm:flex-row sm:items-end">
        <div className="flex-1">
          <label htmlFor="c" className="label">Constituency</label>
          <select id="c" name="c" defaultValue={selected?.id ?? ""} className="input" required>
            <option value="" disabled>Select…</option>
            {constituencies.map((c) => (
              <option key={c.id} value={c.id}>
                {c.id} · {c.nameEn} ({c.type === "ASSEMBLY" ? "MLA" : "MP"}) — {c._count.candidates} verified
              </option>
            ))}
          </select>
        </div>
        <button className="btn-navy" type="submit">Continue</button>
      </form>
      {selected && (
        <CreatePollForm
          constituency={{ id: selected.id, nameEn: selected.nameEn, nameTe: selected.nameTe, type: selected.type }}
          candidates={candidates}
          defaultDate={addDays(istDateString(), 1)}
        />
      )}
    </div>
  );
}
