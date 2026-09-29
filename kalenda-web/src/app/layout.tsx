import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { AppShell } from "@/components/app-shell";
import { KalendaProvider } from "@/context/kalenda-context";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  // `title.template` évite qu'un onglet affiche seulement « Connexion » :
  // le nom du produit reste visible.
  title: {
    default: "Alliya Kalenda — Outil métier",
    template: "%s · Alliya Kalenda",
  },
  applicationName: "Alliya Kalenda",
  description:
    "Alliya Kalenda — agenda, chantiers, finances et rapports pour les équipes de terrain.",
  appleWebApp: {
    title: "Alliya Kalenda",
  },
  // `/icon.png` sert de favicon : le `favicon.ico` Vercel par défaut a été
  // retiré, la convention fichier primant sur ces métadonnées.
  icons: {
    icon: "/icon.png",
    apple: "/icon.png",
    shortcut: "/icon.png",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="fr"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full">
        <KalendaProvider>
          <AppShell>{children}</AppShell>
        </KalendaProvider>
      </body>
    </html>
  );
}
