
/**
 * Types d'interface de l'application.
 *
 * Ce sont les formes utilisees par les composants, volontairement distinctes
 * des charges utiles de l'API (`src/lib/api.ts`) : la conversion est centralisee
 * dans `src/lib/mappers.ts`. Les donnees proviennent exclusivement du backend.
 */

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

export interface Report {
  id: string;
  date: string; // ISO
  project: string;
  title: string;
  summary: string;
  status: "Validé" | "Brouillon";
}

export const projectStatusLabels: Record<ProjectStatus, string> = {
  planned: "Planifié",
  active: "En cours",
  paused: "En pause",
  completed: "Terminé",
  cancelled: "Annulé",
};
