/// Données de démonstration — miroir des seeds de lib/data/local_store.dart.
/// Le dashboard reste utilisable sans identifiants Supabase ; dès que la
/// clé est fournie, `src/lib/supabase.ts` bascule sur la vraie base.

export type ProjectStatus =
  | "planned"
  | "active"
  | "paused"
  | "completed"
  | "cancelled";

export interface Project {
  id: string;
  name: string;
  reference: string;
  client: string;
  location: string;
  progress: number;
  status: ProjectStatus;
  contractAmount: number;
  plannedEnd: string; // ISO
  imageUrl: string;
}

export interface Activity {
  title: string;
  project: string;
  time: string;
  priority: "Urgente" | "Haute" | "Normale" | "Basse";
  status: "En cours" | "À faire" | "Terminée";
}

export interface Payment {
  project: string;
  amount: number;
  date: string;
  method: string;
}

export interface Conversation {
  id: string;
  title: string;
  subtitle: string;
  initials: string;
  projectName: string;
  unread: number;
}

export interface ChatMessage {
  id: string;
  conversationId: string;
  body: string;
  projectName: string;
  sentAt: string; // ISO
  isMine: boolean;
  attachmentNames: string[];
}

export interface Person {
  id: string;
  name: string;
  role: string;
  project: string;
}

const inDays = (days: number) =>
  new Date(Date.now() + days * 86_400_000).toISOString();

export const demoProjects: Project[] = [
  {
    id: "p1",
    name: "Résidence Kasaï",
    reference: "AK-2026-001",
    client: "Groupe Mwamba",
    location: "Kasaï, Kinshasa",
    progress: 68,
    status: "active",
    contractAmount: 145_000,
    plannedEnd: inDays(34),
    imageUrl: "/covers/cover-01.jpg",
  },
  {
    id: "p2",
    name: "Atelier Kalenda",
    reference: "AK-2026-002",
    client: "Kalenda SARL",
    location: "Lemba, Kinshasa",
    progress: 42,
    status: "active",
    contractAmount: 76_500,
    plannedEnd: inDays(58),
    imageUrl: "/covers/cover-02.jpg",
  },
  {
    id: "p3",
    name: "Bureaux Lumumba",
    reference: "AK-2026-003",
    client: "SCI Lumumba",
    location: "Gombe, Kinshasa",
    progress: 91,
    status: "active",
    contractAmount: 210_000,
    plannedEnd: inDays(12),
    imageUrl: "/covers/cover-03.jpg",
  },
  {
    id: "p4",
    name: "Extension école Matonge",
    reference: "AK-2026-004",
    client: "Fondation Matonge",
    location: "Matonge, Kinshasa",
    progress: 12,
    status: "planned",
    contractAmount: 28_000,
    plannedEnd: inDays(92),
    imageUrl: "/covers/cover-04.jpg",
  },
];

export const demoActivities: Activity[] = [
  {
    title: "Contrôle ferraillage fondations",
    project: "Résidence Kasaï",
    time: "08:00",
    priority: "Urgente",
    status: "En cours",
  },
  {
    title: "Réception du ciment",
    project: "Atelier Kalenda",
    time: "10:30",
    priority: "Haute",
    status: "À faire",
  },
  {
    title: "Point équipe chantier",
    project: "Résidence Kasaï",
    time: "16:00",
    priority: "Normale",
    status: "À faire",
  },
];

export const demoPayments: Payment[] = [
  { project: "Résidence Kasaï", amount: 18_500, date: "12 sept.", method: "Virement" },
  { project: "Atelier Kalenda", amount: 7_200, date: "09 sept.", method: "Espèces" },
  { project: "Bureaux Lumumba", amount: 12_000, date: "02 sept.", method: "Virement" },
];

export const demoConversations: Conversation[] = [
  {
    id: "team-kasai",
    title: "Équipe Résidence Kasaï",
    subtitle: "Chef de chantier · 4 membres",
    initials: "RK",
    projectName: "Résidence Kasaï",
    unread: 2,
  },
  {
    id: "atelier",
    title: "Atelier Kalenda",
    subtitle: "Aline, Patrick et 2 autres",
    initials: "AK",
    projectName: "Atelier Kalenda",
    unread: 0,
  },
  {
    id: "direction",
    title: "Direction travaux",
    subtitle: "Groupe interne · 6 membres",
    initials: "DT",
    projectName: "Tous les projets",
    unread: 1,
  },
];

export const demoMessages: ChatMessage[] = [
  {
    id: "m1",
    conversationId: "team-kasai",
    body: "Le ferraillage des fondations est terminé sur la zone B. Je vous envoie les photos du contrôle.",
    projectName: "Résidence Kasaï",
    sentAt: new Date(Date.now() - 18 * 60_000).toISOString(),
    isMine: false,
    attachmentNames: ["controle-zone-b.jpg", "ferraillage-b.jpg"],
  },
  {
    id: "m2",
    conversationId: "team-kasai",
    body: "Bien reçu. On garde le coulage à 16 h si la météo reste stable.",
    projectName: "Résidence Kasaï",
    sentAt: new Date(Date.now() - 11 * 60_000).toISOString(),
    isMine: true,
    attachmentNames: [],
  },
  {
    id: "m3",
    conversationId: "direction",
    body: "Le brief quotidien est prêt : trois activités terminées, une livraison reçue et aucun blocage critique.",
    projectName: "Tous les projets",
    sentAt: new Date(Date.now() - 2 * 3_600_000).toISOString(),
    isMine: false,
    attachmentNames: [],
  },
];

export const demoPeople: Person[] = [
  { id: "h1", name: "Jean Kalala", role: "Chef de chantier", project: "Résidence Kasaï" },
  { id: "h2", name: "Mado Tshibanda", role: "Génie civil", project: "Atelier Kalenda" },
  { id: "h3", name: "Patrick Ilunga", role: "Conducteur de travaux", project: "Bureaux Lumumba" },
  { id: "h4", name: "Aline Mbala", role: "Architecte", project: "Extension école Matonge" },
];

export const demoTotalExpenses = 12_450;

export const projectStatusLabels: Record<ProjectStatus, string> = {
  planned: "Planifié",
  active: "En cours",
  paused: "En pause",
  completed: "Terminé",
  cancelled: "Annulé",
};