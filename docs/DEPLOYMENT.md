# Deploying VoteWala

## 1. Prerequisites you must set up

| What | Where | Notes |
| --- | --- | --- |
| Official logo | `brand/VW.png` (commit it) | Required: builds fail without it. |
| PostgreSQL 14+ | Neon, Supabase, AWS RDS, or the bundled `docker-compose.yml` | Set `DATABASE_URL`. The migration installs triggers, so the role must be able to create functions. |
| Google OAuth client | Google Cloud Console → APIs & Services → Credentials → *OAuth client ID* (Web) | Authorised redirect URI: `https://<your-domain>/api/auth/callback/google`. Set `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`. Configure the OAuth consent screen and publish it. |
| SMS provider for OTP | Twilio (`SMS_PROVIDER=twilio`) or MSG91 (`SMS_PROVIDER=msg91`) | Indian SMS needs **DLT registration** (entity, sender ID, and an approved OTP template). With MSG91 the template must contain `##otp##`. `SMS_PROVIDER=console` is refused in production. |
| Secrets | any secret manager | `NEXTAUTH_SECRET`, `OTP_SECRET`, `CRON_SECRET`: each `openssl rand -base64 32`. |
| Admins | `ADMIN_EMAILS` | Comma-separated Google emails promoted to admin at sign-in. Or `npm run make-admin -- email` after their first sign-in. |
| Domain + HTTPS | your host | Set `NEXTAUTH_URL` to the public https URL. |

See `.env.example` for every variable.

## 2. Database

```bash
npm ci
npx prisma migrate deploy   # schema, constraints and triggers
npm run db:seed             # 175 Assembly + 25 Lok Sabha constituencies (idempotent)
```

Do **not** run `npm run db:seed:demo` in production: it creates fictional demo candidates and polls.

## 3. Google Cloud

See [DEPLOY-GCP.md](DEPLOY-GCP.md) (Cloud Run + Cloud SQL, scripted).

## 3a. Vercel

1. Import the repository and add the environment variables above.
2. Build command: `npm run build` (default). It generates the brand assets and the Prisma client.
3. Run migrations from CI or your machine against the production `DATABASE_URL` (step 2) before the first deploy and after each schema change.
4. `vercel.json` schedules `/api/cron/finalize` every 10 minutes. Vercel sends `Authorization: Bearer $CRON_SECRET` automatically when `CRON_SECRET` is set. The Hobby plan only allows daily crons; on that plan, use an external scheduler (step 4).

## 3b. Docker (single server)

```bash
cp .env.example .env            # fill in values; set POSTGRES_PASSWORD too
docker compose up -d db
docker compose run --rm migrate # migrate + seed directory
docker compose up -d --build app
```

Put a TLS-terminating reverse proxy (Caddy, nginx, a cloud load balancer) in front
of port 3000 and make it forward `X-Forwarded-For`.

## 4. Scheduled finalisation

Closed polls get a frozen end-of-day report when the finaliser runs. Results pages
fall back to computing closed polls up to their closing time, so nothing breaks if
the job is late. Run it every 5–15 minutes:

```bash
curl -fsS -X POST -H "Authorization: Bearer $CRON_SECRET" https://<your-domain>/api/cron/finalize
# or, from a machine with DATABASE_URL:
npm run finalize
```

Admins can also run it from the dashboard ("Finalize closed polls now").

## 5. Going-live checklist

- [ ] `brand/VW.png` committed, and `npm run brand` output reviewed (the favicon crop in particular).
- [ ] Constituency directory cross-checked against the CEO Andhra Pradesh / ECI lists (`src/data/constituencies.ts`).
- [ ] Candidate CSVs imported, and every record **verified against its official source** by an admin.
- [ ] Google OAuth consent screen published, with production redirect URI.
- [ ] DLT-approved SMS template live; tested with a real handset.
- [ ] `ENABLE_DEV_LOGIN` unset (it is ignored in production builds anyway).
- [ ] Cron for `/api/cron/finalize` running.
- [ ] Database backups enabled (votes and the audit log are not recoverable otherwise).
- [ ] Privacy policy and contact details reviewed by counsel, including obligations under the Digital Personal Data Protection Act, 2023, and any Election Commission guidance on opinion polls during the Model Code of Conduct / Section 126A silence periods.
