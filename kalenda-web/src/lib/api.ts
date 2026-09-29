/**
 * Client HTTP de l'API Alliya Kalenda (kalenda-backend).
 *
 * La cible vient de `NEXT_PUBLIC_API_URL` : basculer de `localhost` en dev vers
 * le domaine heberge en production ne demande donc aucune modification de code.
 *
 * Les tokens JWT (access + refresh) vivent dans `localStorage` et sont renvoyes
 * automatiquement en `Authorization: Bearer`. Un 401 declenche une tentative de
 * rafraichissement puis un rejeu de la requete d'origine.
 */

export const API_URL = (
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000"
).replace(/\/+$/, "");

const ACCESS_KEY = "kalenda.accessToken";
const REFRESH_KEY = "kalenda.refreshToken";

export class ApiError extends Error {
  readonly status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

/** Vrai quand un Client ID Google est injecte a la compilation. */
export const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";

/** Vrai quand une API cible a ete injectee via NEXT_PUBLIC_API_URL. */
export function isApiConfigured(): boolean {
  return Boolean(process.env.NEXT_PUBLIC_API_URL);
}

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(REFRESH_KEY);
}

export function setTokens(accessToken: string, refreshToken: string): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(ACCESS_KEY, accessToken);
  window.localStorage.setItem(REFRESH_KEY, refreshToken);
}

export function clearTokens(): void {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem(ACCESS_KEY);
  window.localStorage.removeItem(REFRESH_KEY);
}

export function isSignedIn(): boolean {
  return Boolean(getAccessToken());
}

type Body = Record<string, unknown> | FormData | undefined;

/**
 * Le backend repond `{ error: { message, details } }` (voir
 * `src/middleware/error-handler.ts`). On tolere aussi les formes plates pour
 * rester robuste face a d'autres sources d'erreur (proxy, passerelle).
 */
async function parseError(response: Response): Promise<string> {
  const fallback = `Erreur ${response.status}`;
  try {
    const data = (await response.json()) as {
      message?: unknown;
      error?: unknown;
    };
    const nested =
      data.error && typeof data.error === "object"
        ? (data.error as { message?: unknown })
        : null;
    const candidates = [nested?.message, data.message, data.error];
    const found = candidates.find(
      (value): value is string => typeof value === "string" && value.length > 0,
    );
    return found ?? fallback;
  } catch {
    return fallback;
  }
}

/** Un seul refresh a la fois, partage par toutes les requetes en vol. */
let refreshing: Promise<boolean> | null = null;

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;

  if (!refreshing) {
    refreshing = (async () => {
      try {
        const response = await fetch(`${API_URL}/api/v1/auth/refresh`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken }),
        });
        if (!response.ok) return false;
        const data = (await response.json()) as AuthSession;
        setTokens(data.accessToken, data.refreshToken);
        return true;
      } catch {
        return false;
      } finally {
        setTimeout(() => {
          refreshing = null;
        }, 0);
      }
    })();
  }
  return refreshing;
}

export interface RequestOptions {
  method?: "GET" | "POST" | "PATCH" | "PUT" | "DELETE";
  body?: Body;
  /** evite une boucle infinie si /auth/refresh echoue lui-meme */
  retry?: boolean;
  auth?: boolean;
}

export async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { method = "GET", body, retry = true, auth = true } = options;

  const headers: Record<string, string> = {};
  if (!(body instanceof FormData)) headers["Content-Type"] = "application/json";

  const token = auth ? getAccessToken() : null;
  if (token) headers.Authorization = `Bearer ${token}`;

  const response = await fetch(`${API_URL}${path}`, {
    method,
    headers,
    body:
      body instanceof FormData
        ? body
        : body === undefined
          ? undefined
          : JSON.stringify(body),
    cache: "no-store",
  });

  if (response.status === 204) return undefined as T;

  if (response.status === 401 && auth && retry) {
    const renewed = await refreshAccessToken();
    if (renewed) return request<T>(path, { ...options, retry: false });
    clearTokens();
  }

  if (!response.ok) {
    throw new ApiError(response.status, await parseError(response));
  }

  return (await response.json()) as T;
}

/* ------------------------------------------------------------------ */
/* Contrats â€” alignes sur prisma/schema.prisma et les routes           */
/* ------------------------------------------------------------------ */

export interface AuthUser {
  id: string;
  email: string;
}

export interface AuthSession {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
}

export type ApiProjectStatus =
  | "planned"
  | "active"
  | "paused"
  | "completed"
  | "cancelled";

/** Les `Decimal` Prisma sont serialises en chaine JSON. */
export type Decimalish = number | string;

export interface ApiProject {
  id: string;
  name: string;
  reference: string;
  clientName: string;
  clientPhone: string;
  location: string;
  description: string;
  startDate: string | null;
  plannedEndDate: string | null;
  actualEndDate: string | null;
  contractAmount: Decimalish;
  status: ApiProjectStatus;
  progress: Decimalish;
  notes: string;
  createdAt: string;
  updatedAt: string;
}

export interface ApiActivity {
  id: string;
  title: string;
  projectId: string | null;
  description: string;
  status: "todo" | "in_progress" | "completed";
  priority: "low" | "normal" | "high" | "urgent";
  activityDate: string | null;
  notes: string;
  project?: { id: string; name: string } | null;
}

export interface ApiPerson {
  id: string;
  fullName: string;
  lastName: string;
  firstName: string;
  /** Date de naissance, absente tant que l'utilisateur ne l'a pas saisie. */
  birthDate: string | null;
  jobTitle: string;
  address: string;
  notes: string;
}

export interface ApiPayment {
  id: string;
  projectId: string;
  amount: Decimalish;
  paymentDate: string;
  method: string;
  notes: string;
  project?: { id: string; name: string } | null;
}

export interface ApiExpense {
  id: string;
  projectId: string;
  label: string;
  category: string;
  amount: Decimalish;
  expenseDate: string;
  notes: string;
  project?: { id: string; name: string } | null;
}

export interface ApiAttachment {
  id: string;
  path: string;
  filename: string;
  mimeType: string;
}

export interface ApiMessage {
  id: string;
  conversationId: string;
  projectId: string | null;
  body: string;
  sentAt: string;
  mine: boolean;
  attachments: ApiAttachment[];
}

export interface ApiConversation {
  id: string;
  title: string;
  recipientLabel: string;
  project: { id: string; name: string; reference: string } | null;
  projectId: string | null;
  createdAt: string;
  updatedAt: string;
  messageCount: number;
  unread: number;
  lastMessage: { id: string; body: string; sentAt: string; mine: boolean } | null;
}

export interface ApiReport {
  id: string;
  projectId: string;
  title: string;
  body: string;
  reportDate: string;
  project?: { id: string; name: string; reference: string } | null;
}

export interface FinanceSummary {
  received: number;
  spent: number;
  balance: number;
  paymentsCount: number;
  expensesCount: number;
}

export interface DashboardSummary {
  stats: {
    activeProjects: number;
    totalProjects: number;
    receivedMonth: number;
    expensesMonth: number;
    balanceMonth: number;
    activitiesToday: number;
    unreadMessages: number;
  };
  hero: ApiProject | null;
  activeProjects: ApiProject[];
  activitiesToday: ApiActivity[];
  dueSoon: ApiProject[];
  recentPayments: ApiPayment[];
  conversations: ApiConversation[];
}

export interface ApiProfile {
  id: string;
  email: string;
  createdAt: string;
  profile: {
    fullName: string;
    lastName: string;
    firstName: string;
    /** Date de naissance, absente tant que l'utilisateur ne l'a pas saisie. */
    birthDate: string | null;
    module: string;
    jobTitle: string;
    certifications: string;
    companyName: string;
    phone: string;
    currency: string;
    dateFormat: string;
    darkMode: boolean;
  } | null;
}

/** Forme renvoyee par GET /api/v1/modules ; cf. le modele Prisma. */
export type ApiModule = {
  id: string;
  label: string;
  status: string;
  promise: string;
  cover: string;
  highlights: string[];
  fields: {
    key: string;
    label: string;
    type: string;
    options?: string[];
    optional?: boolean;
  }[];
};

/**
 * Specialisation collectee pendant le parcours d'inscription.
 *
 * `email` et `phone` sont l'un ou l'autre : le backend refuse un compte qui
 * n'aurait aucun moyen de contact.
 */
export type RegisterInput = {
  email?: string;
  phone?: string;
  password: string;
  /** Nom de famille, puis prenom : l'ordre suit l'usage local. */
  lastName: string;
  firstName: string;
  /** Date de naissance au format AAAA-MM-JJ. Facultative. */
  birthDate?: string;
  module: string;
  jobTitle: string;
  companyName: string;
  certifications: string;
};

/** Donnees renvoyees quand Google ne reconnait pas encore le compte. */
export type GoogleSignupRequired = {
  /** Adresse Google, pre-remplie dans le parcours. */
  email: string;
  name: string;
  /** Un compte de meme e-mail existe : il sera relie, pas duplique. */
  requiresLink: boolean;
  message: string;
};


/* ------------------------------------------------------------------ */
/* Endpoints â€” uniquement ce que le backend expose reellement         */
/* ------------------------------------------------------------------ */

export const api = {
  health: () => request<{ status: string }>("/api/v1/health", { auth: false }),

  modules: {
    /**
     * Catalogue des modules d'activite. Public : l'ecran de connexion en a
     * besoin avant l'ouverture d'une session.
     */
    list: () =>
      request<ApiModule[]>("/api/v1/modules", { auth: false }),
  },

  auth: {
    /** Connexion par e-mail OU par numero de telephone. */
    login: (identifier: string, password: string) =>
      request<AuthSession>("/api/v1/auth/login", {
        method: "POST",
        body: { identifier, password },
        auth: false,
      }),
    register: (input: RegisterInput) =>
      request<AuthSession>("/api/v1/auth/register", {
        method: "POST",
        body: input,
        auth: false,
      }),
    /**
     * Verifie une identite Google.
     *
     * Deux issues possibles, et c'est pourquoi l'appel n'est pas un simple
     * `request` : le backend repond 409 quand il ne connait pas encore ce
     * compte. L'echec n'est donc pas une erreur, c'est le debut du parcours
     * d'inscription, et il faut pouvoir lire les donnees pour le preparer.
     */
    google: async (
      credential: string,
    ): Promise<
      | { status: "linked"; session: AuthSession }
      | { status: "signup-required"; signup: GoogleSignupRequired }
    > => {
      const response = await fetch(`${API_URL}/api/v1/auth/google`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ credential }),
      });

      if (response.ok) {
        return { status: "linked", session: (await response.json()) as AuthSession };
      }

      if (response.status === 409) {
        const data = (await response.json()) as {
          error?: Partial<GoogleSignupRequired> & { code?: string };
        };
        if (data.error?.code === "GOOGLE_ACCOUNT_REQUIRED") {
          return {
            status: "signup-required",
            signup: {
              email: data.error.email ?? "",
              name: data.error.name ?? "",
              requiresLink: Boolean(data.error.requiresLink),
              message: data.error.message ?? "ComplÃ©tez votre inscription.",
            },
          };
        }
      }

      throw new ApiError(response.status, await parseError(response));
    },
    /** Acheve l'inscription d'une identite Google et ouvre la session. */
    googleRegister: (
      credential: string,
      input: Omit<RegisterInput, "lastName" | "firstName" | "email">,
    ) =>
      request<AuthSession>("/api/v1/auth/google/register", {
        method: "POST",
        body: { credential, ...input },
        auth: false,
      }),
    me: () => request<ApiProfile>("/api/v1/auth/me"),
  },

  dashboard: {
    summary: () => request<DashboardSummary>("/api/v1/dashboard/summary"),
  },

  projects: {
    list: (status?: ApiProjectStatus) =>
      request<ApiProject[]>(
        status ? `/api/v1/projects?status=${status}` : "/api/v1/projects",
      ),
    get: (id: string) =>
      request<ApiProject & { phases: unknown[] }>(`/api/v1/projects/${id}`),
    create: (data: Partial<ApiProject> & { plannedEndDate?: string }) =>
      request<ApiProject>("/api/v1/projects", { method: "POST", body: data }),
    update: (
      id: string,
      data: Partial<ApiProject> & { plannedEndDate?: string },
    ) =>
      request<ApiProject>(`/api/v1/projects/${id}`, {
        method: "PATCH",
        body: data,
      }),
    remove: (id: string) =>
      request<void>(`/api/v1/projects/${id}`, { method: "DELETE" }),
  },

  activities: {
    // Le backend filtre sur une date exacte (YYYY-MM-DD), pas sur une plage.
    list: (date?: string) =>
      request<ApiActivity[]>(
        date ? `/api/v1/activities?date=${date}` : "/api/v1/activities",
      ),
    create: (data: Partial<ApiActivity> & { activityDate?: string }) =>
      request<ApiActivity>("/api/v1/activities", {
        method: "POST",
        body: data,
      }),
  },

  people: {
    list: () => request<ApiPerson[]>("/api/v1/people"),
    create: (data: Partial<ApiPerson>) =>
      request<ApiPerson>("/api/v1/people", { method: "POST", body: data }),
  },

  finances: {
    summary: (projectId?: string) =>
      request<FinanceSummary>(
        projectId
          ? `/api/v1/finances/summary?projectId=${projectId}`
          : "/api/v1/finances/summary",
      ),
    payments: (projectId?: string) =>
      request<ApiPayment[]>(
        projectId
          ? `/api/v1/finances/payments?projectId=${projectId}`
          : "/api/v1/finances/payments",
      ),
    expenses: (projectId?: string) =>
      request<ApiExpense[]>(
        projectId
          ? `/api/v1/finances/expenses?projectId=${projectId}`
          : "/api/v1/finances/expenses",
      ),
    createPayment: (data: {
      projectId: string;
      amount: number;
      paymentDate: string;
      method?: string;
      notes?: string;
    }) =>
      request<ApiPayment>("/api/v1/finances/payments", {
        method: "POST",
        body: data,
      }),
    createExpense: (data: {
      projectId: string;
      label: string;
      amount: number;
      expenseDate: string;
      category?: string;
      notes?: string;
    }) =>
      request<ApiExpense>("/api/v1/finances/expenses", {
        method: "POST",
        body: data,
      }),
  },

  reports: {
    list: () => request<ApiReport[]>("/api/v1/reports"),
    create: (data: {
      projectId: string;
      title: string;
      body?: string;
      reportDate: string;
    }) =>
      request<ApiReport>("/api/v1/reports", { method: "POST", body: data }),
  },

  conversations: {
    list: () => request<ApiConversation[]>("/api/v1/conversations"),
    get: (id: string) => request<ApiConversation>(`/api/v1/conversations/${id}`),
    create: (data: {
      title: string;
      projectId?: string;
      recipientLabel?: string;
    }) =>
      request<ApiConversation>("/api/v1/conversations", {
        method: "POST",
        body: data,
      }),
    remove: (id: string) =>
      request<void>(`/api/v1/conversations/${id}`, { method: "DELETE" }),
    messages: (id: string, limit = 100) =>
      request<ApiMessage[]>(`/api/v1/conversations/${id}/messages?limit=${limit}`),
    sendMessage: (id: string, body: string, projectId?: string) =>
      request<ApiMessage>(`/api/v1/conversations/${id}/messages`, {
        method: "POST",
        body: { body, projectId },
      }),
  },
};

