import { formatDate } from "@/lib/format";
import { demoActivities, demoProjects } from "@/lib/demo-data";

const reports = [
  {
    id: "r1",
    date: new Date(),
    project: "Résidence Kasaï",
    summary:
      "Ferraillage zone B contrôlé, livraison de ciment réceptionnée, aucune blocage critique.",
    status: "Validé",
  },
  {
    id: "r2",
    date: new Date(Date.now() - 86_400_000),
    project: "Atelier Kalenda",
    summary: "Coffrage des poteaux RDC terminé, curse de préparation lancée.",
    status: "Brouillon",
  },
  {
    id: "r3",
    date: new Date(Date.now() - 2 * 86_400_000),
    project: "Bureaux Lumumba",
    summary: "Réception des cloisons sèches, début des travaux de finition.",
    status: "Validé",
  },
];

export default function ReportsPage() {
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
          className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
        >
          + Nouveau rapport
        </button>
      </header>

      <section className="flex flex-col gap-3">
        {reports.map((report) => (
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
            <p className="mt-1 text-xs text-navy/55">{formatDate(report.date)}</p>
            <p className="mt-2 text-sm text-navy/80">{report.summary}</p>
          </article>
        ))}
      </section>

      <section className="rounded-xl border border-card-border bg-white p-4">
        <h2 className="text-sm font-extrabold text-navy">
          Activités incluses dans les prochains rapports
        </h2>
        <ul className="mt-3 flex flex-col divide-y divide-card-border">
          {demoActivities.map((activity) => (
            <li key={activity.title} className="py-2 text-sm">
              <span className="font-bold text-navy">{activity.time}</span>{" "}
              {activity.title}
              <span className="text-xs text-navy/55">
                {" "}
                · {activity.project} · {activity.status}
              </span>
            </li>
          ))}
          {demoProjects.slice(0, 2).map((project) => (
            <li key={project.id} className="py-2 text-sm text-navy/70">
              Point chantier {project.name} à {project.progress}%
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}