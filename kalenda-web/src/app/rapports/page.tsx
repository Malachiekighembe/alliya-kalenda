"use client";

import { useState } from "react";
import { formatDate } from "@/lib/format";
import { useKalenda } from "@/context/kalenda-context";
import type { Project } from "@/lib/types";

export default function ReportsPage() {
  const { reports, activities, projects, addReport, status } = useKalenda();
  const [composing, setComposing] = useState(false);
  const [project, setProject] = useState("");
  const [summary, setSummary] = useState("");

  const selected = projects.find((item: Project) => item.name === project);

  const submit = (event: React.FormEvent) => {
    event.preventDefault();
    if (!project || !summary.trim()) return;
    addReport({
      date: new Date().toISOString(),
      project,
      title: "Rapport journalier",
      summary: summary.trim(),
      status: "Brouillon",
    });
    setSummary("");
    setComposing(false);
  };

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Rapports</h1>
          <p className="text-sm text-navy/60">
            Rapports quotidiens de chantier, prêts pour l’export PDF.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setComposing((open) => !open)}
          className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
        >
          {composing ? "Annuler" : "+ Nouveau rapport"}
        </button>
      </header>

      {composing ? (
        <form
          onSubmit={submit}
          className="flex flex-col gap-3 rounded-xl border border-card-border bg-white p-4"
        >
          <div>
            <label
              htmlFor="report-project"
              className="text-xs font-bold text-navy"
            >
              Chantier
            </label>
            <select
              id="report-project"
              required
              value={project}
              onChange={(event) => setProject(event.target.value)}
              className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3 py-2 text-sm font-medium text-navy outline-none focus:border-accent"
            >
              <option value="">Choisir un chantier…</option>
              {projects.map((item: Project) => (
                <option key={item.id} value={item.name}>
                  {item.name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label
              htmlFor="report-summary"
              className="text-xs font-bold text-navy"
            >
              Compte rendu
            </label>
            <textarea
              id="report-summary"
              required
              rows={3}
              value={summary}
              onChange={(event) => setSummary(event.target.value)}
              className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3 py-2 text-sm font-medium text-navy outline-none focus:border-accent"
              placeholder="Avancement, livraisons, blocages…"
            />
          </div>
          <p className="text-[11px] font-medium text-navy/50">
            {selected
              ? "Le rapport sera enregistré sur l'API."
              : "Sélectionnez un chantier pour enregistrer sur l'API."}
          </p>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={!project || !summary.trim()}
              className="rounded-xl bg-navy px-4 py-2 text-sm font-bold text-white transition hover:bg-navy/90 disabled:opacity-50"
            >
              Enregistrer
            </button>
          </div>
        </form>
      ) : null}


      <section className="flex flex-col gap-3">
        {reports.length === 0 ? (
          <p className="text-sm text-navy/50">
            {status === "loading" ? "Chargement…" : "Aucun rapport."}
          </p>
        ) : (
          reports.map((report) => (
            <article
              key={report.id}
              className="rounded-xl border border-card-border bg-white p-4"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <p className="text-sm font-extrabold text-navy">
                  {report.project}
                </p>
                <span
                  className={
                    "rounded-full px-2 py-0.5 text-[11px] font-bold " +
                    (report.status === "Validé"
                      ? "bg-green-100 text-green-700"
                      : "bg-surface-high text-navy/60")
                  }
                >
                  {report.status}
                </span>
              </div>
              <p className="mt-1 text-xs text-navy/55">
                {report.title} · {formatDate(new Date(report.date))}
              </p>
              <p className="mt-2 text-sm text-navy/80">{report.summary}</p>
            </article>
          ))
        )}
      </section>

      <section className="rounded-xl border border-card-border bg-white p-4">
        <h2 className="text-sm font-extrabold text-navy">
          Activités incluses dans les prochains rapports
        </h2>
        <ul className="mt-3 flex flex-col divide-y divide-card-border">
          {activities.map((activity, index) => (
            <li key={`${activity.title}-${index}`} className="py-2 text-sm">
              <span className="font-bold text-navy">{activity.time}</span>{" "}
              {activity.title}
              <span className="text-xs text-navy/55">
                {" "}
                · {activity.project} · {activity.status}
              </span>
            </li>
          ))}
          {projects.slice(0, 2).map((item) => (
            <li key={item.id} className="py-2 text-sm text-navy/70">
              Point chantier {item.name} à {item.progress}%
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
