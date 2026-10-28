#!/usr/bin/env bash
# Builds, migrates and deploys VoteWala to Cloud Run. Run after setup.sh, from
# the repository root in Cloud Shell:  bash deploy/gcp/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
source deploy/gcp/config.env
gcloud config set project "$PROJECT_ID" >/dev/null

[ -f brand/VW.png ] || { echo "✖ brand/VW.png (official logo) is missing — the build requires it."; exit 1; }

RUN_SA="votewala-run@${PROJECT_ID}.iam.gserviceaccount.com"
BUILD_SA="votewala-build@${PROJECT_ID}.iam.gserviceaccount.com"
CONN="${PROJECT_ID}:${REGION}:${SQL_INSTANCE}"
REPO="${REGION}-docker.pkg.dev/${PROJECT_ID}/votewala"
TAG="$(git rev-parse --short HEAD 2>/dev/null || echo manual)-$(date +%Y%m%d%H%M%S)"
step() { printf '\n\033[1;33m▶ %s\033[0m\n' "$*"; }

step "Building images ($TAG)"
gcloud builds submit . --region="$REGION" --config=deploy/gcp/cloudbuild.yaml \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA}" \
  --substitutions="_REPO=${REPO},_TAG=${TAG}"

step "Running database migrations"
gcloud run jobs deploy votewala-migrate --image="${REPO}/migrate:${TAG}" --region="$REGION" \
  --service-account="$RUN_SA" --set-cloudsql-instances="$CONN" \
  --set-secrets="DATABASE_URL=votewala-database-url:latest" \
  --max-retries=0 --task-timeout=900s --memory=1Gi
gcloud run jobs execute votewala-migrate --region="$REGION" --wait

SECRETS="DATABASE_URL=votewala-database-url:latest,NEXTAUTH_SECRET=votewala-nextauth-secret:latest,OTP_SECRET=votewala-otp-secret:latest,CRON_SECRET=votewala-cron-secret:latest,GOOGLE_CLIENT_SECRET=votewala-google-client-secret:latest"
case "$SMS_PROVIDER" in
  twilio) SECRETS+=",TWILIO_AUTH_TOKEN=votewala-twilio-auth-token:latest" ;;
  msg91) SECRETS+=",MSG91_AUTH_KEY=votewala-msg91-auth-key:latest" ;;
esac

URL="$PUBLIC_URL"
[ -n "$URL" ] || URL=$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)' 2>/dev/null || true)

# "^|^" switches the list delimiter so values such as ADMIN_EMAILS may contain commas.
ENV_VARS="^|^NEXTAUTH_URL=${URL:-https://pending.invalid}|GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}|SMS_PROVIDER=${SMS_PROVIDER}|ADMIN_EMAILS=${ADMIN_EMAILS}|RESULTS_MIN_SAMPLE=${RESULTS_MIN_SAMPLE}|RESULTS_BLACKOUT=${RESULTS_BLACKOUT}|TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}|TWILIO_FROM_NUMBER=${TWILIO_FROM_NUMBER}|MSG91_TEMPLATE_ID=${MSG91_TEMPLATE_ID}"

step "Deploying Cloud Run service"
gcloud run deploy "$SERVICE" --image="${REPO}/web:${TAG}" --region="$REGION" \
  --service-account="$RUN_SA" --add-cloudsql-instances="$CONN" \
  --allow-unauthenticated --port=3000 --cpu=1 --memory=1Gi --concurrency=80 \
  --min-instances="$MIN_INSTANCES" --max-instances="$MAX_INSTANCES" \
  --set-env-vars="$ENV_VARS" --set-secrets="$SECRETS"

if [ -z "$URL" ]; then # first deploy: the run.app URL is known only now
  URL=$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')
  gcloud run services update "$SERVICE" --region="$REGION" --update-env-vars="NEXTAUTH_URL=${URL}"
fi

step "Scheduling end-of-day finalisation (every 10 minutes)"
CRON_SECRET=$(gcloud secrets versions access latest --secret=votewala-cron-secret)
SCHED=(--location="$REGION" --schedule="*/10 * * * *" --time-zone="Asia/Kolkata"
  --uri="${URL}/api/cron/finalize" --http-method=POST)
if gcloud scheduler jobs describe votewala-finalize --location="$REGION" >/dev/null 2>&1; then
  gcloud scheduler jobs update http votewala-finalize "${SCHED[@]}" --update-headers="Authorization=Bearer ${CRON_SECRET}" >/dev/null
else
  gcloud scheduler jobs create http votewala-finalize "${SCHED[@]}" --headers="Authorization=Bearer ${CRON_SECRET}" >/dev/null
fi

step "Live at ${URL}"
echo "Google OAuth redirect URI to register: ${URL}/api/auth/callback/google"
