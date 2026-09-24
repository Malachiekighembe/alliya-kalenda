"use client";

import { FormEvent, useMemo, useState } from "react";
import { Reveal } from "@/components/reveal";
import { useKalenda } from "@/context/kalenda-context";
import { initials } from "@/lib/format";

export default function PeoplePage() {
  const { persons, addPerson } = useKalenda();
  const [query, setQuery] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [name, setName] = useState("");
  const [role, setRole] = useState("");
  const [project, setProject] = useState("");

  const filtered = useMemo(() => {
    const search = query.trim().toLowerCase();
    if (!search) return persons;
    return persons.filter((person) =>
      [person.name, person.role, person.project].some((value) =>
        value.toLowerCase().includes(search),
      ),
    );
  }, [persons, query]);

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!name.trim() || !role.trim() || !project.trim()) return;
    addPerson({ name: name.trim(), role: role.trim(), project: project.trim() });
    setName("");
    setRole("");
    setProject("");
    setShowForm(false);
  }

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Personnes</h1>
          <p className="text-sm text-navy/60">
            Répertoire de vos ouvriers et collaborateurs.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowForm(true)}
          className="min-h-11 rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
        >
          + Nouvelle personne
        </button>
      </header>

      <div className="rounded-xl border border-card-border bg-white p-3">
        <label className="sr-only" htmlFor="people-search">Rechercher</label>
        <input
          id="people-search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Rechercher dans le répertoire…"
          className="min-h-11 w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent"
        />
      </div>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {filtered.map((person, index) => (
          <Reveal key={person.id} delay={Math.min(index * 50, 300)}>
            <article className="flex h-full items-center gap-3 rounded-xl border border-card-border bg-white p-4 transition-all duration-300 hover:-translate-y-0.5 hover:border-accent/40 hover:shadow-soft">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-navy text-sm font-bold text-white">
                {initials(person.name)}
              </span>
              <div className="min-w-0">
                <p className="truncate text-sm font-extrabold text-navy">{person.name}</p>
                <p className="truncate text-xs text-navy/55">{person.role}</p>
                <p className="truncate text-xs font-semibold text-accent">{person.project}</p>
              </div>
            </article>
          </Reveal>
        ))}
      </section>
      {filtered.length === 0 ? (
        <p className="rounded-xl border border-card-border bg-white p-6 text-center text-sm text-navy/60">
          Aucune personne ne correspond à votre recherche.
        </p>
      ) : null}

      {showForm ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-navy/35 p-3 sm:items-center" role="presentation" onClick={() => setShowForm(false)}>
          <form className="w-full max-w-lg rounded-2xl bg-white p-5 shadow-soft" onClick={(event) => event.stopPropagation()} onSubmit={submit}>
            <div className="mb-4 flex items-center justify-between">
              <div><h2 className="text-lg font-extrabold text-navy">Nouvelle personne</h2><p className="text-xs text-navy/55">Ajoutez un membre à votre équipe.</p></div>
              <button type="button" onClick={() => setShowForm(false)} className="rounded-lg px-2 py-1 text-sm font-bold text-navy/50">Fermer</button>
            </div>
            <div className="grid gap-3">
              <label className="text-xs font-bold text-navy/70">Nom complet<input required value={name} onChange={(event) => setName(event.target.value)} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent" placeholder="Ex. Jean Kalala" /></label>
              <label className="text-xs font-bold text-navy/70">Fonction<input required value={role} onChange={(event) => setRole(event.target.value)} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent" placeholder="Ex. Chef de chantier" /></label>
              <label className="text-xs font-bold text-navy/70">Projet<input required value={project} onChange={(event) => setProject(event.target.value)} className="mt-1 min-h-11 w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent" placeholder="Ex. Résidence Kasaï" /></label>
            </div>
            <div className="mt-5 flex justify-end gap-2"><button type="button" onClick={() => setShowForm(false)} className="min-h-11 rounded-lg px-4 text-sm font-bold text-navy/60">Annuler</button><button type="submit" className="min-h-11 rounded-lg bg-navy px-4 text-sm font-bold text-white">Enregistrer</button></div>
          </form>
        </div>
      ) : null}
    </div>
  );
}
