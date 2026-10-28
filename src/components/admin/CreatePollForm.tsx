"use client";

import { useActionState, useState } from "react";
import { createPollsAction, type CreatePollState } from "@/app/admin/actions";

export function CreatePollForm({
  constituency,
  candidates,
  defaultDate,
}: {
  constituency: { id: string; nameEn: string; nameTe: string; type: "ASSEMBLY" | "PARLIAMENTARY" };
  candidates: { id: string; nameEn: string; partyEn: string; electionYear: number; isDemo: boolean }[];
  defaultDate: string;
}) {
  const [state, action, pending] = useActionState<CreatePollState, FormData>(createPollsAction, {});
  const [policy, setPolicy] = useState("AFTER_CLOSE");
  const office = constituency.type === "ASSEMBLY" ? "MLA" : "MP";
  return (
    <form action={action} className="card space-y-6 p-6">
      <input type="hidden" name="constituencyId" value={constituency.id} />
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor="questionEn">Question (English)</label>
          <input id="questionEn" name="questionEn" className="input" required defaultValue={`Who do you prefer as the ${office} for ${constituency.nameEn}?`} />
        </div>
        <div>
          <label className="label" htmlFor="questionTe">Question (Telugu)</label>
          <input
            id="questionTe"
            name="questionTe"
            lang="te"
            className="input"
            required
            defaultValue={`${constituency.nameTe} ${office === "MLA" ? "ఎమ్మెల్యే" : "ఎంపీ"}గా మీరు ఎవరిని ఇష్టపడతారు?`}
          />
        </div>
      </div>

      <fieldset>
        <legend className="label">Options (verified candidates only)</legend>
        {candidates.length === 0 ? (
          <p className="text-sm text-muted">No verified candidates for this constituency. Import and verify candidates first.</p>
        ) : (
          <div className="grid gap-2 sm:grid-cols-2">
            {candidates.map((c) => (
              <label key={c.id} className="flex min-h-[48px] cursor-pointer items-center gap-3 rounded-xl border border-line px-3 py-2 hover:bg-page">
                <input type="checkbox" name="candidateIds" value={c.id} defaultChecked className="h-4 w-4 accent-[rgb(var(--brand-orange))]" />
                <span className="text-sm">
                  <span className="font-semibold">{c.nameEn}</span> <span className="text-muted">· {c.partyEn} · {c.electionYear}</span>
                  {c.isDemo && <span className="chip ml-1 bg-amber-50 text-amber-800">demo</span>}
                </span>
              </label>
            ))}
          </div>
        )}
        <label className="mt-3 flex items-center gap-2 text-sm">
          <input type="checkbox" name="includeNone" defaultChecked className="h-4 w-4" /> Include “None of these / పైవేవీ కాదు”
        </label>
      </fieldset>

      <div className="grid gap-4 sm:grid-cols-4">
        <div>
          <label className="label" htmlFor="startDate">First date (IST)</label>
          <input id="startDate" name="startDate" type="date" className="input" required defaultValue={defaultDate} />
        </div>
        <div>
          <label className="label" htmlFor="days">Repeat for days</label>
          <input id="days" name="days" type="number" min={1} max={31} className="input" defaultValue={1} required />
        </div>
        <div>
          <label className="label" htmlFor="openTime">Opens (IST)</label>
          <input id="openTime" name="openTime" type="time" className="input" defaultValue="00:00" required />
        </div>
        <div>
          <label className="label" htmlFor="closeTime">Closes (IST)</label>
          <select id="closeTime" name="closeTime" className="input" defaultValue="24:00">
            <option value="24:00">End of day (24:00)</option>
            {Array.from({ length: 23 }, (_, i) => `${String(i + 1).padStart(2, "0")}:00`).map((t) => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor="resultPolicy">Result publication</label>
          <select id="resultPolicy" name="resultPolicy" className="input" value={policy} onChange={(e) => setPolicy(e.target.value)}>
            <option value="AFTER_CLOSE">After close (recommended)</option>
            <option value="DELAYED">Delayed</option>
            <option value="LIVE">Live</option>
          </select>
        </div>
        {policy === "DELAYED" && (
          <div>
            <label className="label" htmlFor="publishDelayMinutes">Delay (minutes)</label>
            <input id="publishDelayMinutes" name="publishDelayMinutes" type="number" min={1} max={1440} defaultValue={60} className="input" />
          </div>
        )}
      </div>

      <label className="flex items-center gap-2 text-sm font-semibold">
        <input type="checkbox" name="publish" className="h-4 w-4" /> Publish immediately (otherwise saved as draft)
      </label>

      {state.error && <p role="alert" className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-800">{state.error}</p>}
      <button type="submit" className="btn-primary" disabled={pending || candidates.length === 0}>
        {pending ? "Saving…" : "Create polls"}
      </button>
    </form>
  );
}
