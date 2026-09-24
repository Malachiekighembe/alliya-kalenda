"use client";

import { useState } from "react";
import Link from "next/link";
import { deadlineHint, money } from "@/lib/format";
import { projectStatusLabels, ProjectStatus } from "@/lib/demo-data";
import { Reveal } from "@/components/reveal";
import { Progress } from "@/components/progress";
import { useKalenda } from "@/context/kalenda-context";
import { NewProjectModal } from "@/components/new-project-modal";

const statusFilter: Array<{ label: string; value: ProjectStatus | null }> = [
  { label: "Tous", value: null },
  { label: "En cours", value: "active" },
  { label: "Planifiés", value: "planned" },
  { label: "Terminés", value: "completed" },
];

export default function ProjectsPage() {
  const { projects } = useKalenda();
  const [selectedStatus, setSelectedStatus] = useState<ProjectStatus | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const filtered = selectedStatus
    ? projects.filter((p) => p.status === selectedStatus)
    : projects;

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-8 pb-12">
      <Reveal>
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-navy md:text-3xl">
              Vos chantiers
            </h1>
            <p className="mt-1 text-sm text-navy/60">
              Supervisez l’avancement et les indicateurs de tous vos chantiers.
            </p>
          </div>
          <button
            type="button"
            onClick={() => setIsModalOpen(true)}
            className="inline-flex items-center gap-2 rounded-2xl bg-navy px-5 py-3 text-sm font-extrabold text-white shadow-sm transition hover:bg-navy/90 hover:shadow active:scale-95"
          >
            <span className="text-lg leading-none">+</span> Nouveau projet
          </button>
        </header>
      </Reveal>

      {/* Filtres interactifs & aérés */}
      <Reveal delay={80}>
        <div className="flex flex-wrap items-center gap-2.5">
          {statusFilter.map((filter) => {
            const count =
              filter.value === null
                ? projects.length
                : projects.filter((p) => p.status === filter.value).length;
            const isSelected = selectedStatus === filter.value;

            return (
              <button
                key={filter.label}
                type="button"
                onClick={() => setSelectedStatus(filter.value)}
                className={`flex items-center gap-2 rounded-2xl px-4 py-2 text-xs font-bold transition ${
                  isSelected
                    ? "bg-navy text-white shadow-sm"
                    : "border border-card-border bg-white text-navy/70 hover:bg-app-bg hover:text-navy"
                }`}
              >
                <span>{filter.label}</span>
                <span
                  className={`rounded-full px-1.5 py-0.5 text-[10px] font-extrabold ${
                    isSelected ? "bg-white/20 text-white" : "bg-surface-high text-navy"
                  }`}
                >
                  {count}
                </span>
              </button>
            );
          })}
        </div>
      </Reveal>

      {/* Grille de cartes chantiers ultra-aérée et claire */}
      <Reveal delay={160}>
        {filtered.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-card-border bg-white/70 p-12 text-center">
            <p className="text-base font-bold text-navy">Aucun chantier dans cette catégorie</p>
            <p className="mt-1 text-xs text-navy/50">Sélectionnez un autre filtre ou créez un nouveau projet.</p>
          </div>
        ) : (
          <section className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {filtered.map((project) => (
              <Link
                key={project.id}
                href={`/projets/${project.id}`}
                className="group flex flex-col overflow-hidden rounded-3xl border border-card-border bg-white shadow-sm transition hover:-translate-y-1 hover:border-accent/40 hover:shadow-lg"
              >
                {/* Image & badge */}
                <div className="relative h-44 w-full overflow-hidden bg-navy/10">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={project.imageUrl}
                    alt={project.name}
                    className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy/80 via-navy/20 to-transparent" />
                  <span className="absolute left-4 top-4 rounded-full bg-white/95 px-3 py-1 text-[11px] font-extrabold text-navy shadow-sm backdrop-blur">
                    {projectStatusLabels[project.status]}
                  </span>
                  <div className="absolute inset-x-4 bottom-3">
                    <p className="text-[11px] font-semibold text-white/70">
                      Réf. {project.reference}
                    </p>
                    <p className="truncate text-lg font-black text-white">
                      {project.name}
                    </p>
                  </div>
                </div>

                {/* Corps de carte aéré */}
                <div className="flex flex-1 flex-col justify-between p-5">
                  <div className="space-y-3">
                    <div className="space-y-1 text-xs text-navy/60">
                      <p className="font-semibold text-navy/80">
                        {project.client}
                      </p>
                      <p className="truncate">{project.location}</p>
                    </div>

                    {/* Jauge d'avancement */}
                    <div className="space-y-1.5 pt-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-medium text-navy/60">Progression</span>
                        <span className="font-black text-navy">{project.progress}%</span>
                      </div>
                      <Progress value={project.progress} className="h-2 rounded-full" />
                    </div>
                  </div>

                  {/* Pied de carte avec contrat & échéance */}
                  <div className="mt-5 flex items-center justify-between border-t border-card-border pt-4 text-xs">
                    <div>
                      <p className="text-[10px] uppercase tracking-wider text-navy/50 font-bold">Contrat</p>
                      <p className="font-black text-navy">{money(project.contractAmount)}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-[10px] uppercase tracking-wider text-navy/50 font-bold">Échéance</p>
                      <p className="font-semibold text-accent">{deadlineHint(new Date(project.plannedEnd))}</p>
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </section>
        )}
      </Reveal>

      {/* Modale d'ajout de projet */}
      <NewProjectModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
      />
    </div>
  );
}