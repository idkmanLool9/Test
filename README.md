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

**Demo login:** gebruikersnaam `admin`, wachtwoord `admin`

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

**Demo / prototype.** Dit is bedoeld om aan parochies en het bisdom te tonen hoe het systeem werkt. Voor productiegebruik door meerdere kerken is een echt backend (database, authenticatie, betalingen, e-mails) nodig — dat is werk voor een ontwikkelaar.

## Beperkingen van deze demo

- Data wordt opgeslagen in de browser (localStorage) — niet gedeeld tussen apparaten of gebruikers
- Geen echte iDEAL/Mollie integratie — betaling is gesimuleerd
- Geen automatische e-mails — sjablonen zijn wel in te stellen
- Geen echte authenticatie — wachtwoorden staan in plain text in localStorage

Voor een productiesysteem zie [TECHNISCH-PLAN.md](TECHNISCH-PLAN.md).

## Techniek

- HTML, CSS en JavaScript in één bestand — geen build, geen dependencies behalve Chart.js (CDN)
- Werkt in alle moderne browsers
- Geen server nodig om te bekijken

## Licentie

Zie [LICENSE](LICENSE).
