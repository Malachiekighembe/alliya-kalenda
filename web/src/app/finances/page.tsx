import { compactMoney, money } from "@/lib/format";
import {
  demoPayments,
  demoProjects,
  demoTotalExpenses,
} from "@/lib/demo-data";

export default function FinancesPage() {
  const totalReceived = demoPayments.reduce((sum, payment) => sum + payment.amount, 0);
  const balance = totalReceived - demoTotalExpenses;

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header>
        <h1 className="text-2xl font-extrabold text-navy">Finances</h1>
        <p className="text-sm text-navy/60">
          Suivi de trésorerie par chantier.
        </p>
      </header>

      <section className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div className="rounded-xl border border-card-border bg-white p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-navy/50">
            Encaissements
          </p>
          <p className="mt-1 text-2xl font-extrabold text-navy">
            {compactMoney(totalReceived)}
          </p>
        </div>
        <div className="rounded-xl border border-card-border bg-white p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-navy/50">
            Dépenses
          </p>
          <p className="mt-1 text-2xl font-extrabold text-navy">
            {compactMoney(demoTotalExpenses)}
          </p>
        </div>
        <div className="rounded-xl border border-card-border bg-white p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-navy/50">
            Solde
          </p>
          <p
            className={
              "mt-1 text-2xl font-extrabold " +
              (balance >= 0 ? "text-navy" : "text-red-600")
            }
          >
            {compactMoney(balance)}
          </p>
        </div>
      </section>

      <div className="grid gap-5 lg:grid-cols-2">
        <section className="rounded-xl border border-card-border bg-white p-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-extrabold text-navy">
              Paiements reçus
            </h2>
            <span className="text-xs font-bold text-navy/50">Montant</span>
          </div>
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

        <section className="rounded-xl border border-card-border bg-white p-4">
          <h2 className="text-sm font-extrabold text-navy">
            Montants contractuels
          </h2>
          <ul className="mt-3 flex flex-col divide-y divide-card-border">
            {demoProjects.map((project) => (
              <li
                key={project.id}
                className="flex items-center justify-between gap-3 py-2 text-sm"
              >
                <div className="min-w-0">
                  <p className="truncate font-semibold text-navy">
                    {project.name}
                  </p>
                  <p className="text-xs text-navy/55">
                    Référence {project.reference}
                  </p>
                </div>
                <span className="shrink-0 font-bold text-navy">
                  {money(project.contractAmount)}
                </span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}