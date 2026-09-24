"use client";

import { use } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useKalenda } from "@/context/kalenda-context";
import { money, formatDate, deadlineHint, initials } from "@/lib/format";
import { projectStatusLabels, ProjectStatus } from "@/lib/demo-data";
import { Progress } from "@/components/progress";
import { Reveal } from "@/components/reveal";

export default function ProjectDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);
  const router = useRouter();
  const { projects, updateProject, deleteProject, activities, payments, persons } =
    useKalenda();

  const project = projects.find((p) => p.id === resolvedParams.id);

  if (!project) {
    return (
      <div className="mx-auto flex max-w-3xl flex-col items-center justify-center py-20 text-center">
        <h1 className="text-xl font-extrabold text-navy">Chantier non trouvé</h1>
        <p className="mt-2 text-sm text-navy/60">
          Ce projet n’existe pas ou a été supprimé.
        </p>
        <Link
          href="/projets"
          className="mt-6 rounded-xl bg-navy px-5 py-2.5 text-sm font-bold text-white hover:bg-navy/90"
        >
          Retour aux projets
        </Link>
      </div>
    );
  }

  const projectActivities = activities.filter(
    (a) =>
      a.project.toLowerCase() === project.name.toLowerCase() ||
      a.project === "Tous les projets",
  );
  const projectPayments = payments.filter(
    (p) => p.project.toLowerCase() === project.name.toLowerCase(),
  );
  const totalPaid = projectPayments.reduce((acc, p) => acc + p.amount, 0);
  const remaining = Math.max(0, project.contractAmount - totalPaid);

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8 pb-12">
      {/* Navigation retour & Actions */}
      <Reveal>
        <div className="flex flex-wrap items-center justify-between gap-4">
          <Link
            href="/projets"
            className="inline-flex items-center gap-2 text-sm font-bold text-navy/60 transition hover:text-navy"
          >
            <span aria-hidden="true">←</span> Tous les chantiers
          </Link>
          <div className="flex items-center gap-3">
            <span
              className={`rounded-full px-3.5 py-1 text-xs font-extrabold uppercase tracking-wider ${
                project.status === "active"
                  ? "bg-accent/15 text-accent"
                  : project.status === "completed"
                  ? "bg-emerald-50 text-emerald-700"
                  : project.status === "paused"
                  ? "bg-amber/15 text-amber"
                  : "bg-navy/10 text-navy"
              }`}
            >
              {projectStatusLabels[project.status]}
            </span>
            <button
              type="button"
              onClick={() => {
                if (confirm("Supprimer ce chantier définitivement ?")) {
                  deleteProject(project.id);
                  router.push("/projets");
                }
              }}
              className="rounded-xl border border-red-200 px-3 py-1.5 text-xs font-bold text-red-600 transition hover:bg-red-50"
            >
              Supprimer
            </button>
          </div>
        </div>
      </Reveal>

      {/* Hero photo grand format avec respiration */}
      <Reveal delay={60}>
        <div className="relative overflow-hidden rounded-3xl border border-card-border bg-navy shadow-sm">
          <div className="relative h-72 w-full md:h-96">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={project.imageUrl}
              alt={project.name}
              className="h-full w-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-navy via-navy/55 to-transparent" />
            <div className="absolute inset-x-0 bottom-0 flex flex-col gap-2 p-6 md:p-8 text-white">
              <span className="font-mono text-xs font-semibold tracking-wider text-white/70">
                {project.reference}
              </span>
              <h1 className="text-2xl font-black md:text-4xl">{project.name}</h1>
              <p className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-white/80">
                <span>👤 Client : {project.client}</span>
                <span>📍 {project.location}</span>
                <span>📅 Fin : {formatDate(new Date(project.plannedEnd))} ({deadlineHint(new Date(project.plannedEnd))})</span>
              </p>
            </div>
          </div>
        </div>
      </Reveal>

      {/* Bloc interactif de Progression */}
      <Reveal delay={120}>
        <div className="rounded-3xl border border-card-border bg-white p-6 md:p-8 shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-navy/50">
                Avancement du chantier
              </p>
              <h2 className="mt-1 text-2xl font-black text-navy md:text-3xl">
                {project.progress}% achevé
              </h2>
            </div>
            <div className="flex items-center gap-2">
              {[0, 25, 50, 75, 100].map((step) => (
                <button
                  key={step}
                  type="button"
                  onClick={() => updateProject(project.id, { progress: step })}
                  className={`rounded-xl px-3 py-1.5 text-xs font-bold transition ${
                    project.progress === step
                      ? "bg-navy text-white"
                      : "border border-card-border bg-app-bg text-navy/70 hover:bg-card-border"
                  }`}
                >
                  {step}%
                </button>
              ))}
            </div>
          </div>

          <div className="mt-6">
            <Progress value={project.progress} className="h-4 rounded-full" />
          </div>

          {/* Slider pour ajustement fin */}
          <div className="mt-5 flex items-center gap-4">
            <span className="text-xs font-bold text-navy/60">Ajuster :</span>
            <input
              type="range"
              min="0"
              max="100"
              value={project.progress}
              onChange={(e) =>
                updateProject(project.id, { progress: Number(e.target.value) })
              }
              className="h-2 flex-1 cursor-pointer appearance-none rounded-lg bg-surface-high accent-accent"
            />
            <span className="font-mono text-sm font-bold text-navy">
              {project.progress}%
            </span>
          </div>

          {/* Sélecteur de statut */}
          <div className="mt-6 flex flex-wrap items-center gap-3 border-t border-card-border pt-6">
            <span className="text-xs font-bold uppercase tracking-wider text-navy/50">
              Changer le statut :
            </span>
            {(["planned", "active", "paused", "completed"] as ProjectStatus[]).map(
              (st) => (
                <button
                  key={st}
                  type="button"
                  onClick={() => updateProject(project.id, { status: st })}
                  className={`rounded-xl px-4 py-2 text-xs font-extrabold transition ${
                    project.status === st
                      ? "bg-navy text-white shadow-sm"
                      : "border border-card-border bg-white text-navy/70 hover:bg-app-bg"
                  }`}
                >
                  {projectStatusLabels[st]}
                </button>
              ),
            )}
          </div>
        </div>
      </Reveal>

      {/* Cartes métriques financières */}
      <Reveal delay={180}>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="rounded-2xl border border-card-border bg-white p-6 shadow-sm">
            <p className="text-xs font-bold uppercase tracking-wider text-navy/50">
              Montant contractuel
            </p>
            <p className="mt-2 text-2xl font-black text-navy md:text-3xl">
              {money(project.contractAmount)}
            </p>
            <p className="mt-1 text-xs text-navy/50">Devis validé avec le client</p>
          </div>

          <div className="rounded-2xl border border-card-border bg-white p-6 shadow-sm">
            <p className="text-xs font-bold uppercase tracking-wider text-navy/50">
              Total encaissé
            </p>
            <p className="mt-2 text-2xl font-black text-emerald-600 md:text-3xl">
              {money(totalPaid)}
            </p>
            <p className="mt-1 text-xs text-navy/50">
              {projectPayments.length} règlement(s) enregistré(s)
            </p>
          </div>

          <div className="rounded-2xl border border-card-border bg-white p-6 shadow-sm">
            <p className="text-xs font-bold uppercase tracking-wider text-navy/50">
              Reste à percevoir
            </p>
            <p className="mt-2 text-2xl font-black text-amber md:text-3xl">
              {money(remaining)}
            </p>
            <p className="mt-1 text-xs text-navy/50">Solde contractuel restant</p>
          </div>
        </div>
      </Reveal>

      {/* Deux colonnes : Activités & Paiements */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Colonne Activités */}
        <Reveal delay={240}>
          <div className="flex h-full flex-col rounded-3xl border border-card-border bg-white p-6 md:p-8 shadow-sm">
            <div className="flex items-center justify-between pb-4">
              <h3 className="text-lg font-black text-navy">
                Activités & Tâches ({projectActivities.length})
              </h3>
              <Link
                href="/agenda"
                className="text-xs font-bold text-accent hover:underline"
              >
                + Planifier
              </Link>
            </div>
            {projectActivities.length === 0 ? (
              <div className="flex flex-1 flex-col items-center justify-center py-12 text-center">
                <p className="text-sm font-semibold text-navy/50">
                  Aucune activité spécifique pour ce chantier
                </p>
                <Link
                  href="/agenda"
                  className="mt-3 rounded-xl border border-card-border bg-app-bg px-4 py-2 text-xs font-bold text-navy hover:bg-card-border"
                >
                  Ajouter une tâche
                </Link>
              </div>
            ) : (
              <ul className="mt-3 flex flex-col divide-y divide-card-border">
                {projectActivities.map((act) => (
                  <li key={act.title} className="flex items-start gap-3 py-3">
                    <span className="mt-0.5 rounded-lg bg-surface-high px-2 py-1 font-mono text-xs font-bold text-navy">
                      {act.time}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-bold text-navy">{act.title}</p>
                      <div className="mt-1 flex items-center gap-2 text-xs text-navy/60">
                        <span
                          className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase ${
                            act.priority === "Urgente"
                              ? "bg-red-50 text-red-600"
                              : act.priority === "Haute"
                              ? "bg-amber/15 text-amber"
                              : "bg-navy/10 text-navy"
                          }`}
                        >
                          {act.priority}
                        </span>
                        <span>•</span>
                        <span>{act.status}</span>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </Reveal>

        {/* Colonne Paiements */}
        <Reveal delay={300}>
          <div className="flex h-full flex-col rounded-3xl border border-card-border bg-white p-6 md:p-8 shadow-sm">
            <div className="flex items-center justify-between pb-4">
              <h3 className="text-lg font-black text-navy">
                Paiements ({projectPayments.length})
              </h3>
              <Link
                href="/finances"
                className="text-xs font-bold text-accent hover:underline"
              >
                + Encaisser
              </Link>
            </div>
            {projectPayments.length === 0 ? (
              <div className="flex flex-1 flex-col items-center justify-center py-12 text-center">
                <p className="text-sm font-semibold text-navy/50">
                  Aucun paiement enregistré
                </p>
                <Link
                  href="/finances"
                  className="mt-3 rounded-xl border border-card-border bg-app-bg px-4 py-2 text-xs font-bold text-navy hover:bg-card-border"
                >
                  Enregistrer un paiement
                </Link>
              </div>
            ) : (
              <ul className="mt-3 flex flex-col divide-y divide-card-border">
                {projectPayments.map((p, idx) => (
                  <li
                    key={idx}
                    className="flex items-center justify-between gap-4 py-3"
                  >
                    <div>
                      <p className="text-sm font-bold text-navy">
                        {money(p.amount)}
                      </p>
                      <p className="text-xs text-navy/55">
                        {p.date} • Règlement par {p.method}
                      </p>
                    </div>
                    <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700">
                      Encaissé
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </Reveal>
      </div>

      {/* Équipe mobilisée sur le chantier */}
      <Reveal delay={360}>
        <div className="rounded-3xl border border-card-border bg-white p-6 md:p-8 shadow-sm">
          <div className="flex items-center justify-between pb-4">
            <div>
              <h3 className="text-lg font-black text-navy">
                Intervenants & Équipe chantier
              </h3>
              <p className="text-xs text-navy/50">
                Membres et sous-traitants affectés à ce projet
              </p>
            </div>
            <Link
              href="/personnes"
              className="text-xs font-bold text-accent hover:underline"
            >
              Gérer le répertoire →
            </Link>
          </div>
          <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {persons.slice(0, 3).map((person) => (
              <div
                key={person.id}
                className="flex items-center gap-3.5 rounded-2xl border border-card-border bg-app-bg p-4"
              >
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-navy text-sm font-extrabold text-white">
                  {initials(person.name)}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-navy">
                    {person.name}
                  </p>
                  <p className="truncate text-xs font-medium text-navy/60">
                    {person.role}
                  </p>
                  <p className="mt-0.5 text-[11px] text-accent font-semibold">{person.project}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </Reveal>
    </div>
  );
}

