"use client";

import { useState } from "react";
import { clockLabel } from "@/lib/format";
import { demoConversations, demoMessages } from "@/lib/demo-data";

export default function MessagesPage() {
  const [activeId, setActiveId] = useState(demoConversations[0].id);
  const [query, setQuery] = useState("");
  const [draft, setDraft] = useState("");

  const filtered = demoConversations.filter((conversation) =>
    conversation.title.toLowerCase().includes(query.trim().toLowerCase()),
  );
  const active =
    demoConversations.find((conversation) => conversation.id === activeId) ??
    demoConversations[0];
  const thread = demoMessages.filter(
    (message) => message.conversationId === active.id,
  );
  const [sent, setSent] = useState<string[]>([]);

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-5">
      <header>
        <h1 className="text-2xl font-extrabold text-navy">Équipe</h1>
        <p className="text-sm text-navy/60">
          Conversations par chantier avec vos équipes.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-[280px,1fr]">
        <aside className="flex flex-col gap-3 rounded-xl border border-card-border bg-white p-3">
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Rechercher…"
            className="w-full rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent"
          />
          <ul className="flex flex-col gap-1">
            {filtered.map((conversation) => (
              <li key={conversation.id}>
                <button
                  type="button"
                  onClick={() => setActiveId(conversation.id)}
                  className={
                    "flex w-full items-center gap-3 rounded-lg p-2 text-left transition-colors " +
                    (conversation.id === active.id
                      ? "bg-accent/10"
                      : "hover:bg-app")
                  }
                >
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-navy text-xs font-bold text-white">
                    {conversation.initials}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-bold text-navy">
                      {conversation.title}
                    </span>
                    <span className="block truncate text-xs text-navy/55">
                      {conversation.projectName}
                    </span>
                  </span>
                  {conversation.unread > 0 ? (
                    <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-amber px-1.5 text-[11px] font-bold text-white">
                      {conversation.unread}
                    </span>
                  ) : null}
                </button>
              </li>
            ))}
          </ul>
        </aside>

        <section className="flex min-h-[420px] flex-col rounded-xl border border-card-border bg-white">
          <header className="border-b border-card-border px-4 py-3">
            <p className="text-sm font-extrabold text-navy">{active.title}</p>
            <p className="text-xs text-navy/55">
              {active.subtitle} · {active.projectName}
            </p>
          </header>
          <div className="flex flex-1 flex-col gap-3 overflow-y-auto p-4">
            {thread.map((message) => (
              <div
                key={message.id}
                className={
                  "max-w-[80%] rounded-2xl px-3 py-2 text-sm " +
                  (message.isMine
                    ? "self-end bg-navy text-white"
                    : "self-start bg-app text-navy")
                }
              >
                <p>{message.body}</p>
                {message.attachmentNames.length > 0 ? (
                  <p className="mt-1 text-[11px] opacity-70">
                    📎 {message.attachmentNames.join(", ")}
                  </p>
                ) : null}
                <p className="mt-1 text-[10px] opacity-60">
                  {clockLabel(new Date(message.sentAt))}
                </p>
              </div>
            ))}
            {sent.map((body, index) => (
              <div
                key={`sent-${index}`}
                className="max-w-[80%] self-end rounded-2xl bg-navy px-3 py-2 text-sm text-white"
              >
                <p>{body}</p>
              </div>
            ))}
          </div>
          <form
            onSubmit={(event) => {
              event.preventDefault();
              const body = draft.trim();
              if (!body) return;
              setSent((previous) => [...previous, body]);
              setDraft("");
            }}
            className="flex gap-2 border-t border-card-border p-3"
          >
            <input
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              placeholder="Écrire un message…"
              className="flex-1 rounded-lg border border-card-border bg-app px-3 py-2 text-sm outline-none focus:border-accent"
            />
            <button
              type="submit"
              className="rounded-lg bg-navy px-4 py-2 text-sm font-bold text-white hover:bg-navy/90"
            >
              Envoyer
            </button>
          </form>
        </section>
      </div>
    </div>
  );
}