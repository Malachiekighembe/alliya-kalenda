import Link from "next/link";
import { compactMoney, deadlineHint, formatDate, money } from "@/lib/format";
import {
  demoActivities,
  demoConversations,
  demoPayments,
  demoProjects,
  demoTotalExpenses,
  projectStatusLabels,
} from "@/lib/demo-data";

function StatCard({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint?: string;
}) {
  return (
    <div className="rounded-xl border border-card-border bg-white p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-navy/50">
        {label}
      </p>
      <p className="mt-1 text-2xl font-extrabold text-navy">{value}</p>
      {hint ? <p className="mt-0.5 text-xs text-navy/50">{hint}</p> : null}
    </div>
  );
}

export default function DashboardPage() {
  const activeProjects = demoProjects.filter((p) => p.status === "active");
  const totalReceived = demoPayments.reduce((sum, p) => sum + p.amount, 0);
  const hero = activeProjects[0] ?? demoProjects[0];
  const upcoming = [...demoProjects]
    .sort(
      (a, b) =>
        new Date(a.plannedEnd).getTime() - new Date(b.plannedEnd).getTime(),
    )
    .slice(0, 3);

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header>
        <h1 className="text-2xl font-extrabold text-navy">Dashboard</h1>
        <p className="text-sm text-navy/60">
          Vue d’ensemble de vos chantiers aujourd’hui.
        </p>
      </header>

      <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard
          label="Projets actifs"
          value={String(activeProjects.length)}
          hint={`sur ${demoProjects.length} projets`}
        />
        <StatCard
          label="Encaissé"
          value={compactMoney(totalReceived)}
          hint="ce mois-ci"
        />
        <StatCard
          label="Dépenses"
          value={compactMoney(demoTotalExpenses)}
          hint="ce mois-ci"
        />
        <StatCard
          label="Activités"
          value={String(demoActivities.length)}
          hint="prévues aujourd’hui"
        />
      </section>

      {hero ? (
        <section className="relative overflow-hidden rounded-2xl bg-navy text-white">
          {/* Photo de chantier en fond (fallback dégradé navy si absente). */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={hero.imageUrl}
            alt=""
            className="absolute inset-0 h-full w-full object-cover opacity-60"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-navy via-navy/50 to-navy/10" />
          <div className="relative flex min-h-[200px] flex-col justify-end gap-1 p-5">
            <span className="w-fit rounded-full bg-white/15 px-2.5 py-0.5 text-xs font-bold">
              {projectStatusLabels[hero.status]}
            </span>
            <h2 className="text-xl font-extrabold">{hero.name}</h2>
            <p className="text-xs text-white/70">
              {hero.client} · {hero.location} · fin prévue le{" "}
              {formatDate(new Date(hero.plannedEnd))} (
              {deadlineHint(new Date(hero.plannedEnd))})
            </p>
            <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-white/25">
              <div
                className="h-full rounded-full bg-accent transition-all"
                style={{ width: `${hero.progress}%` }}
              />
            </div>
            <p className="mt-1 text-xs font-semibold text-white/80">
              {hero.progress}% · contrat {money(hero.contractAmount)}
            </p>
          </div>
        </section>
      ) : null}

      <div className="grid gap-5 lg:grid-cols-2">
        <section className="rounded-xl border border-card-border bg-white p-4">
          <h3 className="text-sm font-extrabold text-navy">
            Activités du jour
          </h3>
          <ul className="mt-3 flex flex-col gap-3">
            {demoActivities.map((activity) => (
              <li key={activity.title} className="flex items-start gap-3">
                <span className="mt-1 w-11 shrink-0 text-xs font-bold text-accent">
                  {activity.time}
                </span>
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-navy">
                    {activity.title}
                  </p>
                  <p className="text-xs text-navy/55">
                    {activity.project} · {activity.status} · priorité{" "}
                    {activity.priority.toLowerCase()}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </section>

        <section className="rounded-xl border border-card-border bg-white p-4">
          <h3 className="text-sm font-extrabold text-navy">
            Progression des projets
          </h3>
          <ul className="mt-3 flex flex-col gap-3">
            {demoProjects.slice(0, 4).map((project) => (
              <li key={project.id} className="flex items-center gap-3">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={project.imageUrl}
                  alt=""
                  className="h-9 w-9 shrink-0 rounded-lg object-cover"
                />
                <div className="min-w-0 flex-1">
                  <div className="flex items-baseline justify-between gap-2">
                    <p className="truncate text-sm font-semibold text-navy">
                      {project.name}
                    </p>
                    <span className="text-xs font-bold text-navy/60">
                      {project.progress}%
                    </span>
                  </div>
                  <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-surface-high">
                    <div
                      className="h-full rounded-full bg-accent"
                      style={{ width: `${project.progress}%` }}
                    />
                  </div>
                </div>
              </li>
            ))}
          </ul>
          <Link
            href="/projets"
            className="mt-3 inline-block text-xs font-bold text-accent hover:underline"
          >
            Voir tous les projets →
          </Link>
        </section>

        <section className="rounded-xl border border-card-border bg-white p-4">
          <h3 className="text-sm font-extrabold text-navy">
            Échéances proches
          </h3>
          <ul className="mt-3 flex flex-col gap-3">
            {upcoming.map((project) => (
              <li
                key={project.id}
                className="flex items-center justify-between gap-3 text-sm"
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

        <section className="rounded-xl border border-card-border bg-white p-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-extrabold text-navy">
              Messages non lus
            </h3>
            <Link
              href="/messages"
              className="text-xs font-bold text-accent hover:underline"
            >
              Ouvrir
            </Link>
          </div>
          <ul className="mt-3 flex flex-col gap-3">
            {demoConversations
              .filter((conversation) => conversation.unread > 0)
              .map((conversation) => (
                <li key={conversation.id} className="flex items-center gap-3">
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-navy text-xs font-bold text-white">
                    {conversation.initials}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold text-navy">
                      {conversation.title}
                    </p>
                    <p className="truncate text-xs text-navy/55">
                      {conversation.subtitle}
                    </p>
                  </div>
                  <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-amber px-1.5 text-[11px] font-bold text-white">
                    {conversation.unread}
                  </span>
                </li>
              ))}
          </ul>
        </section>
      </div>

      <section className="rounded-xl border border-card-border bg-white p-4">
        <h3 className="text-sm font-extrabold text-navy">Paiements récents</h3>
        <ul className="mt-3 flex flex-col divide-y divide-card-border">
          {demoPayments.map((payment) => (
            <li
              key={`${payment.project}-${payment.date}`}
              className="flex items-center justify-between gap-3 py-2 text-sm"
            >
              <div className="min-w-0">
                <p className="truncate font-semibold text-navy">
                  {payment.project}
                </p>
                <p className="text-xs text-navy/55">
                  {payment.date} · {payment.method}
                </p>
              </div>
              <span className="shrink-0 font-bold text-navy">
                {money(payment.amount)}
              </span>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}