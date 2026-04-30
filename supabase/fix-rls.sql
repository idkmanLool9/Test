-- Fix voor: "new row violates row-level security policy for table bookings"
-- Plak in: Supabase → SQL Editor → New query → Run.
-- Idempotent — veilig om meermaals te runnen.

-- Oude bookings INSERT policies opruimen
drop policy if exists bookings_anon_insert on public.bookings;
drop policy if exists bookings_auth_insert on public.bookings;
drop policy if exists bookings_insert      on public.bookings;

-- Nieuwe bookings INSERT policy:
--  - anonieme bezoekers via het publieke formulier mogen alleen pending bookings aanmaken
--  - ingelogde gebruikers mogen pending bookings aanmaken (publiek formulier)
--    of bookings voor hun eigen parochie, en bisdom mag voor alle parochies
create policy bookings_insert on public.bookings for insert
  to anon, authenticated
  with check (
    status = 'pending'
    or parish_id = public.current_parish_id()
    or public.is_bisdom()
  );

-- Voor de zekerheid ook expliciete TO-clausules op de andere bookings policies
drop policy if exists bookings_parish_read on public.bookings;
drop policy if exists bookings_parish_mod  on public.bookings;
drop policy if exists bookings_parish_del  on public.bookings;

create policy bookings_parish_read on public.bookings for select
  to authenticated
  using (parish_id = public.current_parish_id() or public.is_bisdom());

create policy bookings_parish_mod on public.bookings for update
  to authenticated
  using (parish_id = public.current_parish_id() or public.is_bisdom())
  with check (parish_id = public.current_parish_id() or public.is_bisdom());

create policy bookings_parish_del on public.bookings for delete
  to authenticated
  using (parish_id = public.current_parish_id() or public.is_bisdom());

-- Verificatie — moet 4 rijen geven (insert, select, update, delete)
select policyname, cmd, roles
  from pg_policies
 where schemaname = 'public' and tablename = 'bookings'
 order by cmd;
