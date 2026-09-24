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
  title: "Alliya Kalenda",
  description:
    "Alliya Kalenda — suivi de chantiers, agenda et finances pour ingénieurs et conducteurs de travaux.",
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
