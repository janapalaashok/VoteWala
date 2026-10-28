#!/usr/bin/env bash
# One-time Google Cloud setup for VoteWala. Safe to re-run: existing resources are kept.
# Run from the repository root in Cloud Shell:  bash deploy/gcp/setup.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
source deploy/gcp/config.env

: "${PROJECT_ID:?set PROJECT_ID in deploy/gcp/config.env}"
gcloud config set project "$PROJECT_ID" >/dev/null
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
RUN_SA="votewala-run@${PROJECT_ID}.iam.gserviceaccount.com"
BUILD_SA="votewala-build@${PROJECT_ID}.iam.gserviceaccount.com"
CONN="${PROJECT_ID}:${REGION}:${SQL_INSTANCE}"

step() { printf '\n\033[1;33m▶ %s\033[0m\n' "$*"; }
secret_exists() { gcloud secrets describe "$1" >/dev/null 2>&1; }
put_secret() { # name value
  if secret_exists "$1"; then
    printf '%s' "$2" | gcloud secrets versions add "$1" --data-file=- >/dev/null
  else
    printf '%s' "$2" | gcloud secrets create "$1" --replication-policy=automatic --data-file=- >/dev/null
  fi
  echo "  stored $1"
}
ask_secret() { # name prompt
  if secret_exists "$1"; then echo "  $1 already set (gcloud secrets versions add $1 to change it)"; return; fi
  local v; read -rsp "  $2: " v; echo
  [ -n "$v" ] || { echo "  ✖ $1 is required"; exit 1; }
  put_secret "$1" "$v"
}

step "Enabling APIs"
gcloud services enable run.googleapis.com sqladmin.googleapis.com secretmanager.googleapis.com \
  artifactregistry.googleapis.com cloudbuild.googleapis.com cloudscheduler.googleapis.com iam.googleapis.com

step "Artifact Registry repository"
gcloud artifacts repositories describe votewala --location="$REGION" >/dev/null 2>&1 || \
  gcloud artifacts repositories create votewala --repository-format=docker --location="$REGION"

step "Service accounts"
gcloud iam service-accounts describe "$RUN_SA" >/dev/null 2>&1 || \
  gcloud iam service-accounts create votewala-run --display-name="VoteWala Cloud Run runtime"
gcloud iam service-accounts describe "$BUILD_SA" >/dev/null 2>&1 || \
  gcloud iam service-accounts create votewala-build --display-name="VoteWala Cloud Build"
for role in roles/cloudsql.client roles/secretmanager.secretAccessor; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$RUN_SA" --role="$role" --condition=None >/dev/null
done
for role in roles/artifactregistry.writer roles/logging.logWriter roles/storage.objectViewer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$BUILD_SA" --role="$role" --condition=None >/dev/null
done

step "Cloud SQL (PostgreSQL 16) — first creation takes ~10 minutes"
if ! gcloud sql instances describe "$SQL_INSTANCE" >/dev/null 2>&1; then
  gcloud sql instances create "$SQL_INSTANCE" \
    --database-version=POSTGRES_16 --edition=ENTERPRISE --tier="$DB_TIER" --region="$REGION" \
    --storage-type=SSD --storage-auto-increase \
    --backup-start-time=20:30 --enable-point-in-time-recovery --retained-backups-count=14 \
    --deletion-protection
fi
gcloud sql databases describe votewala --instance="$SQL_INSTANCE" >/dev/null 2>&1 || \
  gcloud sql databases create votewala --instance="$SQL_INSTANCE"
if ! secret_exists votewala-database-url; then
  DB_PASS=$(openssl rand -hex 24)
  if gcloud sql users list --instance="$SQL_INSTANCE" --format='value(name)' | grep -qx votewala; then
    gcloud sql users set-password votewala --instance="$SQL_INSTANCE" --password="$DB_PASS"
  else
    gcloud sql users create votewala --instance="$SQL_INSTANCE" --password="$DB_PASS"
  fi
  put_secret votewala-database-url "postgresql://votewala:${DB_PASS}@localhost/votewala?host=/cloudsql/${CONN}"
fi

step "Application secrets"
secret_exists votewala-nextauth-secret || put_secret votewala-nextauth-secret "$(openssl rand -base64 32)"
secret_exists votewala-otp-secret || put_secret votewala-otp-secret "$(openssl rand -base64 32)"
secret_exists votewala-cron-secret || put_secret votewala-cron-secret "$(openssl rand -hex 32)"
ask_secret votewala-google-client-secret "Google OAuth client secret"
case "$SMS_PROVIDER" in
  twilio) ask_secret votewala-twilio-auth-token "Twilio auth token" ;;
  msg91) ask_secret votewala-msg91-auth-key "MSG91 auth key" ;;
  *) echo "  ✖ SMS_PROVIDER must be twilio or msg91"; exit 1 ;;
esac

step "Done"
echo "Next: put the official logo at brand/VW.png, then run: bash deploy/gcp/deploy.sh"
