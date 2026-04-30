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

**Eerste login:** gebruikersnaam `admin`, wachtwoord `admin` — wijzig dit direct na de eerste keer inloggen via **Beheer → Gebruikers**.

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

## Belangrijk bij eerste gebruik

1. Open de site en ga naar **Beheer** → log in met `admin` / `admin`
2. Ga direct naar **Beheer → Gebruikers** en wijzig het wachtwoord van het `admin`-account
3. Maak voor elke medewerker een eigen account met alleen de rechten die ze nodig hebben
4. Maak regelmatig een backup via **Beheer → Backup** — dit is een JSON-bestand met alle data

## Beperkingen op GitHub Pages

GitHub Pages is statische hosting — er is geen server, dus:

- **Data staat alleen in de browser** (localStorage). Wie het systeem op een andere computer of in een andere browser opent, ziet zijn eigen lege kopie. Gebruik backup/restore om data over te zetten.
- **Geen echte iDEAL/Mollie betalingen** — betaalstatus is handmatig in te vullen door beheerder.
- **Geen automatische e-mails** — sjablonen openen je eigen mailprogramma met ingevulde tekst.
- **Wachtwoorden** worden gehashed (PBKDF2-SHA256, 200.000 rondes) en zo opgeslagen, niet meer in plaintext. Een sessie wordt automatisch beëindigd na 30 minuten inactiviteit. Na 5 mislukte login-pogingen wordt verder proberen 30s geblokkeerd.

Voor een echt multi-parochie systeem met gedeelde database, echte betalingen en automatische e-mails: zie [TECHNISCH-PLAN.md](TECHNISCH-PLAN.md).

## Techniek

- HTML, CSS en JavaScript in één bestand — geen build, geen dependencies behalve Chart.js (CDN)
- Werkt in alle moderne browsers
- Geen server nodig om te bekijken

## Licentie

Zie [LICENSE](LICENSE).
