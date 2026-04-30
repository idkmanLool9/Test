-- Mollie velden + tijdslot voor reserveringen
-- Plak in: Supabase → SQL Editor → New query → Run

alter table public.bookings
  add column if not exists time              text,
  add column if not exists mollie_payment_id text,
  add column if not exists payment_status    text;

create index if not exists bookings_mollie_id on public.bookings(mollie_payment_id);

-- De webhook (publiek aanroepbaar door Mollie) en de check-payment functie
-- gebruiken de service-role key, dus we hoeven hier geen extra RLS-policy
-- aan te passen. Anonieme gebruikers blijven alleen 'pending' bookings
-- mogen aanmaken (dat staat al in schema.sql).
