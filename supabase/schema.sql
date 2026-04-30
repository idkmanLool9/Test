-- ============================================================================
-- Reserveringssysteem Syrisch-Orthodoxe Kerken — database-schema
-- Plak dit in: Supabase → SQL Editor → New query → Run
-- Veilig om opnieuw uit te voeren (idempotent).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PAROCHIES
-- ----------------------------------------------------------------------------
create table if not exists public.parishes (
  id            text primary key,
  name          text not null,
  short_mark    text,
  address       text,
  phone         text,
  email         text,
  iban          text,
  hours         text,
  city          text,
  country       text default 'NL',
  language      text default 'nl',
  currency      text default 'EUR',
  created_at    timestamptz not null default now()
);

insert into public.parishes (id, name, short_mark, address, phone, email, iban, hours, city, country)
values
  ('glane',    'Mor Ephrem Klooster', 'ME', 'Glanerbrugstraat 33, Glane', '053 461 47 64', 'info@morephrem.nl',  'NL00 INGB 0000 0000 00', 'Werkdagen 9.00 - 17.00 uur', 'Glane',    'NL'),
  ('enschede', 'Mor Kuryakos',        'MK', 'Voorbeeldstraat 1, Enschede', '053 000 00 00', 'info@morkuryakos.nl', 'NL11 INGB 0000 0000 11', 'Werkdagen 10.00 - 16.00 uur','Enschede','NL'),
  ('hengelo',  'Mor Yulios',          'MY', 'Voorbeeldweg 5, Hengelo',     '074 000 00 00', 'info@moryulios.nl',  'NL22 INGB 0000 0000 22', 'Werkdagen 9.00 - 15.00 uur', 'Hengelo',  'NL')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 2. PROFIELEN  (1-op-1 met auth.users — Supabase Auth doet wachtwoorden)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text,
  parish_id   text references public.parishes(id),       -- null = bisdom-niveau
  role        text not null default 'secretariaat'
              check (role in ('bisdom','admin','secretariaat','priester')),
  perms       text[] not null default array[
                'dashboard','bookings','contacts','reports',
                'blocked','templates','audit','register','settings'
              ]::text[],
  active      boolean not null default true,
  last_login  timestamptz,
  created_at  timestamptz not null default now()
);

-- Auto-create profile on signup. Admin moet daarna parish_id en role goedzetten.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', new.email))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 3. RESERVERINGEN
-- ----------------------------------------------------------------------------
create table if not exists public.bookings (
  id             uuid primary key default gen_random_uuid(),
  ref            text unique not null,
  parish_id      text not null references public.parishes(id),
  date           date not null,
  type           text not null,
  location       text not null,
  firstname      text,
  lastname       text,
  name           text,
  email          text,
  phone          text,
  address        text,
  postcode       text,
  city           text,
  guests         int  default 0,
  celebrant      text,
  notes          text,
  status         text not null default 'pending'
                 check (status in ('pending','confirmed','cancelled','completed')),
  paid           text not null default 'unpaid'
                 check (paid in ('unpaid','partial','paid')),
  method         text,
  total          numeric default 0,
  deposit        numeric default 0,
  flagged        boolean default false,
  internal_notes jsonb default '[]'::jsonb,
  history        jsonb default '[]'::jsonb,
  created_by     uuid references auth.users(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists bookings_parish_date on public.bookings (parish_id, date);
create index if not exists bookings_status      on public.bookings (status);

-- ----------------------------------------------------------------------------
-- 4. DOOPREGISTER
-- ----------------------------------------------------------------------------
create table if not exists public.baptisms (
  id             text primary key,
  parish_id      text not null references public.parishes(id),
  firstname      text,
  lastname       text,
  firstname_sy   text,
  lastname_sy    text,
  birth_date     date,
  birth_place    text,
  baptism_date   date,
  baptism_place  text,
  father         text,
  mother         text,
  godfather      text,
  godmother      text,
  celebrant      text,
  notes          text,
  created_by     uuid references auth.users(id),
  created_at     timestamptz not null default now()
);
create index if not exists baptisms_parish on public.baptisms (parish_id);

-- ----------------------------------------------------------------------------
-- 5. HUWELIJKSREGISTER
-- ----------------------------------------------------------------------------
create table if not exists public.marriages (
  id                 text primary key,
  parish_id          text not null references public.parishes(id),
  groom_firstname    text,
  groom_lastname     text,
  bride_firstname    text,
  bride_lastname     text,
  groom_baptism_id   text references public.baptisms(id),
  bride_baptism_id   text references public.baptisms(id),
  date               date,
  place              text,
  celebrant          text,
  witnesses          text,
  notes              text,
  created_by         uuid references auth.users(id),
  created_at         timestamptz not null default now()
);
create index if not exists marriages_parish on public.marriages (parish_id);

-- ----------------------------------------------------------------------------
-- 6. GEZINSREGISTER (lidmaatschap)
-- ----------------------------------------------------------------------------
create table if not exists public.families (
  id                  text primary key,
  parish_id           text not null references public.parishes(id),
  head_name           text,
  partner_name        text,
  children            jsonb default '[]'::jsonb,
  address             text,
  contact             text,
  member_since        date,
  annual_contribution text,
  notes               text,
  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now()
);
create index if not exists families_parish on public.families (parish_id);

-- ----------------------------------------------------------------------------
-- 7. GEBLOKKEERDE DATA (per parochie)
-- ----------------------------------------------------------------------------
create table if not exists public.blocked_dates (
  id          uuid primary key default gen_random_uuid(),
  parish_id   text not null references public.parishes(id),
  date        date not null,
  reason      text,
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now(),
  unique (parish_id, date)
);

-- ----------------------------------------------------------------------------
-- 8. WACHTLIJST
-- ----------------------------------------------------------------------------
create table if not exists public.waitlist (
  id          uuid primary key default gen_random_uuid(),
  parish_id   text not null references public.parishes(id),
  name        text,
  email       text,
  phone       text,
  date        date,
  location    text,
  type        text,
  created_at  timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 9. AUDIT-LOGBOEK
-- ----------------------------------------------------------------------------
create table if not exists public.audit_log (
  id          uuid primary key default gen_random_uuid(),
  ts          timestamptz not null default now(),
  user_id     uuid references auth.users(id),
  parish_id   text references public.parishes(id),
  who_name    text,
  action      text not null,
  detail      text
);
create index if not exists audit_parish_ts on public.audit_log (parish_id, ts desc);

-- ----------------------------------------------------------------------------
-- 10. INSTELLINGEN per parochie (types, locaties, celebranten, sjablonen, etc.)
-- ----------------------------------------------------------------------------
create table if not exists public.parish_settings (
  parish_id   text primary key references public.parishes(id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.parishes        enable row level security;
alter table public.profiles        enable row level security;
alter table public.bookings        enable row level security;
alter table public.baptisms        enable row level security;
alter table public.marriages       enable row level security;
alter table public.families        enable row level security;
alter table public.blocked_dates   enable row level security;
alter table public.waitlist        enable row level security;
alter table public.audit_log       enable row level security;
alter table public.parish_settings enable row level security;

-- Helper: huidige gebruiker zijn parish_id
create or replace function public.current_parish_id()
returns text language sql stable security definer set search_path = public as $$
  select parish_id from public.profiles where id = auth.uid();
$$;

create or replace function public.current_role_name()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.has_perm(p text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(p = any(perms), false) from public.profiles where id = auth.uid();
$$;

create or replace function public.is_bisdom()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(role = 'bisdom', false) from public.profiles where id = auth.uid();
$$;

-- ----- PAROCHIES (publiek leesbaar; alleen bisdom mag wijzigen)
drop policy if exists parishes_read   on public.parishes;
drop policy if exists parishes_modify on public.parishes;
create policy parishes_read   on public.parishes for select using (true);
create policy parishes_modify on public.parishes for all
  using (public.is_bisdom()) with check (public.is_bisdom());

-- ----- PROFIELEN (eigen profiel zien/updaten; bisdom ziet alle profielen)
drop policy if exists profiles_self_read   on public.profiles;
drop policy if exists profiles_self_update on public.profiles;
drop policy if exists profiles_bisdom      on public.profiles;
create policy profiles_self_read on public.profiles for select
  using (auth.uid() = id or public.is_bisdom());
create policy profiles_self_update on public.profiles for update
  using (auth.uid() = id) with check (auth.uid() = id and parish_id = (select parish_id from public.profiles where id = auth.uid()) and role = (select role from public.profiles where id = auth.uid()));
create policy profiles_bisdom on public.profiles for all
  using (public.is_bisdom()) with check (public.is_bisdom());

-- ----- RESERVERINGEN
--  - iedereen (anon) mag een nieuwe pending reservering insturen via het publieke formulier
--  - eigen parochie kan lezen/wijzigen
--  - bisdom kan alles
drop policy if exists bookings_anon_insert on public.bookings;
drop policy if exists bookings_parish_read on public.bookings;
drop policy if exists bookings_parish_mod  on public.bookings;
drop policy if exists bookings_bisdom      on public.bookings;
create policy bookings_anon_insert on public.bookings for insert
  with check (status = 'pending');
create policy bookings_parish_read on public.bookings for select
  using (parish_id = public.current_parish_id() or public.is_bisdom());
create policy bookings_parish_mod on public.bookings for update
  using (parish_id = public.current_parish_id())
  with check (parish_id = public.current_parish_id());
create policy bookings_parish_del on public.bookings for delete
  using (parish_id = public.current_parish_id() or public.is_bisdom());

-- ----- DOOPREGISTER, HUWELIJKSREGISTER, GEZINNEN
--  - alleen ingelogde, eigen-parochie of bisdom
do $$ declare t text; begin
  for t in select unnest(array['baptisms','marriages','families','blocked_dates','waitlist','parish_settings']) loop
    execute format('drop policy if exists %I_parish_all on public.%I', t, t);
    execute format($f$create policy %I_parish_all on public.%I for all
      using (parish_id = public.current_parish_id() or public.is_bisdom())
      with check (parish_id = public.current_parish_id() or public.is_bisdom())$f$, t, t);
  end loop;
end $$;

-- ----- AUDIT-LOGBOEK
drop policy if exists audit_read   on public.audit_log;
drop policy if exists audit_insert on public.audit_log;
create policy audit_read   on public.audit_log for select
  using (parish_id = public.current_parish_id() or public.is_bisdom());
create policy audit_insert on public.audit_log for insert
  with check (auth.uid() is not null);

-- ----------------------------------------------------------------------------
-- 11. updated_at triggers
-- ----------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists bookings_touch on public.bookings;
create trigger bookings_touch before update on public.bookings
  for each row execute function public.touch_updated_at();

-- ============================================================================
-- KLAAR.
-- Volgende stap: maak een eerste gebruiker via Supabase → Authentication → Users
-- en zet daarna in de SQL editor:
--
--   update public.profiles
--      set role = 'bisdom', full_name = 'Jouw Naam', parish_id = null
--    where email = 'jouw@adres.nl';
--
-- Een bisdom-gebruiker kan vervolgens via de app andere parochie-beheerders
-- aanmaken en hun rechten instellen.
-- ============================================================================
