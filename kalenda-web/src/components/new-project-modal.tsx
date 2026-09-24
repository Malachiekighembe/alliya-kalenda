"use client";

import React, { useState } from "react";
import { ProjectStatus } from "@/lib/demo-data";
import { useKalenda } from "@/context/kalenda-context";

const covers = [
  { id: "c1", path: "/covers/cover-01.jpg" },
  { id: "c2", path: "/covers/cover-02.jpg" },
  { id: "c3", path: "/covers/cover-03.jpg" },
  { id: "c4", path: "/covers/cover-04.jpg" },
];

export function NewProjectModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const { addProject } = useKalenda();
  const [name, setName] = useState("");
  const [client, setClient] = useState("");
  const [location, setLocation] = useState("Kinshasa");
  const [contractAmount, setContractAmount] = useState("");
  const [status, setStatus] = useState<ProjectStatus>("planned");
  const [selectedCover, setSelectedCover] = useState(covers[0].path);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    addProject({
      name: name.trim(),
      client: client.trim() || "Client non renseigné",
      location: location.trim() || "Kinshasa",
      contractAmount: parseFloat(contractAmount.replace(/\s/g, "")) || 0,
      status,
      imageUrl: selectedCover,
    });

    setName("");
    setClient("");
    setLocation("Kinshasa");
    setContractAmount("");
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="fixed inset-0 bg-navy/60 backdrop-blur-sm transition-opacity"
        onClick={onClose}
      />
      <div className="relative w-full max-w-lg overflow-hidden rounded-2xl border border-card-border bg-white p-6 shadow-2xl">
        <div className="flex items-center justify-between pb-3 border-b border-card-border">
          <div>
            <h2 className="text-xl font-extrabold text-navy">
              Nouveau projet de chantier
            </h2>
            <p className="text-xs text-navy/60">
              Renseignez les détails pour démarrer le suivi opérationnel.
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-full text-navy/40 hover:bg-surface-high hover:text-navy"
          >
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-3.5">
          <div>
            <label className="text-xs font-bold text-navy">
              Nom du chantier *
            </label>
            <input
              type="text"
              required
              autoFocus
              placeholder="ex. Résidence Bandalungwa"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3.5 py-2 text-sm font-semibold text-navy outline-none focus:border-accent focus:bg-white focus:ring-2 focus:ring-accent/20"
            />
          </div>

          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div>
              <label className="text-xs font-bold text-navy">Client</label>
              <input
                type="text"
                placeholder="ex. M. Mukendi"
                value={client}
                onChange={(e) => setClient(e.target.value)}
                className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3 py-2 text-sm font-medium text-navy outline-none focus:border-accent focus:bg-white focus:ring-2 focus:ring-accent/20"
              />
            </div>
            <div>
              <label className="text-xs font-bold text-navy">Localisation</label>
              <input
                type="text"
                placeholder="ex. Gombe, Kinshasa"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3 py-2 text-sm font-medium text-navy outline-none focus:border-accent focus:bg-white focus:ring-2 focus:ring-accent/20"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div>
              <label className="text-xs font-bold text-navy">Contrat ($)</label>
              <input
                type="number"
                placeholder="ex. 45000"
                value={contractAmount}
                onChange={(e) => setContractAmount(e.target.value)}
                className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3 py-2 text-sm font-medium text-navy outline-none focus:border-accent focus:bg-white focus:ring-2 focus:ring-accent/20"
              />
            </div>
            <div>
              <label className="text-xs font-bold text-navy">Statut</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as ProjectStatus)}
                className="mt-1 w-full rounded-xl border border-card-border bg-surface-low px-3 py-2 text-sm font-medium text-navy outline-none focus:border-accent focus:bg-white focus:ring-2 focus:ring-accent/20"
              >
                <option value="planned">Planifié</option>
                <option value="active">En cours</option>
                <option value="paused">En pause</option>
                <option value="completed">Terminé</option>
              </select>
            </div>
          </div>

          <div>
            <label className="text-xs font-bold text-navy">Couverture</label>
            <div className="mt-1 grid grid-cols-4 gap-2">
              {covers.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => setSelectedCover(c.path)}
                  className={
                    "relative h-14 overflow-hidden rounded-xl border-2 transition " +
                    (selectedCover === c.path
                      ? "border-accent ring-2 ring-accent/30"
                      : "border-transparent opacity-60 hover:opacity-100")
                  }
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={c.path} alt="" className="h-full w-full object-cover" />
                </button>
              ))}
            </div>
          </div>

          <div className="mt-2 flex items-center justify-end gap-2 border-t border-card-border pt-3">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl px-4 py-2 text-sm font-semibold text-navy/70 hover:bg-surface-high hover:text-navy"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="rounded-xl bg-navy px-5 py-2 text-sm font-bold text-white shadow-sm transition hover:bg-navy/90"
            >
              Créer le chantier
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

