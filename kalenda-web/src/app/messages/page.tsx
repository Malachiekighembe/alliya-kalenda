"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import {
  demoConversations,
  demoMessages,
  type ChatMessage,
} from "@/lib/demo-data";
import { clockLabel } from "@/lib/format";

export default function MessagesPage() {
  const [activeId, setActiveId] = useState(demoConversations[0].id);
  const [search, setSearch] = useState("");
  const [draft, setDraft] = useState("");
  const [extra, setExtra] = useState<ChatMessage[]>([]);
  const [typing, setTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const active =
    demoConversations.find((conversation) => conversation.id === activeId) ??
    demoConversations[0];

  const visibleConversations = useMemo(() => {
    const needle = search.trim().toLowerCase();
    const filtered = needle
      ? demoConversations.filter(
          (conversation) =>
            conversation.title.toLowerCase().includes(needle) ||
            conversation.projectName.toLowerCase().includes(needle),
        )
      : demoConversations;
    // Non-lus d'abord, comme sur mobile.
    return [...filtered].sort((a, b) => b.unread - a.unread);
  }, [search]);

  const conversationMessages = useMemo(
    () =>
      [...demoMessages, ...extra]
        .filter((message) => message.conversationId === activeId)
        .sort((a, b) => a.sentAt.localeCompare(b.sentAt)),
    [activeId, extra],
  );

  // Auto-scroll en bas à chaque changement de conversation / nouveau message.
  useEffect(() => {
    const node = scrollRef.current;
    if (node) node.scrollTop = node.scrollHeight;
  }, [activeId, conversationMessages.length, typing]);

  const send = () => {
    const body = draft.trim();
    if (!body) return;
    setDraft("");
    const message: ChatMessage = {
      id: `local-${Date.now()}`,
      conversationId: activeId,
      body,
      projectName: active.projectName,
      sentAt: new Date().toISOString(),
      isMine: true,
      attachmentNames: [],
    };
    setExtra((current) => [...current, message]);
    // Réponse simulée : l'interlocuteur écrit puis répond.
    setTyping(true);
    window.setTimeout(() => {
      setTyping(false);
      setExtra((current) => [
        ...current,
        {
          id: `echo-${Date.now()}`,
          conversationId: activeId,
          body: "Bien noté, je m’en occupe et je reviens vers vous rapidement.",
          projectName: active.projectName,
          sentAt: new Date().toISOString(),
          isMine: false,
          attachmentNames: [],
        },
      ]);
    }, 1600);
  };

  return (
    <div className="mx-auto flex h-[calc(100dvh-6.5rem)] max-w-6xl flex-col overflow-hidden rounded-2xl border border-card-border bg-white lg:h-[calc(100dvh-4rem)]">
      <div className="grid h-full grid-cols-1 lg:grid-cols-[340px_1fr]">
        <aside
          className={`flex min-h-0 flex-col border-card-border lg:border-r ${
            activeId ? "hidden lg:flex" : "flex"
          }`}
        >
          <header className="border-b border-card-border px-4 py-3.5">
            <div className="flex items-center justify-between">
              <h1 className="text-lg font-extrabold text-navy">Équipe</h1>
              <span className="rounded-full bg-accent/10 px-2 py-0.5 text-xs font-bold text-accent">
                {demoConversations.reduce((sum, c) => sum + c.unread, 0)} non
                lus
              </span>
            </div>
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Rechercher une conversation…"
              className="mt-3 w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none transition-colors placeholder:text-navy/40 focus:border-accent"
            />
          </header>

          <ul className="min-h-0 flex-1 divide-y divide-card-border overflow-y-auto">
            {visibleConversations.map((conversation) => {
              const last = [...demoMessages, ...extra]
                .filter((message) => message.conversationId === conversation.id)
                .sort((a, b) => b.sentAt.localeCompare(a.sentAt))[0];
              const isActive = conversation.id === activeId;
              return (
                <li key={conversation.id}>
                  <button
                    type="button"
                    onClick={() => setActiveId(conversation.id)}
                    className={`flex w-full items-center gap-3 px-4 py-3 text-left transition-colors ${
                      isActive ? "bg-accent/5" : "hover:bg-app"
                    }`}
                  >
                    <span className="relative flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-navy text-sm font-bold text-white">
                      {conversation.initials}
                      <span className="pulse-dot absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-white bg-green-500" />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="flex items-baseline justify-between gap-2">
                        <span className="truncate text-sm font-bold text-navy">
                          {conversation.title}
                        </span>
                        {last ? (
                          <span className="shrink-0 text-[11px] text-navy/45">
                            {clockLabel(new Date(last.sentAt))}
                          </span>
                        ) : null}
                      </span>
                      <span className="mt-0.5 flex items-center justify-between gap-2">
                        <span className="truncate text-xs text-navy/55">
                          {last
                            ? `${last.isMine ? "Vous : " : ""}${last.body}`
                            : conversation.subtitle}
                        </span>
                        {conversation.unread > 0 ? (
                          <span className="flex h-4.5 min-w-4.5 shrink-0 items-center justify-center rounded-full bg-amber px-1.5 text-[10px] font-bold text-white">
                            {conversation.unread}
                          </span>
                        ) : null}
                      </span>
                    </span>
                  </button>
                </li>
              );
            })}
            {visibleConversations.length === 0 ? (
              <li className="px-4 py-8 text-center text-sm text-navy/50">
                Aucune conversation pour « {search} ».
              </li>
            ) : null}
          </ul>
        </aside>

        <section className="flex min-h-0 flex-col">
          <header className="flex items-center gap-3 border-b border-card-border px-4 py-3">
            <button
              type="button"
              onClick={() => setActiveId("")}
              className="rounded-lg p-1.5 text-navy/60 transition-colors hover:bg-app hover:text-navy lg:hidden"
              aria-label="Retour aux conversations"
            >
              ←
            </button>
            <span className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-navy text-sm font-bold text-white">
              {active.initials}
              <span className="pulse-dot absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-white bg-green-500" />
            </span>
            <div className="min-w-0">
              <p className="truncate text-sm font-extrabold text-navy">
                {active.title}
              </p>
              <p className="truncate text-xs text-navy/55">
                {active.subtitle} · {active.projectName}
              </p>
            </div>
            <span className="ml-auto hidden items-center gap-1.5 rounded-full bg-green-50 px-2.5 py-1 text-xs font-bold text-green-700 sm:flex">
              <span className="h-1.5 w-1.5 rounded-full bg-green-500" />
              En ligne
            </span>
          </header>

          <div
            ref={scrollRef}
            className="min-h-0 flex-1 space-y-3 overflow-y-auto bg-app/60 px-4 py-4"
          >
            {conversationMessages.map((message, index) => {
              const previous = conversationMessages[index - 1];
              const showDate =
                !previous ||
                new Date(previous.sentAt).toDateString() !==
                  new Date(message.sentAt).toDateString();
              return (
                <div key={message.id} className="bubble-in">
                  {showDate ? (
                    <div className="my-3 flex items-center gap-3">
                      <span className="h-px flex-1 bg-card-border" />
                      <span className="text-[11px] font-bold uppercase tracking-wide text-navy/40">
                        {new Intl.DateTimeFormat("fr-FR", {
                          weekday: "long",
                          day: "numeric",
                          month: "long",
                        }).format(new Date(message.sentAt))}
                      </span>
                      <span className="h-px flex-1 bg-card-border" />
                    </div>
                  ) : null}
                  <div
                    className={`flex ${
                      message.isMine ? "justify-end" : "justify-start"
                    }`}
                  >
                    <div
                      className={`max-w-[78%] rounded-2xl px-3.5 py-2.5 text-sm shadow-sm ${
                        message.isMine
                          ? "rounded-br-md bg-navy text-white"
                          : "rounded-bl-md border border-card-border bg-white text-navy"
                      }`}
                    >
                      {message.attachmentNames.length > 0 ? (
                        <div className="mb-1.5 flex flex-wrap gap-1.5">
                          {message.attachmentNames.map((name) => (
                            <span
                              key={name}
                              className={`flex items-center gap-1 rounded-lg px-2 py-1 text-[11px] font-semibold ${
                                message.isMine
                                  ? "bg-white/15 text-white/90"
                                  : "bg-app text-navy/70"
                              }`}
                            >
                              📎 {name}
                            </span>
                          ))}
                        </div>
                      ) : null}
                      <p className="whitespace-pre-wrap break-words leading-relaxed">
                        {message.body}
                      </p>
                      <p
                        className={`mt-1 text-right text-[10px] ${
                          message.isMine ? "text-white/55" : "text-navy/40"
                        }`}
                      >
                        {clockLabel(new Date(message.sentAt))}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
            {typing ? (
              <div className="bubble-in flex justify-start">
                <div className="flex items-center gap-1 rounded-2xl rounded-bl-md border border-card-border bg-white px-3.5 py-3 shadow-sm">
                  <span className="typing-dot h-1.5 w-1.5 rounded-full bg-navy/60" />
                  <span
                    className="typing-dot h-1.5 w-1.5 rounded-full bg-navy/60"
                    style={{ animationDelay: "150ms" }}
                  />
                  <span
                    className="typing-dot h-1.5 w-1.5 rounded-full bg-navy/60"
                    style={{ animationDelay: "300ms" }}
                  />
                </div>
              </div>
            ) : null}
          </div>

          {/* COMPOSER */}
          <footer className="border-t border-card-border bg-app/60 p-3">
            <div className="flex items-end gap-2">
              <button
                type="button"
                aria-label="Joindre un fichier"
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-card-border bg-white text-navy/60 transition-all hover:border-accent hover:text-accent active:scale-95"
              >
                <svg
                  viewBox="0 0 24 24"
                  className="h-4.5 w-4.5"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48" />
                </svg>
              </button>
              <div className="flex min-h-10 flex-1 items-center rounded-2xl border border-card-border bg-white px-4 transition-colors focus-within:border-accent">
                <input
                  value={draft}
                  onChange={(event) => setDraft(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter" && !event.shiftKey) {
                      event.preventDefault();
                      send();
                    }
                  }}
                  placeholder={`Écrire à ${active.title}…`}
                  aria-label="Message"
                  className="w-full bg-transparent py-2 text-sm text-navy outline-none placeholder:text-navy/40"
                />
              </div>
              <button
                type="button"
                onClick={send}
                disabled={!draft.trim()}
                aria-label="Envoyer"
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-navy text-white transition-all hover:bg-accent active:scale-95 disabled:cursor-not-allowed disabled:bg-navy/30"
              >
                <svg
                  viewBox="0 0 24 24"
                  className="h-4.5 w-4.5"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="m22 2-7 20-4-9-9-4Z" />
                  <path d="M22 2 11 13" />
                </svg>
              </button>
            </div>
            <p className="mt-1.5 pl-12 text-[10px] text-navy/40">
              Entrée pour envoyer · démo locale (aucun serveur)
            </p>
          </footer>
        </section>
      </div>
    </div>
  );
}