# Reserveringssysteem Syrisch-Orthodoxe Kerken

Online reserveringssysteem en kerkelijk register voor de Syrisch-Orthodoxe gemeenschap in Nederland en Duitsland.

## Wat zit erin

- **Reserveringen** voor huwelijken, doopsels en zaalhuur, met agenda en betaaloverzicht
- **Kerkelijk register** — Doop, Huwelijk en Lidmaatschap, gedeeld over parochies
- **Multi-parochie** — Mor Ephrem (Glane), Mor Kuryakos (Enschede), Mor Yulios (Hengelo) — uitbreidbaar
- **Drietalig** — Nederlands, Suryoyo (ܣܘܪܝܝܐ) en Duits, met rechts-naar-links voor Suryoyo
- **Beheerderspaneel** met eigen inlog per gebruiker en aanpasbare rechten per onderdeel
- **Activiteitenlogboek** — volledig audit trail
- **Backup en herstel** in JSON
- **Aanpasbaar** — locaties, prijzen, celebranten, e-mailsjablonen, alles via Instellingen

## Demo bekijken

Open `index.html` in je browser, of hosting via GitHub Pages / Netlify (zie hieronder).

**Login:** via e-mailadres + wachtwoord. Het eerste account moet je zelf aanmaken in Supabase — zie [Supabase opzetten](#supabase-opzetten-fase-1) hieronder.

## Online zetten

### Optie 1: GitHub Pages (gratis)

1. Push deze repository naar GitHub
2. Ga naar **Settings → Pages**
3. Bij **Source** kies `Deploy from a branch` en selecteer `main` branch, root folder
4. Wacht 1-2 minuten — je site staat dan op `https://JOUW-NAAM.github.io/REPO-NAAM/`

### Optie 2: Netlify Drop (gratis, geen account nodig)

1. Ga naar [app.netlify.com/drop](https://app.netlify.com/drop)
2. Sleep de hele map naar het venster
3. Direct een URL terug

### Optie 3: Cloudflare Pages (gratis)

Vergelijkbaar met Netlify, gekoppeld aan GitHub.

## Status

**Bruikbaar voor één parochie / één computer per parochie.** Geschikt als digitale werkkopie naast een papieren register, of voor één secretariaat-pc. Voor multi-parochie productiegebruik met gedeelde database, echte betalingen en automatische e-mails is een server nodig — zie [TECHNISCH-PLAN.md](TECHNISCH-PLAN.md).

## Supabase opzetten (Fase 1)

De huidige versie gebruikt **Supabase** voor authenticatie en het audit-logboek. De project-URL en publishable-key staan al in `index.html`. Wat je éénmalig moet doen:

### Stap 1: schema in Supabase laden

1. Open [Supabase Dashboard](https://app.supabase.com) → jouw project
2. Ga naar **SQL Editor** → **New query**
3. Open `supabase/schema.sql` uit deze repo en plak de hele inhoud
4. Klik **Run**. Bij succes zie je `Success. No rows returned`. Het schema is veilig om opnieuw te draaien (idempotent).

Wat dit aanmaakt: tabellen `parishes`, `profiles`, `bookings`, `baptisms`, `marriages`, `families`, `blocked_dates`, `waitlist`, `audit_log`, `parish_settings`, plus alle Row Level Security-regels en de drie standaard parochies (Glane, Enschede, Hengelo).

### Stap 2: eerste beheerder aanmaken

1. Supabase Dashboard → **Authentication → Users → Add user → Create new user**
2. Vul je e-mailadres en een sterk wachtwoord in. Vink **Auto Confirm User** aan zodat je niet eerst hoeft te bevestigen.
3. Klik **Create user**.

### Stap 3: jezelf bisdom-rechten geven

Standaard krijgt een nieuwe gebruiker rol `secretariaat` zonder parochie. Voor de eerste login moet je jezelf bisdom-rechten geven:

1. Supabase Dashboard → **SQL Editor → New query**
2. Plak (vervang het e-mailadres):
   ```sql
   update public.profiles
      set role = 'bisdom',
          full_name = 'Jouw Naam',
          parish_id = null
    where email = 'jouw@adres.nl';
   ```
3. Klik **Run**.

### Stap 4: testen

Open de site, klik op **Beheer**, log in met je e-mail en wachtwoord. Je komt dan in het beheerpaneel. Vanaf hier kun je via **Instellingen → Gebruikers** andere medewerkers toevoegen (zie de instructies in de modal).

## Hoe weet ik of Supabase werkt?

In de browser:

1. Open de site, open **DevTools → Console** (F12)
2. Tik in: `_supa` en druk Enter — moet een object teruggeven, geen `null`
3. Probeer in te loggen met je Supabase-account
4. Open in Supabase Dashboard → **Table Editor → `audit_log`** — daar moet een regel "Ingelogd" verschijnen
5. Open Supabase Dashboard → **Authentication → Users** — bij jouw gebruiker moet `last_sign_in_at` zojuist zijn bijgewerkt

Foutmeldingen die je kunt zien:
- *"Invalid login credentials"* → e-mail of wachtwoord klopt niet
- *"Geen profiel gevonden"* → de SQL is niet (helemaal) gelopen, of je hebt de gebruiker handmatig aangemaakt vóór het schema. Run `supabase/schema.sql` opnieuw.
- *Niets gebeurt na "Inloggen"-knop* → check de browser console op rode errors. Vaak een CSP-probleem of verkeerde URL/key.

## Mollie iDEAL koppelen (optioneel)

Voor echte iDEAL-betalingen draait er server-side code op **Supabase Edge Functions**. Je hebt nodig: een Mollie-account met een API-key.

### Stap 1: schema-update

In **Supabase → SQL Editor → New query** plak de hele inhoud van `supabase/schema-mollie.sql` en klik **Run**. Dit voegt `time`, `mollie_payment_id` en `payment_status` toe aan `bookings`.

### Stap 2: API-key als secret

⚠️ **Plak de Mollie-key NIET in code of in git.** Zet hem als Supabase-secret:

- **Via Dashboard:** Supabase → **Project Settings → Edge Functions → Secrets → Add new secret**
  - Name: `MOLLIE_API_KEY` — Value: `test_xxx...` (jouw Mollie test- of live-key)
- **Via CLI:** `supabase secrets set MOLLIE_API_KEY=test_xxx`

### Stap 3: Edge Functions deployen

Twee opties — kies wat het makkelijkst is.

**Optie A — Supabase CLI (aanbevolen):**

```bash
# eenmalig: install + login
npm i -g supabase
supabase login
supabase link --project-ref hdezdfanhbqgfklfbcws

# deploy de drie functions
supabase functions deploy create-payment --no-verify-jwt
supabase functions deploy check-payment  --no-verify-jwt
supabase functions deploy mollie-webhook --no-verify-jwt
```

`--no-verify-jwt` is nodig zodat de webhook (vanuit Mollie) en het publieke booking-formulier (van anonieme bezoekers) de functies kunnen aanroepen.

**Optie B — Dashboard:**

Supabase → **Edge Functions → Deploy a new function**, naam invullen (`create-payment`, daarna `check-payment`, daarna `mollie-webhook`), inhoud van `supabase/functions/<naam>/index.ts` plakken, **Deploy**.
Bij iedere functie: zet **Verify JWT** uit.

### Stap 4 (aanbevolen): webhook URL

Zodra `mollie-webhook` is gedeployed, vind je de URL in Supabase → Edge Functions → mollie-webhook → bovenaan. Plaatst die ook als secret zodat `create-payment` hem meegeeft aan elke Mollie-call:

- Name: `MOLLIE_WEBHOOK_URL`
- Value: `https://hdezdfanhbqgfklfbcws.supabase.co/functions/v1/mollie-webhook`

(zonder dit blijft betalen werken — alleen de status komt dan binnen via de return-pagina in plaats van direct via Mollie's webhook.)

### Stap 5: testen

Op de site: maak een reservering, kies **iDEAL** als betaalmethode, klik **Bevestig**. Je wordt doorgestuurd naar Mollie's testbank. Kies daar **Paid** in de simulator. Je komt terug op de site, ziet "Betaling geslaagd", en in de admin staat de reservering met `paid='partial'` (voorschot voldaan).

In Mollie Dashboard → **Payments** zie je de testbetaling verschijnen.

### Beveiliging

- Mollie key staat alleen op Supabase als secret — niet in de frontend, niet in git
- De Edge Functions valideren de booking server-side
- Bij webhook-pings haalt de server de definitieve status op vanuit Mollie zelf (kan niet worden vervalst)
- ⚠️ De test-key die je in chat hebt gedeeld: revoke en regenereer hem in [Mollie Dashboard → Developers → API keys](https://my.mollie.com/dashboard/developers/api-keys), zet de nieuwe als secret

## Wat zit waar (Fase 1)

| Onderdeel | Opslag |
|---|---|
| Authenticatie (login, sessie, wachtwoorden) | **Supabase Auth** (server-side bcrypt) |
| Profielen, rollen, rechten | **Supabase** tabel `profiles` |
| Audit-logboek | **Supabase** tabel `audit_log` (gespiegeld naar localStorage als cache) |
| Reserveringen, registers, blokkades, instellingen | localStorage (Fase 2 verhuist dit naar Supabase) |
| Frontend code | Statisch op GitHub Pages |

## Beperkingen huidige fase

- **Reserveringen en registers staan nog lokaal** — daarom geldt voor die data nog steeds: één computer = één kopie. Fase 2 verhuist alles naar Supabase met Row Level Security per parochie.
- **Geen echte iDEAL/Mollie betalingen** — betaalstatus is handmatig in te vullen door beheerder.
- **Geen automatische e-mails** — sjablonen openen je eigen mailprogramma met ingevulde tekst. Wachtwoord-reset werkt wel automatisch via Supabase.
- **Sessie verloopt** automatisch na 30 minuten inactiviteit.

Voor het volledige productieplan: zie [TECHNISCH-PLAN.md](TECHNISCH-PLAN.md).

## Techniek

- HTML, CSS en JavaScript in één bestand — geen build, geen dependencies behalve Chart.js (CDN)
- Werkt in alle moderne browsers
- Geen server nodig om te bekijken

## Licentie

Zie [LICENSE](LICENSE).
