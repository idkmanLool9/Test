# Technisch plan productiesysteem

Voor een ontwikkelaar of webbureau die het demo-prototype omzet naar een echt systeem.

## Architectuur

**Multi-tenant** — één applicatie, meerdere parochies. Elke parochie eigen subdomein:
- `glane.reserveren.suryoyo.nl`
- `enschede.reserveren.suryoyo.nl`
- enz.

Centrale identiteit op `register.suryoyo.nl` voor het gedeelde kerkelijk register over parochies heen.

## Stack-aanbeveling

- **Backend:** Node.js + Express, of Python + FastAPI, of PHP + Laravel
- **Database:** PostgreSQL (host bij voorkeur in EU — Hetzner Duitsland of TransIP Nederland)
- **Frontend:** kan gehandhaafd blijven als vanilla HTML/JS, of overgezet naar React/Vue
- **Authenticatie:** sessie-cookies + bcrypt voor wachtwoorden, of een dienst zoals Clerk/Auth0
- **E-mail:** Postmark, Mailgun of SendGrid
- **Betalingen:** Mollie (iDEAL, Bancontact, SEPA)
- **Bestandsopslag:** lokaal of S3-compatible (MinIO, Backblaze)

## Datamodel

### Parochies (`parishes`)
- id, naam, korte_naam, adres, telefoon, e-mail, IBAN, openingstijden, taal, valuta, land

### Gebruikers (`users`)
- id, parochie_id (nullable voor bisdom-rol), gebruikersnaam, wachtwoord_hash, naam, e-mail, rechten (JSON), laatste_login

### Reserveringen (`bookings`)
- id, ref, parochie_id, datum, type, locatie, aanvrager-velden, status, betaalstatus, total, deposit, mollie_payment_id

### Doopregister (`baptisms`)
- id, parochie_id, naam_latijn, naam_suryoyo, geboortedatum, geboorteplaats, doopdatum, doopplaats, vader, moeder, peetvader, peetmoeder, bedienaar, aantekeningen

### Huwelijksregister (`marriages`)
- id, parochie_id, bruidegom-velden, bruid-velden, doop_ref_bruidegom (FK naar baptisms), doop_ref_bruid (FK), datum, plaats, bedienaar, getuigen

### Lidmaatschap (`families`)
- id, parochie_id, hoofd, partner, kinderen (JSON of aparte tabel), adres, contact, lid_sinds, jaarbijdrage_status

### Audit (`audit_log`)
- id, tijdstip, gebruiker_id, parochie_id, actie, doel_type, doel_id, details

## Beveiligingseisen

- HTTPS verplicht (Let's Encrypt)
- Wachtwoorden gehashed met bcrypt (cost factor ≥ 12)
- CSRF-bescherming op alle POST/PUT/DELETE
- Rate limiting op login en betalingen
- Backup dagelijks naar versleutelde offsite locatie
- AVG: dataverwerkingsregister, recht op inzage en verwijdering geïmplementeerd
- Audit-logs ten minste 5 jaar bewaren (canoniek belang)

## Rollen

| Rol | Reikwijdte | Rechten |
|---|---|---|
| Patriarchaat / Bisschop | Alle parochies | Alles lezen, parochies beheren |
| Parochie-beheerder | Eigen parochie | Volledig binnen parochie |
| Secretariaat | Eigen parochie | Reserveringen + register lezen/inschrijven |
| Priester | Eigen parochie | Register lezen + ondertekenen |
| Lid (toekomst) | Eigen account | Eigen reserveringen en gezinsgegevens |

## Migratiepad

1. **MVP (3 maanden)** — één parochie als pilot, reserveringen + Nederlands + Duits, basis-doopregister
2. **Suryoyo + RTL** (1 maand)
3. **Tweede parochie aansluiten** (1 maand) — multi-tenant testen
4. **Huwelijksregister + lidmaatschap** (2 maanden)
5. **Migratie bestaande papieren registers** (doorlopend)
6. **Geleidelijke uitrol** naar overige parochies

## Geschatte kosten

| Onderdeel | Eenmalig | Maandelijks |
|---|---|---|
| Ontwikkeling MVP | € 8.000 - € 15.000 | — |
| Hosting (VPS + database) | — | € 25 - € 60 |
| Domein + SSL | € 15 | — |
| E-mail dienst | — | € 10 - € 30 |
| Mollie transactiekosten | — | per transactie |
| Backups + monitoring | — | € 10 - € 20 |
| Onderhoud + updates | — | € 100 - € 300 |

## Juridisch

- Stichting onder bisdom als rechtspersoon, of contract per parochie
- Verwerkersovereenkomst per parochie
- Privacyverklaring in NL, Suryoyo, Duits
- AVG functionaris bij meer dan een paar honderd betrokkenen overwegen

## Wat niet in deze demo zit (en wel moet voor productie)

- Echte authenticatie met sessies en wachtwoord-reset
- Server-side validatie (nu alleen client-side)
- E-mail verzending
- iDEAL/Mollie integratie met webhooks
- Bestandsupload (foto bij doop, scans van oude registers)
- Print-templates per taal in plaats van alleen Nederlands
- Liturgische kalender met automatische blokkering
- Notificaties bij conflicterende boekingen tussen parochies
- API voor toekomstige mobiele app
