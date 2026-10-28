# VoteWala

**Your Voice. Your Choice. · మీ అభిప్రాయం. మీ ఎంపిక.**

Andhra Pradesh MLA & MP Candidate Opinion Polling Platform: an independent,
non-partisan site where verified people take part in daily opinion polls about
candidates in all 175 Assembly and 25 Lok Sabha constituencies, in Telugu and English.

> VoteWala is not affiliated with any political party, candidate, government body
> or the Election Commission of India. Its results are opinions of self-selected
> participants, not official election results or forecasts. See `/methodology`.

## Features

- **Public site:** home page with a constituency search, daily poll cards, candidate cards, result charts, participation statistics and previous polls; MLA and MP poll listings (filter by open, upcoming, closed or district); poll pages with voting; results; candidate and constituency directories; a methodology and privacy page.
- **Telugu / English:** every interface string in both languages (`src/i18n`), bilingual names for constituencies, candidates and poll questions, and a language switcher in the header that remembers your choice in a cookie.
- **Sign-in:** Google, then one-time mobile verification by SMS OTP (Twilio or MSG91). Each mobile number can belong to only one account.
- **Voting protections, enforced in PostgreSQL:**
  - `UNIQUE (pollId, userId)`: one vote per verified account per poll, even under concurrent requests.
  - A trigger rejects votes outside the poll window or on unpublished polls, using the database clock, and makes votes immutable.
  - A composite foreign key stops a vote using an option from another poll.
  - `UNIQUE (phone)` plus an Indian mobile format check.
  - The audit log is append-only: a trigger blocks `UPDATE` and `DELETE`.
- **Scheduling:** daily polls set by IST calendar day; opening and closing times are decided on the server; an admin can repeat a poll for up to 31 days.
- **Result publication policy per poll:** *Live*, *Delayed* (N minutes) or *After close*. Percentages are hidden below `RESULTS_MIN_SAMPLE` votes. A configurable **legal blackout** (`RESULTS_BLACKOUT`, for RP Act s.126/126A) hides all results.
- **Final end-of-day reports:** frozen by `/api/cron/finalize` (idempotent). Daily and per-poll CSV exports contain totals only, never individual votes.
- **Admin panel (`/admin`):** dashboard; poll scheduling with publish and cancel; candidate CSV import (only official ECI / CEO Andhra Pradesh source links are accepted); candidate verification workflow; audit log with CSV export. Every admin action is audited.
- **Neutral design:** one neutral colour for all chart bars, no party symbols, the methodology and sample limitations explained on the site, and disclaimers on every results view.

## Branding

The official logo lives at **`brand/VW.png`** and is used as supplied in the header
(desktop and mobile), footer, sign-in page, loading screen and welcome screen.
`npm run brand` crops away excess whitespace, makes a transparent derivative,
crops the symbol for the favicon and app icons, and **samples the brand colours
from the logo** into `src/styles/brand-tokens.css`. See [`brand/README.md`](brand/README.md).

Colour use: orange for primary actions and selected states, green for
verification and supporting accents, navy and white for content surfaces.
Text and white-on-colour buttons use darker "ink" versions of each accent so they meet WCAG AA contrast.

## Stack

Next.js 15 (App Router, server actions) · TypeScript · Tailwind CSS · PostgreSQL ·
Prisma · NextAuth (Google) · Vitest · Playwright-friendly markup.

```
src/app          routes (public pages, /admin, /api)
src/components   UI components (Logo, header, cards, charts, forms)
src/lib          auth, OTP, voting, results policy, finalisation, audit, CSV
src/i18n         en / te dictionaries
src/data         AP constituency directory (2008 delimitation)
prisma           schema, migrations (constraints + triggers), seed
scripts          brand asset generator, make-admin, finalize
tests            unit tests + PostgreSQL integration tests
```

## Local development

```bash
cp .env.example .env               # set DATABASE_URL etc.
cp /path/to/VW.png brand/VW.png    # the official logo
npm install
npx prisma migrate deploy
npm run db:seed                    # constituencies
npm run db:seed:demo               # optional: fictional demo candidates and polls, clearly labelled
npm run dev
```

To try voting locally without Google credentials, set `ENABLE_DEV_LOGIN="true"`
(ignored in production) and use the development sign-in on `/signin`. With
`SMS_PROVIDER="console"`, OTP codes are printed to the server log.

To make yourself an admin, add your email to `ADMIN_EMAILS`, or run
`npm run make-admin -- you@example.com` after signing in once.

## Tests

```bash
npm run typecheck
npm test          # unit tests
npm run test:db   # + PostgreSQL integration tests (needs a database whose name contains "test")
```

The integration tests check, against a real database: concurrent double votes,
votes outside the poll window, cross-poll options, vote immutability, phone
uniqueness, OTP attempt limits and cooldown, result hiding and finalisation, and
that the audit log is append-only. CI runs them all (`.github/workflows/ci.yml`).

## Deployment

- **Google Cloud (Cloud Run + Cloud SQL):** [`docs/DEPLOY-GCP.md`](docs/DEPLOY-GCP.md). Two scripts, `deploy/gcp/setup.sh` and `deploy/gcp/deploy.sh`, run from Cloud Shell.
- Vercel / Docker, required credentials and the go-live checklist: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).
