"use client";

import { useState } from "react";
import { Reveal } from "@/components/reveal";
import { useKalenda } from "@/context/kalenda-context";
import { type Activity } from "@/lib/demo-data";
import { deadlineHint, formatDate } from "@/lib/format";

const weekDay = (date: Date) =>
  new Intl.DateTimeFormat("fr-FR", { weekday: "short" }).format(date);

const weekNumber = (date: Date) => date.getDate();

export default function AgendaPage() {
  const { activities, projects, addActivity } = useKalenda();
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState("");
  const [project, setProject] = useState(projects[0]?.name ?? "");
  const [time, setTime] = useState("09:00");
  const [priority, setPriority] = useState<Activity["priority"]>("Normale");
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
          onClick={() => setShowForm(true)}
          className="min-h-11 rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
        >
          + Nouvelle activité
        </button>
      </header>

      <Reveal>
        <section className="grid grid-cols-4 gap-2 sm:grid-cols-7">
          {days.map((date, index) => {
            const isToday = index === 0;
            return (
              <div
                key={date.toISOString()}
                className={
                  "flex flex-col items-center rounded-xl border py-3 transition-all duration-300 hover:-translate-y-0.5 hover:shadow-soft " +
                  (isToday
                    ? "border-accent bg-accent/10"
                    : "border-card-border bg-white hover:border-accent/40")
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
      </Reveal>

      <Reveal delay={80}>
        <section className="rounded-xl border border-card-border bg-white p-4">
          <h2 className="text-sm font-extrabold text-navy">
            Aujourd’hui · {formatDate(today)}
          </h2>
          <ul className="mt-3 flex flex-col gap-3">
            {activities.map((activity) => (
              <li
                key={activity.title}
                className="group flex items-start gap-3 rounded-lg p-1 transition-colors hover:bg-surface-low"
              >
                <span className="mt-1 w-12 shrink-0 text-sm font-extrabold text-accent">
                  {activity.time}
                </span>
                <div className="min-w-0 flex-1 rounded-lg border border-card-border p-3 transition-all duration-300 group-hover:-translate-y-0.5 group-hover:border-accent/40 group-hover:shadow-soft">
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
      </Reveal>

      <Reveal delay={160}>
        <section className="rounded-xl border border-card-border bg-white p-4">
          <h2 className="text-sm font-extrabold text-navy">Échéances</h2>
          <ul className="mt-3 flex flex-col divide-y divide-card-border">
            {projects.map((project) => (
              <li
                key={project.id}
                className="flex items-center justify-between gap-3 rounded-lg px-2 py-2 text-sm transition-colors hover:bg-surface-low"
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
      </Reveal>
      {showForm ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-navy/35 p-3 sm:items-center" role="presentation" onClick={() => setShowForm(false)}>
          <form className="w-full max-w-lg rounded-2xl bg-white p-5 shadow-soft" onClick={(event) => event.stopPropagation()} onSubmit={(event) => { event.preventDefault(); if (!title.trim() || !project) return; addActivity({ title: title.trim(), project, time, priority, status: "À faire" }); setTitle(""); setShowForm(false); }}>
            <div className="mb-4 flex items-center justify-between"><div><h2 className="text-lg font-extrabold text-navy">Nouvelle activité</h2><p className="text-xs text-navy/55">Ajoutez une tâche à votre journée.</p></div><button type="button" onClick={() => setShowForm(false)} className="rounded-lg px-2 py-1 text-sm font-bold text-navy/50">Fermer</button></div>
            <label className="mb-3 block text-xs font-bold text-navy/70">Activité<input required value={title} onChange={(event) => setTitle(event.target.value)} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent" placeholder="Ex. Contrôle des fondations" /></label>
            <div className="grid gap-3 sm:grid-cols-3"><label className="text-xs font-bold text-navy/70">Chantier<select value={project} onChange={(event) => setProject(event.target.value)} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-white px-3 text-sm outline-none focus:border-accent">{projects.map((item) => <option key={item.id}>{item.name}</option>)}</select></label><label className="text-xs font-bold text-navy/70">Heure<input type="time" value={time} onChange={(event) => setTime(event.target.value)} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-app px-3 text-sm outline-none focus:border-accent" /></label><label className="text-xs font-bold text-navy/70">Priorité<select value={priority} onChange={(event) => setPriority(event.target.value as Activity["priority"])} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-white px-3 text-sm outline-none focus:border-accent"><option>Normale</option><option>Haute</option><option>Urgente</option><option>Basse</option></select></label></div>
            <div className="mt-5 flex justify-end gap-2"><button type="button" onClick={() => setShowForm(false)} className="min-h-11 rounded-lg px-4 text-sm font-bold text-navy/60">Annuler</button><button type="submit" className="min-h-11 rounded-lg bg-navy px-4 text-sm font-bold text-white">Enregistrer</button></div>
          </form>
        </div>
      ) : null}
    </div>
  );
}
