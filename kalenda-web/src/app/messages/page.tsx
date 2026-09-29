"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useKalenda } from "@/context/kalenda-context";
import { clockLabel } from "@/lib/format";

export default function MessagesPage() {
  const { conversations, messages, sendMessage, openConversation, status } =
    useKalenda();

  const [activeId, setActiveId] = useState(conversations[0]?.id ?? "");
  const [conversationOpen, setConversationOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [draft, setDraft] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);

  const active =
    conversations.find((conversation) => conversation.id === activeId) ??
    conversations[0];

  // Le fil complet est charge a l'ouverture quand l'API est joignable.
  useEffect(() => {
    if (activeId) void openConversation(activeId);
    // Volontairement limite a l'ouverture : le store est mis a jour en place.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeId]);

  const visibleConversations = useMemo(() => {
    const needle = search.trim().toLowerCase();
    const filtered = needle
      ? conversations.filter(
          (conversation) =>
            conversation.title.toLowerCase().includes(needle) ||
            conversation.projectName.toLowerCase().includes(needle),
        )
      : conversations;
    // Non-lus d'abord, comme sur mobile.
    return [...filtered].sort((a, b) => b.unread - a.unread);
  }, [conversations, search]);

  const conversationMessages = useMemo(
    () =>
      messages
        .filter((message) => message.conversationId === activeId)
        .sort((a, b) => a.sentAt.localeCompare(b.sentAt)),
    [activeId, messages],
  );

  // Auto-scroll en bas à chaque changement de conversation / nouveau message.
  useEffect(() => {
    const node = scrollRef.current;
    if (node) node.scrollTop = node.scrollHeight;
  }, [activeId, conversationMessages.length]);

  const send = () => {
    const body = draft.trim();
    if (!body || !active) return;
    setDraft("");

    // Le message part sur l'API ; le store remplace l'entree provisoire par la
    // ligne serveur des la reponse.
    sendMessage({
      conversationId: active.id,
      projectName: active.projectName,
      body,
    });
  };

  if (!active) {
    return (
      <div className="mx-auto max-w-6xl rounded-2xl border border-card-border bg-white p-6 text-center text-sm text-navy/60">
        {status === "loading" ? "Chargement des discussions…" : "Aucune discussion."}
      </div>
    );
  }

  return (
    <div className="mx-auto flex h-[calc(100dvh-6.5rem)] max-w-6xl flex-col overflow-hidden rounded-2xl border border-card-border bg-white lg:h-[calc(100dvh-4rem)]">
      <div className="grid h-full grid-cols-1 lg:grid-cols-[340px_1fr]">
        <aside
          className={`flex min-h-0 flex-col border-card-border lg:border-r ${
            conversationOpen ? "hidden lg:flex" : "flex"
          }`}
        >
          <header className="border-b border-card-border px-4 py-3.5">
            <div className="flex items-center justify-between">
              <h1 className="text-lg font-extrabold text-navy">Équipe</h1>
              <span className="rounded-full bg-accent/10 px-2 py-0.5 text-xs font-bold text-accent">
                {conversations.reduce((sum, c) => sum + c.unread, 0)} non
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
              const last = messages
                .filter((message) => message.conversationId === conversation.id)
                .sort((a, b) => b.sentAt.localeCompare(a.sentAt))[0];
              const isActive = conversation.id === activeId;
              return (
                <li key={conversation.id}>
                  <button
                    type="button"
                    onClick={() => {
                      setActiveId(conversation.id);
                      setConversationOpen(true);
                    }}
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

        <section
          className={`min-h-0 flex-col ${
            conversationOpen ? "flex" : "hidden lg:flex"
          }`}
        >
          <header className="flex items-center gap-3 border-b border-card-border px-4 py-3">
            <button
              type="button"
              onClick={() => setConversationOpen(false)}
              className="-ml-1 flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-navy/65 transition-colors hover:bg-app hover:text-navy active:scale-95 lg:hidden"
              aria-label="Retour aux conversations"
            >
              <svg
                viewBox="0 0 24 24"
                className="h-5 w-5"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="m15 18-6-6 6-6" />
              </svg>
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
          </div>

          {/* COMPOSER */}
          <footer className="border-t border-card-border bg-app/60 p-3">
            <div className="flex items-end gap-2">
              <button
                type="button"
                aria-label="Joindre un fichier"
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-card-border bg-white text-navy/60 transition-all hover:border-accent hover:text-accent active:scale-95"
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
              <div className="flex min-h-11 flex-1 items-center rounded-2xl border border-card-border bg-white px-4 transition-colors focus-within:border-accent">
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
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-navy text-white transition-all hover:bg-accent active:scale-95 disabled:cursor-not-allowed disabled:bg-navy/30"
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
              Entrée pour envoyer · messages enregistrés sur le serveur
            </p>
          </footer>
        </section>
      </div>
    </div>
  );
}
