"use client";

import Link from "next/link";
import { API_URL, isApiConfigured } from "@/lib/api";
import { useKalenda } from "@/context/kalenda-context";

/** Valeur affichee : la donnee reelle si elle existe, sinon un tiret. */
const show = (value: string | undefined, placeholder = "À compléter") =>
  value && value.trim() ? value : placeholder;

const statusLabels: Record<string, string> = {
  unauthenticated: "Non connecté",
  loading: "Synchronisation en cours…",
  ready: "Connecté à l'API",
  error: "Erreur de synchronisation",
  unconfigured: "API non configurée",
};

export default function SettingsPage() {
  const { user, profile, isOnline, status, error, logout, refresh } =
    useKalenda();

  const sections = [
    {
      title: "Profil",
      description: "Informations du compte connecté à l'API.",
      rows: [
        { label: "Nom complet", value: show(profile?.profile?.fullName) },
        { label: "Société", value: show(profile?.profile?.companyName) },
        { label: "Téléphone", value: show(profile?.profile?.phone) },
        { label: "E-mail", value: show(user?.email) },
      ],
    },
    {
      title: "Devise & dates",
      description: "Formats utilisés dans l'application.",
      rows: [
        { label: "Devise", value: profile?.profile?.currency ?? "USD ($)" },
        {
          label: "Format de date",
          value: profile?.profile?.dateFormat ?? "dd/MM/yyyy",
        },
        { label: "Langue", value: "Français" },
      ],
    },
    {
      title: "Synchronisation",
      description: "Connexion au backend Alliya Kalenda.",
      rows: [
        {
          label: "API",
          value: isApiConfigured() ? API_URL : "Non configurée",
        },
        { label: "État", value: statusLabels[status] ?? status },
        {
          label: "Dernière synchro",
          value: error ? error : status === "ready" ? "À l'instant" : "—",
        },
      ],
    },
  ];

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header>
        <h1 className="text-2xl font-extrabold text-navy">Paramètres</h1>
        <p className="text-sm text-navy/60">
          Profil, préférences et synchronisation.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-3">
        {sections.map((section) => (
          <section
            key={section.title}
            className="rounded-xl border border-card-border bg-white p-4"
          >
            <h2 className="text-sm font-extrabold text-navy">
              {section.title}
            </h2>
            <p className="mt-0.5 text-xs text-navy/55">{section.description}</p>
            <dl className="mt-3 flex flex-col divide-y divide-card-border">
              {section.rows.map((row) => (
                <div
                  key={row.label}
                  className="flex items-center justify-between gap-3 py-2 text-sm"
                >
                  <dt className="text-navy/60">{row.label}</dt>
                  <dd className="truncate text-right font-semibold text-navy">
                    {row.value}
                  </dd>
                </div>
              ))}
            </dl>
          </section>
        ))}
      </div>


      <section className="rounded-xl border border-card-border bg-white p-4">
        <h2 className="text-sm font-extrabold text-navy">Session</h2>
        <p className="mt-0.5 text-xs text-navy/55">
          {isOnline
            ? "Vos données sont enregistrées sur le serveur Alliya Kalenda."
            : "Aucune session ouverte : connectez-vous pour charger vos données."}
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void refresh()}
            disabled={!isOnline || status === "loading"}
            className="rounded-lg border border-card-border px-4 py-2 text-sm font-bold text-navy/70 transition-colors hover:border-accent hover:text-accent disabled:opacity-50"
          >
            Synchroniser maintenant
          </button>
          {isOnline ? (
            <button
              type="button"
              onClick={logout}
              className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
            >
              Se déconnecter
            </button>
          ) : (
            <Link
              href="/connexion"
              className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-navy/90"
            >
              Se connecter
            </Link>
          )}
        </div>
      </section>
    </div>
  );
}
