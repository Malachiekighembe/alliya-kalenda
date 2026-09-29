/**
 * Traduction des payloads de l'API vers les types d'interface (`src/lib/types.ts`).
 *
 * Les deux modeles ne coincident pas : Prisma stocke `clientName`,
 * `plannedEndDate`, des `Decimal` serialises en chaine et des enums anglais
 * (`in_progress`, `urgent`) ; l'UI attend des libelles francais et des dates
 * ISO. Toute la conversion est centralisee ici.
 */
import type {
  ApiActivity,
  ApiConversation,
  ApiMessage,
  ApiPayment,
  ApiPerson,
  ApiProject,
  ApiReport,
} from "@/lib/api";
import type {
  Activity,
  ChatMessage,
  Conversation,
  Payment,
  Person,
  Project,
  ProjectStatus,
  Report,
} from "@/lib/types";

/** Prisma renvoie les `Decimal` sous forme de chaine JSON. */
export const toNumber = (value: unknown): number => {
  const n = Number(value ?? 0);
  return Number.isFinite(n) ? n : 0;
};

const COVERS = [
  "/covers/cover-01.jpg",
  "/covers/cover-02.jpg",
  "/covers/cover-03.jpg",
  "/covers/cover-04.jpg",
];

/** La table `projects` n'a pas de colonne image : on derive une couverture. */
function coverFor(id: string): string {
  let hash = 0;
  for (let i = 0; i < id.length; i += 1) hash = (hash * 31 + id.charCodeAt(i)) | 0;
  return COVERS[Math.abs(hash) % COVERS.length];
}

const isoDate = (value: string | null | undefined): string =>
  value ? new Date(value).toISOString() : new Date().toISOString();

const clockOf = (value: string | null | undefined): string => {
  if (!value) return "--:--";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "--:--";
  return `${String(date.getHours()).padStart(2, "0")}:${String(
    date.getMinutes(),
  ).padStart(2, "0")}`;
};

const shortDate = (value: string | null | undefined): string => {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("fr-FR", { day: "2-digit", month: "short" }).format(
    date,
  );
};

const ACTIVITY_STATUS = {
  todo: "À faire",
  in_progress: "En cours",
  completed: "Terminée",
} as const;

const PRIORITY_LABEL = {
  low: "Basse",
  normal: "Normale",
  high: "Haute",
  urgent: "Urgente",
} as const;

export function mapProject(raw: ApiProject): Project {
  return {
    id: raw.id,
    name: raw.name,
    reference: raw.reference || `AK-${raw.id.slice(0, 6).toUpperCase()}`,
    client: raw.clientName || "Client non renseigné",
    location: raw.location || "Kinshasa",
    progress: toNumber(raw.progress),
    status: raw.status as ProjectStatus,
    contractAmount: toNumber(raw.contractAmount),
    plannedEnd: isoDate(raw.plannedEndDate),
    imageUrl: coverFor(raw.id),
  };
}

export function mapActivity(raw: ApiActivity): Activity {
  return {
    title: raw.title,
    project: raw.project?.name ?? "Général",
    time: clockOf(raw.activityDate),
    priority: PRIORITY_LABEL[raw.priority] ?? "Normale",
    status: ACTIVITY_STATUS[raw.status] ?? "À faire",
  };
}

export function mapPayment(
  raw: ApiPayment,
  projectsById: Map<string, string>,
): Payment {
  return {
    project: raw.project?.name ?? projectsById.get(raw.projectId) ?? "Général",
    amount: toNumber(raw.amount),
    date: shortDate(raw.paymentDate),
    method: raw.method || "—",
  };
}

/** `people` n'expose pas d'affectation projet : le tableau reste neutral. */
export function mapPerson(raw: ApiPerson): Person {
  return {
    id: raw.id,
    name: raw.fullName || "Sans nom",
    role: raw.jobTitle || "Collaborateur",
    project: "Non affecté",
  };
}

export function mapConversation(raw: ApiConversation): Conversation {
  const projectName = raw.project?.name ?? "Tous les projets";
  return {
    id: raw.id,
    title: raw.title,
    subtitle: raw.recipientLabel || projectName,
    initials: raw.title.slice(0, 2).toUpperCase(),
    projectName,
    unread: typeof raw.unread === "number" ? raw.unread : raw.unread ? 1 : 0,
  };
}

export function mapMessage(
  raw: ApiMessage,
  projectName: string,
): ChatMessage {
  return {
    id: raw.id,
    conversationId: raw.conversationId,
    body: raw.body,
    projectName,
    sentAt: raw.sentAt,
    isMine: Boolean(raw.mine),
    attachmentNames: (raw.attachments ?? []).map((file) => file.filename),
  };
}

/**
 * La table `reports` n'a pas de statut : on derive « Validé » des rapports
 * antérieurs a aujourd'hui, « Brouillon » pour ceux du jour.
 */
export function mapReport(
  raw: ApiReport,
  projectsById: Map<string, string>,
): Report {
  const date = new Date(raw.reportDate);
  const today = new Date();
  const isToday =
    !Number.isNaN(date.getTime()) &&
    date.getFullYear() === today.getFullYear() &&
    date.getMonth() === today.getMonth() &&
    date.getDate() === today.getDate();

  return {
    id: raw.id,
    date: Number.isNaN(date.getTime())
      ? new Date().toISOString()
      : date.toISOString(),
    project: raw.project?.name ?? projectsById.get(raw.projectId) ?? "Général",
    title: raw.title,
    summary: raw.body || "—",
    status: isToday ? "Brouillon" : "Validé",
  };
}
