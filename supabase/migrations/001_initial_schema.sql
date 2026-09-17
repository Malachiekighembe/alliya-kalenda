-- Alliya Kalenda V1 schema. Apply with Supabase migrations when a project is configured.
create extension if not exists pgcrypto;

create type public.project_status as enum ('planned', 'active', 'paused', 'completed', 'cancelled');
create type public.activity_status as enum ('todo', 'in_progress', 'completed');
create type public.activity_priority as enum ('low', 'normal', 'high', 'urgent');

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  company_name text not null default '',
  phone text not null default '',
  currency text not null default 'USD',
  date_format text not null default 'dd/MM/yyyy',
  notifications_enabled boolean not null default true,
  dark_mode boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  reference text not null default '',
  client_name text not null default '',
  client_phone text not null default '',
  location text not null default '',
  description text not null default '',
  start_date date,
  planned_end_date date,
  actual_end_date date,
  planned_budget numeric(14,2) not null default 0,
  contract_amount numeric(14,2) not null default 0,
  status public.project_status not null default 'planned',
  progress numeric(5,2) not null default 0 check (progress >= 0 and progress <= 100),
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.people (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null,
  phone text not null default '',
  job_title text not null default '',
  address text not null default '',
  photo_path text,
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.project_people (
  project_id uuid not null references public.projects(id) on delete cascade,
  person_id uuid not null references public.people(id) on delete cascade,
  assigned_at timestamptz not null default timezone('utc', now()),
  primary key (project_id, person_id)
);

create table public.phases (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  name text not null,
  progress numeric(5,2) not null default 0 check (progress >= 0 and progress <= 100),
  position integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  phase_id uuid references public.phases(id) on delete set null,
  title text not null,
  activity_date date not null,
  starts_at timestamptz,
  ends_at timestamptz,
  description text not null default '',
  priority public.activity_priority not null default 'normal',
  status public.activity_status not null default 'todo',
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.activity_people (
  activity_id uuid not null references public.activities(id) on delete cascade,
  person_id uuid not null references public.people(id) on delete cascade,
  primary key (activity_id, person_id)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  payment_date date not null,
  amount numeric(14,2) not null check (amount >= 0),
  payment_method text not null default '',
  reference text not null default '',
  description text not null default '',
  receipt_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  category text not null,
  description text not null default '',
  amount numeric(14,2) not null check (amount >= 0),
  expense_date date not null,
  supplier text not null default '',
  receipt_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.materials (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  name text not null,
  quantity numeric(14,3) not null default 0,
  unit text not null default '',
  unit_price numeric(14,2) not null default 0,
  supplier text not null default '',
  purchase_date date,
  used_quantity numeric(14,3) not null default 0,
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  report_date date not null,
  work_completed text not null default '',
  work_planned text not null default '',
  progress numeric(5,2) not null default 0,
  people_present text[] not null default '{}',
  materials_used text not null default '',
  difficulties text not null default '',
  observations text not null default '',
  signature_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  activity_id uuid references public.activities(id) on delete cascade,
  payment_id uuid references public.payments(id) on delete cascade,
  expense_id uuid references public.expenses(id) on delete cascade,
  report_id uuid references public.reports(id) on delete cascade,
  storage_path text not null,
  file_name text not null,
  content_type text not null default 'application/octet-stream',
  captured_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.progress_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  progress numeric(5,2) not null check (progress >= 0 and progress <= 100),
  note text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create index projects_owner_status_idx on public.projects(owner_id, status);
create index activities_owner_date_idx on public.activities(owner_id, activity_date);
create index payments_project_date_idx on public.payments(project_id, payment_date desc);
create index expenses_project_date_idx on public.expenses(project_id, expense_date desc);

grant select, insert, update, delete on all tables in schema public to authenticated;

do $$
declare table_name text;
begin
  for table_name in select unnest(array['projects','people','phases','activities','payments','expenses','materials','reports','attachments','progress_events']) loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('create policy %I on public.%I for all to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()))', table_name || '_owner_policy', table_name);
  end loop;
end $$;

alter table public.profiles enable row level security;
create policy profiles_owner_policy on public.profiles for all to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

alter table public.project_people enable row level security;
create policy project_people_owner_policy on public.project_people for all to authenticated
  using (exists (select 1 from public.projects where projects.id = project_people.project_id and projects.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.projects where projects.id = project_people.project_id and projects.owner_id = (select auth.uid())));

alter table public.activity_people enable row level security;
create policy activity_people_owner_policy on public.activity_people for all to authenticated
  using (exists (select 1 from public.activities where activities.id = activity_people.activity_id and activities.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.activities where activities.id = activity_people.activity_id and activities.owner_id = (select auth.uid())));
create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger projects_updated_at before update on public.projects for each row execute procedure public.set_updated_at();
create trigger people_updated_at before update on public.people for each row execute procedure public.set_updated_at();
create trigger phases_updated_at before update on public.phases for each row execute procedure public.set_updated_at();
create trigger activities_updated_at before update on public.activities for each row execute procedure public.set_updated_at();
create trigger payments_updated_at before update on public.payments for each row execute procedure public.set_updated_at();
create trigger expenses_updated_at before update on public.expenses for each row execute procedure public.set_updated_at();
create trigger materials_updated_at before update on public.materials for each row execute procedure public.set_updated_at();
create trigger reports_updated_at before update on public.reports for each row execute procedure public.set_updated_at();
create trigger attachments_updated_at before update on public.attachments for each row execute procedure public.set_updated_at();
