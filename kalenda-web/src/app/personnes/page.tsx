import { initials } from "@/lib/format";
import { demoPeople } from "@/lib/demo-data";
import { Reveal } from "@/components/reveal";

export default function PeoplePage() {
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
          className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
        >
          + Nouvelle personne
        </button>
      </header>

      <div className="rounded-xl border border-card-border bg-white p-3">
        <input
          placeholder="Rechercher dans le répertoire…"
          className="w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent"
        />
      </div>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {demoPeople.map((person, index) => (
          <Reveal key={person.id} delay={Math.min(index * 50, 300)}>
            <article className="flex h-full items-center gap-3 rounded-xl border border-card-border bg-white p-4 transition-all duration-300 hover:-translate-y-0.5 hover:border-accent/40 hover:shadow-soft">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-navy text-sm font-bold text-white shadow-inner">
                {initials(person.name)}
              </span>
              <div className="min-w-0">
                <p className="truncate text-sm font-extrabold text-navy">
                  {person.name}
                </p>
                <p className="truncate text-xs text-navy/55">{person.role}</p>
                <p className="truncate text-xs font-semibold text-accent">{person.project}</p>
              </div>
            </article>
          </Reveal>
        ))}
      </section>
    </div>
  );
}