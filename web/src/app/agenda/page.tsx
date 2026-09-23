import { demoActivities, demoProjects } from "@/lib/demo-data";
import { deadlineHint, formatDate } from "@/lib/format";

const weekDay = (date: Date) =>
  new Intl.DateTimeFormat("fr-FR", { weekday: "short" }).format(date);

const weekNumber = (date: Date) => date.getDate();

export default function AgendaPage() {
  const today = new Date();
  const days = Array.from({ length: 7 }, (_, index) => {
    const date = new Date(today);
    date.setDate(today.getDate() + index);
    return date;
  });

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Agenda</h1>
          <p className="text-sm text-navy/60">
            Jour, semaine et échéances de vos chantiers.
          </p>
        </div>
        <button
          type="button"
          className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
        >
          + Nouvelle activité
        </button>
      </header>

      <section className="grid grid-cols-4 gap-2 sm:grid-cols-7">
        {days.map((date, index) => {
          const isToday = index === 0;
          return (
            <div
              key={date.toISOString()}
              className={
                "flex flex-col items-center rounded-xl border py-3 " +
                (isToday
                  ? "border-accent bg-accent/10"
                  : "border-card-border bg-white")
              }
            >
              <span className="text-[11px] font-bold uppercase text-navy/50">
                {weekDay(date)}
              </span>
              <span className="text-lg font-extrabold text-navy">
                {weekNumber(date)}
              </span>
            </div>
          );
        })}
      </section>

      <section className="rounded-xl border border-card-border bg-white p-4">
        <h2 className="text-sm font-extrabold text-navy">
          Aujourd’hui · {formatDate(today)}
        </h2>
        <ul className="mt-3 flex flex-col gap-3">
          {demoActivities.map((activity) => (
            <li key={activity.title} className="flex items-start gap-3">
              <span className="mt-1 w-12 shrink-0 text-sm font-extrabold text-accent">
                {activity.time}
              </span>
              <div className="min-w-0 flex-1 rounded-lg border border-card-border p-3">
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <p className="text-sm font-bold text-navy">
                    {activity.title}
                  </p>
                  <span
                    className={
                      "rounded-full px-2 py-0.5 text-[11px] font-bold " +
                      (activity.priority === "Urgente"
                        ? "bg-red-100 text-red-700"
                        : activity.priority === "Haute"
                          ? "bg-amber/15 text-amber"
                          : "bg-surface-high text-navy/70")
                    }
                  >
                    {activity.priority}
                  </span>
                </div>
                <p className="mt-0.5 text-xs text-navy/55">
                  {activity.project} · {activity.status}
                </p>
              </div>
            </li>
          ))}
        </ul>
      </section>

      <section className="rounded-xl border border-card-border bg-white p-4">
        <h2 className="text-sm font-extrabold text-navy">Échéances</h2>
        <ul className="mt-3 flex flex-col divide-y divide-card-border">
          {demoProjects.map((project) => (
            <li
              key={project.id}
              className="flex items-center justify-between gap-3 py-2 text-sm"
            >
              <span className="truncate font-semibold text-navy">
                {project.name}
              </span>
              <span className="shrink-0 text-xs text-navy/55">
                {formatDate(new Date(project.plannedEnd))} ·{" "}
                {deadlineHint(new Date(project.plannedEnd))}
              </span>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}