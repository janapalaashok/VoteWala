# Deploying VoteWala on Google Cloud

```
            ┌──────────────── Cloud Scheduler (every 10 min) ──► POST /api/cron/finalize
            │
Users ──► Cloud Run "votewala" (Next.js, asia-south1) ──unix socket──► Cloud SQL PostgreSQL 16
            ▲                    │ secrets                               (backups + PITR)
            │                    └──────────────► Secret Manager
Cloud Build ──► Artifact Registry (web + migrate images) ──► Cloud Run Job "votewala-migrate"
```

Everything runs in **asia-south1 (Mumbai)**, the closest region to Andhra Pradesh.

## What you need before starting

1. A GCP project with **billing enabled**, and an account with Owner (or Editor +
   Security Admin) on it.
2. The official logo at **`brand/VW.png`**. The build refuses to run without it.
3. A **Google OAuth client** (APIs & Services → Credentials → Create credentials →
   OAuth client ID → Web application). You add the redirect URI after the first deploy
   (step 4). Configure and publish the OAuth consent screen.
4. An SMS account: **MSG91** or **Twilio**, with **DLT registration** and an approved
   OTP template (required for SMS in India).

## Steps (in Cloud Shell)

Open [Cloud Shell](https://shell.cloud.google.com), which already has `gcloud`, `git` and `openssl`.

```bash
git clone https://github.com/janapalaashok/VoteWala.git && cd VoteWala
git checkout claude/votewala-website-branding-3tvmwx   # or main, once merged
# Upload VW.png in Cloud Shell (⋮ → Upload), then:
mv ~/VW.png brand/VW.png

cp deploy/gcp/config.example.env deploy/gcp/config.env
nano deploy/gcp/config.env      # PROJECT_ID, GOOGLE_CLIENT_ID, ADMIN_EMAILS, SMS settings

bash deploy/gcp/setup.sh        # once: APIs, Cloud SQL, service accounts, secrets (~10–15 min)
bash deploy/gcp/deploy.sh       # build → migrate → deploy → schedule (~8–12 min)
```

`setup.sh` generates the database password, `NEXTAUTH_SECRET`, `OTP_SECRET` and
`CRON_SECRET` itself. It asks you to type only the Google client secret and the
SMS key (input is hidden). All of these go to Secret Manager and never into files.

4. `deploy.sh` ends by printing the site URL and the **redirect URI**. Add
   `https://…run.app/api/auth/callback/google` to the OAuth client's
   *Authorised redirect URIs*.
5. Sign in on the site with an email listed in `ADMIN_EMAILS`; you'll be made an admin.
   Then go to **/admin → Candidates** to import and verify candidate records.

Re-run `bash deploy/gcp/deploy.sh` for every new release. It applies pending
database migrations before switching traffic.

## Custom domain (e.g. votewala.in)

1. Cloud Run → *votewala* → **Manage custom domains** → add the domain and create the
   DNS records it shows. (Or put a global HTTPS load balancer with a serverless NEG
   in front, if you also want Cloud Armor / CDN.)
2. Set `PUBLIC_URL="https://votewala.in"` in `config.env` and re-run `deploy.sh`.
   This updates `NEXTAUTH_URL` and the scheduler target.
3. Add `https://votewala.in/api/auth/callback/google` to the OAuth client.

## Changing secrets later

```bash
printf '%s' 'NEW_VALUE' | gcloud secrets versions add votewala-msg91-auth-key --data-file=-
bash deploy/gcp/deploy.sh   # new revision picks up :latest
```

## Costs and sizing (rough, asia-south1)

| Resource | Default | Notes |
| --- | --- | --- |
| Cloud SQL | `db-g1-small`, 10 GB SSD, backups | Roughly US$30–40/month. `db-f1-micro` is cheaper for testing; move to `db-custom-2-7680` or larger for election-day traffic. |
| Cloud Run | 1 vCPU / 1 GiB, 0–20 instances | Pay per request. `MIN_INSTANCES=1` removes cold starts (~US$15–25/month extra). |
| Scheduler, Secret Manager, Artifact Registry, Cloud Build | — | Small; within or near the free tiers. |

Check current prices in the GCP pricing calculator. Set a **budget alert** under
Billing → Budgets.

For heavy traffic: raise `MAX_INSTANCES`, upgrade the SQL tier, and keep Cloud
Run's connection count below Cloud SQL's limit (instances × Prisma pool size ≤
`max_connections`). If needed, add `&connection_limit=5` to the database URL secret.

## Operations

- **Logs:** Cloud Run → votewala → Logs (OTP send failures and errors appear here).
- **Backups:** daily, kept 14 days, plus point-in-time recovery. The instance has
  deletion protection.
- **Rollback:** Cloud Run → Revisions → route traffic to an earlier revision.
  Migrations only add things; restore from a backup if a migration has to be undone.
- **Finalisation:** Cloud Scheduler job `votewala-finalize`; "Force run" to trigger it manually.

---

## తెలుగులో సంక్షిప్తంగా

1. GCP ప్రాజెక్ట్‌లో billing ఆన్ చేయండి. Google OAuth client మరియు MSG91/Twilio (DLT తో) సిద్ధం చేసుకోండి.
2. Cloud Shell తెరిచి repo clone చేయండి. `VW.png`ని `brand/VW.png`గా పెట్టండి.
3. `deploy/gcp/config.example.env`ని `config.env`గా కాపీ చేసి PROJECT_ID, GOOGLE_CLIENT_ID, ADMIN_EMAILS నింపండి.
4. `bash deploy/gcp/setup.sh` ఒకసారి, తర్వాత `bash deploy/gcp/deploy.sh` రన్ చేయండి.
5. చివర్లో వచ్చే redirect URIని Google OAuth clientలో జోడించండి. ADMIN_EMAILSలోని ఖాతాతో లాగిన్ అయి /adminలో అభ్యర్థులను import చేయండి.
