-- FeverLog Phase 9 schema: households, membership, and health records,
-- scoped entirely by household membership via Row Level Security.
--
-- Design notes (see README.md "Supabase setup" section for the full
-- writeup):
--   * Every authenticated user (including anonymous-auth users — Supabase
--     assigns the `authenticated` Postgres role to anonymous sessions too)
--     gets exactly one personal household via `create_personal_household()`.
--     There is no "guest household with no remote counterpart" — the local
--     SwiftData household and the remote row are the same entity from the
--     first successful sync.
--   * `updated_at` is a CLIENT-supplied timestamp (set by SwiftData at
--     write time), not server-assigned. This is documented and deliberate:
--     it lets conflict resolution work identically whether the client is
--     online or applying a queued offline write. The known limitation is
--     device clock skew; the tie-break rule (lexicographically greater
--     stable id) plus the `reject_stale_write` trigger below bound the
--     damage a skewed clock can do to a single row's history.
--   * Soft deletion (`deleted_at`) participates in the same conflict rule
--     as any other field change — there is no special-cased "undelete"
--     path, so a newer tombstone can never be resurrected by an older
--     update (`reject_stale_write` rejects any update older than what is
--     already stored, deleted or not).

-- ---------------------------------------------------------------------
-- Households and membership
-- ---------------------------------------------------------------------

create table households (
  id uuid primary key,
  created_by_user_id uuid not null references auth.users (id),
  display_name text not null default 'My Household',
  is_guest boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create table household_members (
  id uuid primary key,
  household_id uuid not null references households (id) on delete cascade,
  user_id uuid not null references auth.users (id),
  display_name text not null default '',
  role text not null default 'member' check (role in ('owner', 'member')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0,
  unique (household_id, user_id)
);

create index household_members_user_id_idx on household_members (user_id);
create index household_members_household_id_idx on household_members (household_id);

create table household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households (id) on delete cascade,
  code text not null unique,
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  redeemed_at timestamptz,
  redeemed_by uuid references auth.users (id)
);

create index household_invites_household_id_idx on household_invites (household_id);

-- ---------------------------------------------------------------------
-- Health records
-- ---------------------------------------------------------------------

create table children (
  id uuid primary key,
  household_id uuid not null references households (id) on delete cascade,
  name text not null,
  birthday date not null,
  avatar_identifier text not null,
  avatar_color_identifier text not null,
  cached_weight_value double precision,
  cached_weight_unit text,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index children_household_id_idx on children (household_id);

create table weight_history (
  id uuid primary key,
  child_id uuid not null references children (id) on delete cascade,
  weight double precision not null,
  unit text not null,
  effective_date date not null,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index weight_history_child_id_idx on weight_history (child_id);

create table temperature_logs (
  id uuid primary key,
  child_id uuid not null references children (id) on delete cascade,
  temperature_celsius double precision not null,
  measurement_method text not null,
  recorded_at timestamptz not null,
  note text,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index temperature_logs_child_id_idx on temperature_logs (child_id);
create index temperature_logs_recorded_at_idx on temperature_logs (recorded_at);

-- Medication *definitions* are bundled reference data shipped with the app,
-- not user-owned mutable records, and are intentionally not synced in v1
-- (see FeverLogEngine's bundled medications.json). Medication *logs* store
-- a full independent snapshot of the definition at administration time, so
-- they never need to join back to a remote definitions table.
create table medication_logs (
  id uuid primary key,
  child_id uuid not null references children (id) on delete cascade,
  medication_definition_id text,
  active_ingredient_snapshot text not null,
  concentration_value_snapshot double precision not null,
  concentration_milliliters_snapshot double precision not null,
  concentration_unit_snapshot text not null,
  form_snapshot text not null,
  brand_snapshot text not null,
  rule_version_snapshot text,
  source_version_snapshot text,
  volume_milliliters double precision not null,
  calculated_milligrams double precision,
  calculated_milligrams_per_kilogram double precision,
  weight_used_for_calculation double precision,
  weight_unit_used_for_calculation text,
  calculation_status text not null,
  administered_at timestamptz not null,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index medication_logs_child_id_idx on medication_logs (child_id);

create table symptoms (
  id uuid primary key,
  child_id uuid not null references children (id) on delete cascade,
  symptom_identifiers text[] not null default '{}',
  recorded_at timestamptz not null,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index symptoms_child_id_idx on symptoms (child_id);

create table notes (
  id uuid primary key,
  child_id uuid not null references children (id) on delete cascade,
  text text not null,
  recorded_at timestamptz not null,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_version integer not null default 0
);

create index notes_child_id_idx on notes (child_id);

-- Reminders and appearance settings are local-only in v1 per spec and have
-- no remote table.

-- ---------------------------------------------------------------------
-- Shared triggers: audit counter + stale-write rejection
-- ---------------------------------------------------------------------

create or replace function public.bump_sync_version()
returns trigger
language plpgsql
as $$
begin
  new.sync_version := coalesce(old.sync_version, 0) + 1;
  return new;
end;
$$;

-- Defense in depth for the documented conflict rule: `updated_at` is a
-- client-supplied timestamp, so a stale/out-of-order write (e.g. a queued
-- offline write applied after a newer one already landed) must never
-- clobber newer state, including a newer soft-delete tombstone.
create or replace function public.reject_stale_write()
returns trigger
language plpgsql
as $$
begin
  if new.updated_at < old.updated_at then
    raise exception 'stale write rejected: incoming updated_at (%) precedes stored updated_at (%)', new.updated_at, old.updated_at
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'households', 'household_members', 'children', 'weight_history',
    'temperature_logs', 'medication_logs', 'symptoms', 'notes'
  ]
  loop
    execute format('create trigger %I_bump_sync_version before update on %I for each row execute function public.bump_sync_version()', t, t);
    execute format('create trigger %I_reject_stale_write before update on %I for each row execute function public.reject_stale_write()', t, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------

-- SECURITY DEFINER helpers bypass RLS internally so policies that call
-- them don't recurse into household_members' own RLS policy.

create or replace function public.is_household_member(target_household_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from household_members hm
    where hm.household_id = target_household_id
      and hm.user_id = auth.uid()
      and hm.deleted_at is null
  );
$$;

create or replace function public.is_child_accessible(target_child_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from children c
    join household_members hm on hm.household_id = c.household_id
    where c.id = target_child_id
      and hm.user_id = auth.uid()
      and hm.deleted_at is null
  );
$$;

alter table households enable row level security;
alter table household_members enable row level security;
alter table household_invites enable row level security;
alter table children enable row level security;
alter table weight_history enable row level security;
alter table temperature_logs enable row level security;
alter table medication_logs enable row level security;
alter table symptoms enable row level security;
alter table notes enable row level security;

-- households: read-only for clients. Creation/mutation only through the
-- SECURITY DEFINER RPCs below, so a household's ownership metadata can't
-- be forged by a direct insert/update.
create policy households_select on households
  for select using (public.is_household_member(id));

-- household_members: read-only for clients for the same reason — joining
-- happens only through redeem_household_invite().
create policy household_members_select on household_members
  for select using (public.is_household_member(household_id));

-- household_invites: a member may see their own household's invites (to
-- display the active code), but never other households' invites. Rows are
-- only created/redeemed through the RPCs below.
create policy household_invites_select on household_invites
  for select using (public.is_household_member(household_id));

create policy children_select on children
  for select using (public.is_household_member(household_id));
create policy children_insert on children
  for insert with check (public.is_household_member(household_id));
create policy children_update on children
  for update using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

create policy weight_history_select on weight_history
  for select using (public.is_child_accessible(child_id));
create policy weight_history_insert on weight_history
  for insert with check (public.is_child_accessible(child_id));
create policy weight_history_update on weight_history
  for update using (public.is_child_accessible(child_id))
  with check (public.is_child_accessible(child_id));

create policy temperature_logs_select on temperature_logs
  for select using (public.is_child_accessible(child_id));
create policy temperature_logs_insert on temperature_logs
  for insert with check (public.is_child_accessible(child_id));
create policy temperature_logs_update on temperature_logs
  for update using (public.is_child_accessible(child_id))
  with check (public.is_child_accessible(child_id));

create policy medication_logs_select on medication_logs
  for select using (public.is_child_accessible(child_id));
create policy medication_logs_insert on medication_logs
  for insert with check (public.is_child_accessible(child_id));
create policy medication_logs_update on medication_logs
  for update using (public.is_child_accessible(child_id))
  with check (public.is_child_accessible(child_id));

create policy symptoms_select on symptoms
  for select using (public.is_child_accessible(child_id));
create policy symptoms_insert on symptoms
  for insert with check (public.is_child_accessible(child_id));
create policy symptoms_update on symptoms
  for update using (public.is_child_accessible(child_id))
  with check (public.is_child_accessible(child_id));

create policy notes_select on notes
  for select using (public.is_child_accessible(child_id));
create policy notes_insert on notes
  for insert with check (public.is_child_accessible(child_id));
create policy notes_update on notes
  for update using (public.is_child_accessible(child_id))
  with check (public.is_child_accessible(child_id));

-- No DELETE policy on any table: the app never physically deletes a
-- synced record, only soft-deletes via an UPDATE that sets deleted_at.

-- ---------------------------------------------------------------------
-- Household lifecycle RPCs (SECURITY DEFINER — the only sanctioned way
-- to create a household, generate an invite, or join one)
-- ---------------------------------------------------------------------

-- Takes the CLIENT's local household id rather than generating a server
-- one, so the local SwiftData `Household.id` and the remote row's `id`
-- are always the same stable UUID — consistent with every other
-- synchronized entity and avoiding a separate local/remote id-mapping
-- table entirely.
create or replace function public.create_personal_household(p_household_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing_household_id uuid;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  -- Idempotent: calling this again for a user who already owns a
  -- household returns the existing one rather than creating a duplicate,
  -- even if a different household_id is passed (e.g. a retry after a
  -- response was lost, or a second local guest household on the same
  -- device — only the first ever becomes the owned remote household).
  select hm.household_id into v_existing_household_id
  from household_members hm
  where hm.user_id = v_user_id and hm.role = 'owner' and hm.deleted_at is null
  limit 1;

  if v_existing_household_id is not null then
    return v_existing_household_id;
  end if;

  insert into households (id, created_by_user_id, display_name, is_guest)
  values (p_household_id, v_user_id, 'My Household', true)
  on conflict (id) do nothing;

  insert into household_members (id, household_id, user_id, display_name, role)
  values (gen_random_uuid(), p_household_id, v_user_id, '', 'owner')
  on conflict (household_id, user_id) do nothing;

  return p_household_id;
end;
$$;

create or replace function public.create_household_invite()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_household_id uuid;
  v_code text;
  v_attempts integer := 0;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select household_id into v_household_id
  from household_members
  where user_id = v_user_id and role = 'owner' and deleted_at is null
  limit 1;

  if v_household_id is null then
    raise exception 'only a household owner may create an invite';
  end if;

  loop
    -- Hex-only alphabet (0-9, A-F) deliberately avoids the O/0 and I/1/L
    -- confusion pairs entirely, since O/I/L never appear.
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    exit when not exists (
      select 1 from household_invites
      where code = v_code and redeemed_at is null and expires_at > now()
    );
    v_attempts := v_attempts + 1;
    if v_attempts > 10 then
      raise exception 'could not generate a unique invite code, try again';
    end if;
  end loop;

  insert into household_invites (household_id, code, created_by)
  values (v_household_id, v_code, v_user_id);

  return v_code;
end;
$$;

create or replace function public.redeem_household_invite(invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite household_invites%rowtype;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select * into v_invite
  from household_invites
  where code = upper(invite_code)
    and redeemed_at is null
    and expires_at > now()
  for update;

  if not found then
    raise exception 'invalid or expired invite code';
  end if;

  insert into household_members (id, household_id, user_id, display_name, role)
  values (gen_random_uuid(), v_invite.household_id, v_user_id, '', 'member')
  on conflict (household_id, user_id) do nothing;

  update household_invites
  set redeemed_at = now(), redeemed_by = v_user_id
  where id = v_invite.id;

  return v_invite.household_id;
end;
$$;

-- ---------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------

-- Anonymous-auth sessions use the `authenticated` role in Supabase (not
-- `anon`, which is reserved for requests with no session at all), so
-- granting `authenticated` covers both anonymous and permanently linked
-- accounts. RLS still governs which rows are visible/writable.
grant select, insert, update on
  households, household_members, household_invites,
  children, weight_history, temperature_logs, medication_logs, symptoms, notes
  to authenticated;

grant execute on function public.create_personal_household(uuid) to authenticated;
grant execute on function public.create_household_invite() to authenticated;
grant execute on function public.redeem_household_invite(text) to authenticated;

-- ---------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------

alter publication supabase_realtime add table
  household_members, children, weight_history, temperature_logs, medication_logs, symptoms, notes;
