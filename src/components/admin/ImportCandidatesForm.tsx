"use client";

import { useActionState } from "react";
import { importCandidatesAction, type ImportState } from "@/app/admin/actions";

export function ImportCandidatesForm() {
  const [state, action, pending] = useActionState<ImportState, FormData>(importCandidatesAction, { done: false });
  return (
    <form action={action} className="card space-y-4 p-5" encType="multipart/form-data">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-lg font-bold">Import candidates (CSV)</h2>
        <a href="/api/admin/candidates/template" className="link text-sm">Download template</a>
      </div>
      <p className="text-sm text-muted">
        Every row must link to an official source (eci.gov.in, affidavit.eci.gov.in, results.eci.gov.in, ceoandhra.nic.in).
        Imported and changed records are saved as <strong>PENDING</strong> until an administrator verifies them against the source.
      </p>
      <input type="file" name="file" accept=".csv,text/csv" className="block w-full text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-page file:px-3 file:py-2 file:font-semibold" />
      <details>
        <summary className="cursor-pointer text-sm font-semibold text-muted">…or paste CSV</summary>
        <textarea name="csv" rows={6} className="input mt-2 py-2 font-mono text-xs" />
      </details>
      <button className="btn-navy" type="submit" disabled={pending}>{pending ? "Importing…" : "Import"}</button>
      {state.done && state.errors && state.errors.length > 0 && (
        <div role="alert" className="rounded-xl bg-red-50 p-4 text-sm text-red-800">
          <p className="font-semibold">Nothing was imported. Fix these rows and try again:</p>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            {state.errors.slice(0, 50).map((e, i) => (
              <li key={i}>Line {e.line}: {e.message}</li>
            ))}
          </ul>
        </div>
      )}
      {state.done && state.errors?.length === 0 && (
        <p className="rounded-xl bg-brand-green/10 p-3 text-sm font-semibold text-brand-green-ink">
          Imported: {state.created} new, {state.updated} updated (pending verification).
        </p>
      )}
    </form>
  );
}
