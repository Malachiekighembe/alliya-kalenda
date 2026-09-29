-- Messaging and project media for the local-first sync adapter.
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  title text not null,
  recipient_label text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  body text not null default '',
  sent_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.attachments
  add column message_id uuid references public.messages(id) on delete cascade;

create index conversations_owner_updated_idx on public.conversations(owner_id, updated_at desc);
create index messages_conversation_sent_idx on public.messages(conversation_id, sent_at desc);
create index attachments_message_idx on public.attachments(message_id);

grant select, insert, update, delete on public.conversations, public.messages to authenticated;

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

create policy conversations_owner_policy on public.conversations
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy messages_owner_policy on public.messages
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

insert into storage.buckets (id, name, public)
values ('project-media', 'project-media', false)
on conflict (id) do nothing;

create policy project_media_read on storage.objects
  for select to authenticated
  using (bucket_id = 'project-media' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy project_media_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'project-media' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy project_media_update on storage.objects
  for update to authenticated
  using (bucket_id = 'project-media' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'project-media' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy project_media_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'project-media' and (storage.foldername(name))[1] = (select auth.uid())::text);

create trigger conversations_updated_at before update on public.conversations for each row execute procedure public.set_updated_at();
create trigger messages_updated_at before update on public.messages for each row execute procedure public.set_updated_at();
