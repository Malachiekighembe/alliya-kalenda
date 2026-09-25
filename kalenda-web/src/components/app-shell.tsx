"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useState } from "react";

/// Icônes SVG inline (style Material, calquées sur les destinations du
/// NavigationRail / NavigationBar Flutter).
const icons: Record<string, React.ReactNode> = {
  dashboard: (
    <path d="M4 13h6V4H4v9Zm0 7h6v-5H4v5Zm10 0h6v-9h-6v9Zm0-16v5h6V4h-6Z" />
  ),
  calendar: (
    <path d="M19 4h-1V2h-2v2H8V2H6v2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2Zm0 16H5V10h14v10Zm0-12H5V6h14v2Z" />
  ),
  building: (
    <path d="M15 11V5l-3-3-3 3v2H3v14h18V11h-6Zm-8 8H5v-2h2v2Zm0-4H5v-2h2v2Zm0-4H5V9h2v2Zm6 8h-2v-2h2v2Zm0-4h-2v-2h2v2Zm0-4h-2V9h2v2Zm0-4h-2V5h2v2Zm6 12h-2v-2h2v2Zm0-4h-2v-2h2v2Z" />
  ),
  forum: (
    <path d="M21 6h-2v9H6v2c0 .55.45 1 1 1h11l4 4V7c0-.55-.45-1-1-1Zm-4 6V3c0-.55-.45-1-1-1H3c-.55 0-1 .45-1 1v14l4-4h10c.55 0 1-.45 1-1Z" />
  ),
  groups: (
    <path d="M16 11c1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3 1.34 3 3 3Zm-8 0c1.66 0 3-1.34 3-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3Zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5Zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5Z" />
  ),
  wallet: (
    <path d="M21 7H5a1 1 0 0 1 0-2h14V3H5a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3h16a1 1 0 0 0 1-1V8a1 1 0 0 0-1-1Zm-3 7a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3Z" />
  ),
  report: (
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6Zm4 18H6V4h7v5h5v11Zm-3-7H9v-2h6v2Zm-3 4H9v-2h4v2Z" />
  ),
  settings: (
    <path d="M19.14 12.94a7.07 7.07 0 0 0 0-1.88l2.03-1.58a.5.5 0 0 0 .12-.64l-1.92-3.32a.5.5 0 0 0-.61-.22l-2.39.96a7.03 7.03 0 0 0-1.62-.94l-.36-2.54a.5.5 0 0 0-.5-.42h-3.84a.5.5 0 0 0-.5.42l-.36 2.54c-.58.24-1.12.56-1.62.94l-2.39-.96a.5.5 0 0 0-.61.22L2.67 8.84a.5.5 0 0 0 .12.64l2.03 1.58a7.07 7.07 0 0 0 0 1.88l-2.03 1.58a.5.5 0 0 0-.12.64l1.92 3.32c.13.22.39.3.61.22l2.39-.96c.5.38 1.04.7 1.62.94l.36 2.54c.04.24.25.42.5.42h3.84c.25 0 .46-.18.5-.42l.36-2.54c.58-.24 1.12-.56 1.62-.94l2.39.96c.22.08.48 0 .61-.22l1.92-3.32a.5.5 0 0 0-.12-.64l-2.03-1.58ZM12 15.6A3.6 3.6 0 1 1 12 8.4a3.6 3.6 0 0 1 0 7.2Z" />
  ),
};

const primaryNav = [
  { href: "/", label: "Dashboard", icon: "dashboard" },
  { href: "/agenda", label: "Agenda", icon: "calendar" },
  { href: "/projets", label: "Projets", icon: "building" },
  { href: "/messages", label: "Messages", icon: "forum" },
  { href: "/personnes", label: "Personnes", icon: "groups" },
];

const secondaryNav = [
  { href: "/finances", label: "Finances", icon: "wallet" },
  { href: "/rapports", label: "Rapports", icon: "report" },
  { href: "/parametres", label: "Paramètres", icon: "settings" },
];

const mobilePrimaryNav = primaryNav.slice(0, 4);

/// Barre latérale fixe (desktop) + barre de navigation basse (mobile),
/// miroir du NavigationRail / NavigationBar Flutter.
export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [moreOpen, setMoreOpen] = useState(false);
  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  const navLink = (item: { href: string; label: string; icon: string }) => {
    const active = isActive(item.href);
    return (
      <Link
        key={item.href}
        href={item.href}
        aria-current={active ? "page" : undefined}
        className={
          "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-semibold transition-colors " +
          (active
            ? "bg-accent/10 text-accent"
            : "text-navy/70 hover:bg-surface-high hover:text-navy")
        }
      >
        <svg viewBox="0 0 24 24" className="h-5 w-5 shrink-0 fill-current">
          {icons[item.icon]}
        </svg>
        <span className="hidden md:inline">{item.label}</span>
      </Link>
    );
  };

  return (
    <div className="flex min-h-screen">
      {/* Rail desktop */}
      <aside className="sticky top-0 hidden h-screen w-16 flex-col border-r border-card-border bg-white md:flex md:w-56 lg:w-60">
        <div className="flex items-center gap-2 px-4 py-5">
          <Image
            src="/icon.png"
            alt="Logo Alliya Kalenda"
            width={40}
            height={40}
            priority
            className="h-10 w-10 rounded-xl object-cover shadow-sm ring-1 ring-navy/10"
          />
          <span className="hidden text-base font-extrabold tracking-tight text-navy md:inline">
            Alliya Kalenda
          </span>
        </div>
        <nav className="flex flex-1 flex-col gap-1 px-2">
          {primaryNav.map(navLink)}
          <div className="my-3 border-t border-card-border" />
          {secondaryNav.map(navLink)}
        </nav>
        <div className="px-4 py-4 text-xs font-medium text-navy/50">
          Mobile &amp; desktop
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-3 border-b border-card-border bg-white px-4 py-3 md:hidden">
          <Image
            src="/icon.png"
            alt="Logo Alliya Kalenda"
            width={36}
            height={36}
            priority
            className="h-9 w-9 rounded-lg object-cover shadow-sm ring-1 ring-navy/10"
          />
          <div className="min-w-0">
            <p className="truncate text-sm font-extrabold tracking-tight text-navy">
              Alliya Kalenda
            </p>
            <p className="truncate text-[11px] font-medium text-navy/50">
              Suivi de vos chantiers
            </p>
          </div>
        </header>
        <main className="flex-1 px-4 pb-28 pt-4 md:px-6 md:pb-8 md:pt-6">
          {children}
        </main>

        {/* Barre mobile : 4 accès lisibles + menu Plus */}
        <nav
        aria-label="Navigation principale"
        className="fixed inset-x-0 bottom-0 z-20 flex border-t border-card-border bg-white/95 shadow-[0_-4px_18px_rgba(11,34,64,0.06)] backdrop-blur md:hidden"
      >
          {mobilePrimaryNav.map((item) => {
            const active = isActive(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-label={item.label}
                aria-current={active ? "page" : undefined}
                className={
                  "flex min-h-16 flex-1 flex-col items-center justify-center gap-1 px-1 py-2 text-[11px] font-semibold " +
                  (active ? "text-accent" : "text-navy/60")
                }
              >
                <svg viewBox="0 0 24 24" className="h-6 w-6 fill-current" aria-hidden="true">
                  {icons[item.icon]}
                </svg>
                {item.label}
              </Link>
            );
          })}
          <button
            type="button"
            aria-label="Ouvrir les autres espaces"
            onClick={() => setMoreOpen((open) => !open)}
            aria-expanded={moreOpen}
            className="flex min-h-16 flex-1 flex-col items-center justify-center gap-1 px-1 py-2 text-[11px] font-semibold text-navy/60"
          >
            <span className="text-lg leading-none">⋯</span>
            Plus
          </button>
        </nav>
        {moreOpen ? (
          <div className="fixed inset-x-3 bottom-20 z-30 rounded-2xl border border-card-border bg-white p-3 shadow-soft md:hidden">
            <div className="mb-2 flex items-center justify-between px-1">
              <p className="text-sm font-extrabold text-navy">Autres espaces</p>
              <button type="button" onClick={() => setMoreOpen(false)} className="rounded-lg px-2 py-1 text-xs font-bold text-navy/50 hover:bg-surface-low">Fermer</button>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {secondaryNav.map((item) => (
                <Link key={item.href} href={item.href} onClick={() => setMoreOpen(false)} className="flex min-h-16 flex-col items-center justify-center gap-1 rounded-xl bg-surface-low px-2 text-center text-[11px] font-bold text-navy/75">
                  <svg viewBox="0 0 24 24" className="h-5 w-5 fill-accent" aria-hidden="true">{icons[item.icon]}</svg>
                  {item.label}
                </Link>
              ))}
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}