"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import {
  demoProjects,
  demoActivities,
  demoPayments,
  demoPeople,
  demoMessages,
  Project,
  Activity,
  Payment,
  Person,
  ChatMessage,
  ProjectStatus,
} from "@/lib/demo-data";

export interface KalendaContextType {
  projects: Project[];
  activities: Activity[];
  payments: Payment[];
  persons: Person[];
  messages: ChatMessage[];
  addProject: (data: {
    name: string;
    client: string;
    location: string;
    contractAmount: number;
    status: ProjectStatus;
    imageUrl: string;
    plannedEnd?: string;
  }) => Project;
  updateProject: (id: string, updates: Partial<Project>) => void;
  deleteProject: (id: string) => void;
  addActivity: (activity: Activity) => void;
  addPayment: (payment: Payment) => void;
  addPerson: (person: Omit<Person, "id">) => void;
  sendMessage: (data: {
    conversationId: string;
    projectName: string;
    body: string;
  }) => void;
}

const KalendaContext = createContext<KalendaContextType | undefined>(undefined);

const STORAGE_KEYS = {
  projects: "kalenda_projects",
  activities: "kalenda_activities",
  payments: "kalenda_payments",
  persons: "kalenda_persons",
  messages: "kalenda_messages",
};

export function KalendaProvider({ children }: { children: React.ReactNode }) {
  const [projects, setProjects] = useState<Project[]>(() => {
    if (typeof window === "undefined") return demoProjects;
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.projects);
      return stored ? JSON.parse(stored) : demoProjects;
    } catch {
      return demoProjects;
    }
  });

  const [activities, setActivities] = useState<Activity[]>(() => {
    if (typeof window === "undefined") return demoActivities;
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.activities);
      return stored ? JSON.parse(stored) : demoActivities;
    } catch {
      return demoActivities;
    }
  });

  const [payments, setPayments] = useState<Payment[]>(() => {
    if (typeof window === "undefined") return demoPayments;
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.payments);
      return stored ? JSON.parse(stored) : demoPayments;
    } catch {
      return demoPayments;
    }
  });

  const [persons, setPersons] = useState<Person[]>(() => {
    if (typeof window === "undefined") return demoPeople;
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.persons);
      return stored ? JSON.parse(stored) : demoPeople;
    } catch {
      return demoPeople;
    }
  });

  const [messages, setMessages] = useState<ChatMessage[]>(() => {
    if (typeof window === "undefined") return demoMessages;
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.messages);
      return stored ? JSON.parse(stored) : demoMessages;
    } catch {
      return demoMessages;
    }
  });

  // Sauvegarde automatique lors des modifications
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.projects, JSON.stringify(projects));
      localStorage.setItem(STORAGE_KEYS.activities, JSON.stringify(activities));
      localStorage.setItem(STORAGE_KEYS.payments, JSON.stringify(payments));
      localStorage.setItem(STORAGE_KEYS.persons, JSON.stringify(persons));
      localStorage.setItem(STORAGE_KEYS.messages, JSON.stringify(messages));
    } catch {}
  }, [projects, activities, payments, persons, messages]);

  const addProject = (data: {
    name: string;
    client: string;
    location: string;
    contractAmount: number;
    status: ProjectStatus;
    imageUrl: string;
    plannedEnd?: string;
  }): Project => {
    const id = "p_" + Date.now();
    const newProject: Project = {
      id,
      name: data.name,
      reference: `AK-${new Date().getFullYear()}-${String(projects.length + 5).padStart(3, "0")}`,
      client: data.client || "Client non renseigné",
      location: data.location || "Kinshasa",
      progress: 0,
      status: data.status,
      contractAmount: data.contractAmount,
      plannedEnd:
        data.plannedEnd ||
        new Date(Date.now() + 90 * 86_400_000).toISOString(),
      imageUrl: data.imageUrl || "/covers/cover-01.jpg",
    };
    setProjects((prev) => [newProject, ...prev]);
    return newProject;
  };

  const updateProject = (id: string, updates: Partial<Project>) => {
    setProjects((prev) =>
      prev.map((p) => (p.id === id ? { ...p, ...updates } : p)),
    );
  };

  const deleteProject = (id: string) => {
    setProjects((prev) => prev.filter((p) => p.id !== id));
  };

  const addActivity = (activity: Activity) => {
    setActivities((prev) => [activity, ...prev]);
  };

  const addPayment = (payment: Payment) => {
    setPayments((prev) => [payment, ...prev]);
  };

  const addPerson = (personData: Omit<Person, "id">) => {
    setPersons((prev) => [{ id: "u_" + Date.now(), ...personData }, ...prev]);
  };

  const sendMessage = (data: {
    conversationId: string;
    projectName: string;
    body: string;
  }) => {
    setMessages((prev) => [
      ...prev,
      {
        id: "m_" + Date.now(),
        conversationId: data.conversationId,
        projectName: data.projectName,
        body: data.body,
        sentAt: new Date().toISOString(),
        isMine: true,
        attachmentNames: [],
      },
    ]);
  };

  return (
    <KalendaContext.Provider
      value={{
        projects,
        activities,
        payments,
        persons,
        messages,
        addProject,
        updateProject,
        deleteProject,
        addActivity,
        addPayment,
        addPerson,
        sendMessage,
      }}
    >
      {children}
    </KalendaContext.Provider>
  );
}

export function useKalenda() {
  const ctx = useContext(KalendaContext);
  if (!ctx) throw new Error("useKalenda must be used within KalendaProvider");
  return ctx;
}
