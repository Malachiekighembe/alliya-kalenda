"use client";

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import {
  api,
  clearTokens,
  isApiConfigured,
  isSignedIn,
  setTokens,
  ApiError,
  type AuthUser,
  type ApiProfile,
  type FinanceSummary,
  type RegisterInput,
  type GoogleSignupRequired,
} from "@/lib/api";
import {
  mapActivity,
  mapConversation,
  mapMessage,
  mapPayment,
  mapPerson,
  mapProject,
  mapReport,
} from "@/lib/mappers";
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

/**
 * Etats possibles de l'application.
 *
 * Il n'existe plus de mode demonstration : sans session, l'application affiche
 * l'ecran de connexion, et les listes restent vides tant que l'API n'a pas
 * repondu.
 */
export type LoadStatus =
  | "unauthenticated"
  | "loading"
  | "ready"
  | "error"
  | "unconfigured";

export interface KalendaContextType {
  projects: Project[];
  activities: Activity[];
  payments: Payment[];
  persons: Person[];
  messages: ChatMessage[];
  conversations: Conversation[];
  reports: Report[];
  finances: FinanceSummary;

  status: LoadStatus;
  error: string | null;
  user: AuthUser | null;
  /** Profil complet renvoye par GET /auth/me (null hors session). */
  profile: ApiProfile | null;
  /** Vrai quand une session est ouverte et l'API est joignable. */
  isOnline: boolean;

  login: (identifier: string, password: string) => Promise<void>;
  register: (input: RegisterInput) => Promise<void>;
  /**
   * Verifie une identite Google. Si le compte est deja relie, la session est
   * ouverte. Sinon, `signup` est renseigne et l'ecran deroule le parcours
   * d'inscription avant de rappeler `completeGoogleSignup`.
   */
  loginWithGoogle: (
    credential: string,
  ) => Promise<{ linked: true } | { linked: false; signup: GoogleSignupRequired }>;
  /** Acheve l'inscription liee a Google : module, metier, mot de passe. */
  completeGoogleSignup: (
    credential: string,
    input: Omit<RegisterInput, "fullName" | "email">,
  ) => Promise<void>;
  logout: () => void;
  refresh: () => Promise<void>;

  addProject: (data: {
    name: string;
    client: string;
    location: string;
    contractAmount: number;
    status: ProjectStatus;
    imageUrl: string;
    plannedEnd?: string;
  }) => void;
  updateProject: (id: string, updates: Partial<Project>) => void;
  deleteProject: (id: string) => void;
  addActivity: (activity: Activity) => void;
  addPayment: (payment: Payment) => void;
  addPerson: (person: Omit<Person, "id">) => void;
  addReport: (report: Omit<Report, "id">) => void;
  /** Charge le fil complet d'une discussion. */
  openConversation: (id: string) => Promise<ChatMessage[]>;
  sendMessage: (data: {
    conversationId: string;
    projectName: string;
    body: string;
  }) => void;
}

const KalendaContext = createContext<KalendaContextType | undefined>(undefined);

const EMPTY_FINANCES: FinanceSummary = {
  received: 0,
  spent: 0,
  balance: 0,
  paymentsCount: 0,
  expensesCount: 0,
};

const messageOf = (error: unknown): string =>
  error instanceof Error ? error.message : "Erreur inconnue";

export function KalendaProvider({ children }: { children: React.ReactNode }) {
  // Sans session, aucune requete n'est envoyee et les listes restent vides.
  const [projects, setProjects] = useState<Project[]>([]);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [persons, setPersons] = useState<Person[]>([]);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [reports, setReports] = useState<Report[]>([]);
  const [finances, setFinances] = useState<FinanceSummary>(EMPTY_FINANCES);

  const [status, setStatus] = useState<LoadStatus>("unauthenticated");
  const [error, setError] = useState<string | null>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [profile, setProfile] = useState<ApiProfile | null>(null);

  const isOnline = isApiConfigured() && isSignedIn();

  const clearData = useCallback(() => {
    setProjects([]);
    setActivities([]);
    setPayments([]);
    setPersons([]);
    setMessages([]);
    setConversations([]);
    setReports([]);
    setFinances(EMPTY_FINANCES);
  }, []);

  const load = useCallback(async () => {
    if (!isApiConfigured()) {
      setStatus("unconfigured");
      return;
    }
    if (!isSignedIn()) {
      clearData();
      setUser(null);
      setProfile(null);
      setStatus("unauthenticated");
      return;
    }

    setStatus("loading");
    setError(null);
    try {
      const [rawProjects, rawActivities, rawPeople, rawPayments, rawFinance, rawTalks, rawReports] =
        await Promise.all([
          api.projects.list(),
          api.activities.list(),
          api.people.list(),
          api.finances.payments(),
          api.finances.summary(),
          api.conversations.list(),
          api.reports.list(),
        ]);

      const byId = new Map(rawProjects.map((item) => [item.id, item.name]));

      // Les fils complets ne sont charges qu'a l'ouverture : on seed le store
      // avec le dernier message de chaque discussion.
      const latest = rawTalks
        .filter((talk) => talk.lastMessage)
        .map((talk) =>
          mapMessage(
            {
              id: talk.lastMessage!.id,
              conversationId: talk.id,
              projectId: talk.projectId,
              body: talk.lastMessage!.body,
              sentAt: talk.lastMessage!.sentAt,
              mine: talk.lastMessage!.mine,
              attachments: [],
            },
            talk.project?.name ?? "Tous les projets",
          ),
        );

      setProjects(rawProjects.map(mapProject));
      setActivities(rawActivities.map(mapActivity));
      setPersons(rawPeople.map(mapPerson));
      setPayments(rawPayments.map((item) => mapPayment(item, byId)));
      setFinances(rawFinance);
      setConversations(rawTalks.map(mapConversation));
      setMessages(latest);
      setReports(rawReports.map((item) => mapReport(item, byId)));
      setStatus("ready");
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        clearTokens();
        clearData();
        setUser(null);
        setProfile(null);
        setStatus("unauthenticated");
        setError("Session expirée, reconnectez-vous.");
        return;
      }
      setStatus("error");
      setError(messageOf(err));
    }
  }, [clearData]);

  useEffect(() => {
    // Le premier rendu est deja « non authentifie ». Le chargement est declenche
    // via un timer : `load()` pose son etat de chargement de facon synchrone,
    // ce qui provoquerait un rendu en cascade s'il etait appele directement ici.
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  const adoptSession = async () => {
    const current = await api.auth.me();
    setProfile(current);
    setUser({ id: current.id, email: current.email });
    await load();
  };

  const login = async (email: string, password: string) => {
    setError(null);
    try {
      const session = await api.auth.login(email, password);
      setTokens(session.accessToken, session.refreshToken);
      await adoptSession();
    } catch (err) {
      setError(messageOf(err));
      throw err;
    }
  };

  const register = async (input: RegisterInput) => {
    setError(null);
    try {
      const session = await api.auth.register(input);
      setTokens(session.accessToken, session.refreshToken);
      await adoptSession();
    } catch (err) {
      setError(messageOf(err));
      throw err;
    }
  };

  const loginWithGoogle = async (credential: string) => {
    setError(null);
    try {
      const result = await api.auth.google(credential);
      if (result.status === "linked") {
        setTokens(result.session.accessToken, result.session.refreshToken);
        await adoptSession();
        return { linked: true } as const;
      }
      // Compte inconnu : aucun jeton n'est emis. L'ecran doit completer le
      // parcours avant d'obtenir une session.
      return { linked: false, signup: result.signup } as const;
    } catch (err) {
      setError(messageOf(err));
      throw err;
    }
  };

  const completeGoogleSignup = async (
    credential: string,
    input: Omit<RegisterInput, "fullName" | "email">,
  ) => {
    setError(null);
    try {
      const session = await api.auth.googleRegister(credential, input);
      setTokens(session.accessToken, session.refreshToken);
      await adoptSession();
    } catch (err) {
      setError(messageOf(err));
      throw err;
    }
  };

  const logout = () => {
    clearTokens();
    clearData();
    setUser(null);
    setProfile(null);
    setError(null);
    setStatus("unauthenticated");
  };

  /** Ramene le type d'UI vers la charge utile attendue par le backend. */
  const toApiProject = (patch: Partial<Project>): Record<string, unknown> => {
    const payload: Record<string, unknown> = {};
    if (patch.name !== undefined) payload.name = patch.name;
    if (patch.client !== undefined) payload.clientName = patch.client;
    if (patch.location !== undefined) payload.location = patch.location;
    if (patch.status !== undefined) payload.status = patch.status;
    if (patch.progress !== undefined) payload.progress = patch.progress;
    if (patch.contractAmount !== undefined)
      payload.contractAmount = patch.contractAmount;
    if (patch.plannedEnd !== undefined)
      payload.plannedEndDate = new Date(patch.plannedEnd).toISOString();
    return payload;
  };

  const addProject = (data: {
    name: string;
    client: string;
    location: string;
    contractAmount: number;
    status: ProjectStatus;
    imageUrl: string;
    plannedEnd?: string;
  }): void => {
    const plannedEnd =
      data.plannedEnd || new Date(Date.now() + 90 * 86_400_000).toISOString();

    // Mise a jour optimiste : l'ecran bouge tout de suite, puis la ligne
    // serveur (avec son vrai identifiant) remplace l'entree provisoire.
    const localId = "p_" + Date.now();
    setProjects((prev) => [
      {
        id: localId,
        name: data.name,
        reference: "—",
        client: data.client,
        location: data.location,
        progress: 0,
        status: data.status,
        contractAmount: data.contractAmount,
        plannedEnd,
        imageUrl: data.imageUrl,
      },
      ...prev,
    ]);

    void api.projects
      .create({
        name: data.name,
        clientName: data.client,
        location: data.location,
        contractAmount: data.contractAmount,
        status: data.status,
        progress: 0,
        plannedEndDate: plannedEnd,
      })
      .then((created) => {
        const mapped = mapProject(created);
        setProjects((prev) =>
          prev.map((item) => (item.id === localId ? mapped : item)),
        );
      })
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const updateProject = (id: string, updates: Partial<Project>) => {
    setProjects((prev) =>
      prev.map((item) => (item.id === id ? { ...item, ...updates } : item)),
    );
    void api.projects
      .update(id, toApiProject(updates))
      .then((updated) => {
        const mapped = mapProject(updated);
        setProjects((prev) =>
          prev.map((item) => (item.id === id ? mapped : item)),
        );
      })
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const deleteProject = (id: string) => {
    setProjects((prev) => prev.filter((item) => item.id !== id));
    void api.projects
      .remove(id)
      .then(() => load())
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const addActivity = (activity: Activity) => {
    setActivities((prev) => [activity, ...prev]);
    const project = projects.find((item) => item.name === activity.project);
    const statusMap = {
      "En cours": "in_progress",
      "À faire": "todo",
      "Terminée": "completed",
    } as const;
    const priorityMap = {
      Urgente: "urgent",
      Haute: "high",
      Normale: "normal",
      Basse: "low",
    } as const;

    void api.activities
      .create({
        title: activity.title,
        projectId: project?.id,
        status: statusMap[activity.status] ?? "todo",
        priority: priorityMap[activity.priority] ?? "normal",
      })
      .then(() => load())
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const addPayment = (payment: Payment) => {
    setPayments((prev) => [payment, ...prev]);
    const project = projects.find((item) => item.name === payment.project);
    if (!project) {
      setError("Sélectionnez un chantier pour enregistrer un encaissement.");
      return;
    }
    void api.finances
      .createPayment({
        projectId: project.id,
        amount: payment.amount,
        paymentDate: new Date().toISOString().slice(0, 10),
        method: payment.method,
      })
      .then(() => load())
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const addPerson = (personData: Omit<Person, "id">) => {
    const person: Person = { id: "u_" + Date.now(), ...personData };
    setPersons((prev) => [person, ...prev]);
    void api.people
      .create({ fullName: personData.name, jobTitle: personData.role })
      .then(() => load())
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const addReport = (data: Omit<Report, "id">) => {
    const localId = "r_" + Date.now();
    setReports((prev) => [{ id: localId, ...data }, ...prev]);

    const project = projects.find((item) => item.name === data.project);
    if (!project) {
      setError("Sélectionnez un chantier pour publier un rapport.");
      return;
    }
    void api.reports
      .create({
        projectId: project.id,
        title: data.title,
        body: data.summary,
        reportDate: data.date.slice(0, 10),
      })
      .then(() => load())
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const openConversation = async (id: string): Promise<ChatMessage[]> => {
    try {
      const raw = await api.conversations.messages(id);
      const talk = conversations.find((item) => item.id === id);
      const projectName = talk?.projectName ?? "Tous les projets";
      const mapped = raw.map((item) => mapMessage(item, projectName));
      setMessages((prev) => [
        ...prev.filter((item) => item.conversationId !== id),
        ...mapped,
      ]);
      return mapped;
    } catch (err) {
      setError(messageOf(err));
      return [];
    }
  };

  const sendMessage = (data: {
    conversationId: string;
    projectName: string;
    body: string;
  }) => {
    const localId = "m_" + Date.now();
    setMessages((prev) => [
      ...prev,
      {
        id: localId,
        conversationId: data.conversationId,
        projectName: data.projectName,
        body: data.body,
        sentAt: new Date().toISOString(),
        isMine: true,
        attachmentNames: [],
      },
    ]);

    void api.conversations
      .sendMessage(data.conversationId, data.body)
      .then((sent) => {
        const mapped = mapMessage(sent, data.projectName);
        setMessages((prev) =>
          prev.map((item) => (item.id === localId ? mapped : item)),
        );
      })
      .catch((err: unknown) => setError(messageOf(err)));
  };

  const value: KalendaContextType = {
    projects,
    activities,
    payments,
    persons,
    messages,
    conversations,
    reports,
    finances,
    status,
    error,
    user,
    profile,
    isOnline,
    login,
    register,
    loginWithGoogle,
    completeGoogleSignup,
    logout,
    refresh: load,
    addProject,
    updateProject,
    deleteProject,
    addActivity,
    addPayment,
    addPerson,
    addReport,
    openConversation,
    sendMessage,
  };

  return (
    <KalendaContext.Provider value={value}>{children}</KalendaContext.Provider>
  );
}

export function useKalenda() {
  const ctx = useContext(KalendaContext);
  if (!ctx) throw new Error("useKalenda must be used within KalendaProvider");
  return ctx;
}
