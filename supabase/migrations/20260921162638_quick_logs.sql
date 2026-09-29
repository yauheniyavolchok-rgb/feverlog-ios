-- Quick log entries: food, drink, pee, poop, vomit, breath. Same shape and
-- conflict/RLS design as `symptoms`/`notes` in the initial schema — see
-- that migration's header comment for the full design notes this reuses
-- (client-supplied `updated_at`, soft deletion, household-scoped RLS via
-- `is_child_accessible`).

create table quick_logs (
  id uuid primary key,
  child_id uuid not null references children (id) on delete cascade,
  type text not null,
  degree smallint not null,
  recorded_at timestamptz not null,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index quick_logs_child_id_idx on quick_logs (child_id);

create trigger quick_logs_bump_sync_version before update on quick_logs
  for each row execute function public.bump_sync_version();
create trigger quick_logs_reject_stale_write before update on quick_logs
  for each row execute function public.reject_stale_write();

alter table quick_logs enable row level security;

create policy quick_logs_select on quick_logs
  for select using (public.is_child_accessible(child_id));
create policy quick_logs_insert on quick_logs
  for insert with check (public.is_child_accessible(child_id));
create policy quick_logs_update on quick_logs
  for update using (public.is_child_accessible(child_id))
  with check (public.is_child_accessible(child_id));

grant select, insert, update on quick_logs to authenticated;

alter publication supabase_realtime add table quick_logs;
