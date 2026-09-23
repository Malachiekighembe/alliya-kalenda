import { isSupabaseConfigured } from "@/lib/supabase";

const settingsSections = [
  {
    title: "Profil",
    description: "Nom, société, téléphone et préférences du compte.",
    rows: [
      { label: "Nom complet", value: "À compléter" },
      { label: "Société", value: "À compléter" },
      { label: "Téléphone", value: "À compléter" },
    ],
  },
  {
    title: "Devise & dates",
    description: "Formats utilisés partout dans l’application.",
    rows: [
      { label: "Devise", value: "USD ($)" },
      { label: "Format de date", value: "dd/MM/yyyy" },
      { label: "Langue", value: "Français" },
    ],
  },
  {
    title: "Synchronisation",
    description: "Connexion Supabase partagée avec les apps mobile et desktop.",
    rows: [
      {
        label: "Base Supabase",
        value: isSupabaseConfigured
          ? "Connectée"
          : "Données démo (clé absente)",
      },
      { label: "Dernière synchro", value: "—" },
    ],
  },
];

export default function SettingsPage() {
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header>
        <h1 className="text-2xl font-extrabold text-navy">Paramètres</h1>
        <p className="text-sm text-navy/60">
          Profil, préférences et synchronisation.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-3">
        {settingsSections.map((section) => (
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
                  <dt className="text-navy/70">{row.label}</dt>
                  <dd className="font-semibold text-navy">{row.value}</dd>
                </div>
              ))}
            </dl>
          </section>
        ))}
      </div>

      <section className="rounded-xl border border-card-border bg-white p-4">
        <h2 className="text-sm font-extrabold text-navy">Thème</h2>
        <div className="mt-3 flex gap-3">
          <span className="rounded-lg border-2 border-accent px-4 py-2 text-sm font-bold text-navy">
            Clair
          </span>
          <span className="rounded-lg border border-card-border px-4 py-2 text-sm font-bold text-navy/50">
            Sombre (bientôt)
          </span>
        </div>
      </section>
    </div>
  );
}