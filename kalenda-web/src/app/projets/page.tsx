import { deadlineHint, formatDate, money } from "@/lib/format";
import { demoProjects, projectStatusLabels } from "@/lib/demo-data";
import { Reveal } from "@/components/reveal";
import { Progress } from "@/components/progress";

type ProjectStatus = keyof typeof projectStatusLabels;

const statusFilter: Array<{ label: string; value: ProjectStatus | null }> = [
  { label: "Tous", value: null },
  { label: "En cours", value: "active" },
  { label: "Planifiés", value: "planned" },
  { label: "Terminés", value: "completed" },
];

export default function ProjectsPage() {
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <Reveal>
        <header className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-extrabold text-navy">Vos projets</h1>
            <p className="text-sm text-navy/60">
              Suivez chaque chantier au même endroit.
            </p>
          </div>
          <button
            type="button"
            className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white shadow-sm transition-all hover:-translate-y-0.5 hover:bg-navy/90 hover:shadow-md active:translate-y-0"
          >
            + Nouveau projet
          </button>
        </header>
      </Reveal>

      <Reveal delay={80}>
        <div className="flex flex-wrap gap-2">
          {statusFilter.map((filter) => (
            <span
              key={filter.label}
              className={
                "cursor-default rounded-full border px-3 py-1 text-xs font-bold transition-all " +
                (filter.value === null
                  ? "border-navy bg-navy text-white shadow-sm"
                  : "border-card-border bg-white text-navy/70 hover:border-navy/30 hover:text-navy")
              }
            >
              {filter.label}
            </span>
          ))}
        </div>
      </Reveal>

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {demoProjects.map((project, index) => (
          <Reveal key={project.id} delay={Math.min(index * 70, 350)}>
            <article className="group flex h-full flex-col overflow-hidden rounded-xl border border-card-border bg-white transition-all hover:-translate-y-1 hover:border-navy/15 hover:shadow-lg">
              <div className="relative h-36 overflow-hidden">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={project.imageUrl}
                  alt=""
                  className="absolute inset-0 h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-navy/85 via-navy/25 to-transparent" />
                <span className="absolute left-3 top-3 rounded-full bg-white/90 px-2 py-0.5 text-[11px] font-bold text-navy backdrop-blur">
                  {projectStatusLabels[project.status]}
                </span>
                <div className="absolute inset-x-3 bottom-3">
                  <p className="truncate text-base font-extrabold text-white">
                    {project.name}
                  </p>
                  <p className="truncate text-xs text-white/75">
                    {project.reference} · {project.client}
                  </p>
                </div>
              </div>
              <div className="flex flex-1 flex-col gap-3 p-4">
                <p className="flex items-center gap-1.5 text-xs text-navy/55">
                  <span aria-hidden>📍</span>
                  {project.location}
                </p>
                <div>
                  <div className="flex items-baseline justify-between text-xs font-bold text-navy">
                    <span>Progression</span>
                    <span>{project.progress}%</span>
                  </div>
                  <Progress value={project.progress} className="mt-1 h-2" />
                </div>
                <div className="mt-auto flex items-center justify-between border-t border-card-border pt-3 text-xs">
                  <span className="font-bold text-navy">
                    {money(project.contractAmount)}
                  </span>
                  <span className="text-navy/55">
                    {formatDate(new Date(project.plannedEnd))} ·{" "}
                    {deadlineHint(new Date(project.plannedEnd))}
                  </span>
                </div>
              </div>
            </article>
          </Reveal>
        ))}
      </section>
    </div>
  );
}