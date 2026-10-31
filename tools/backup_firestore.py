"""Daily Firestore backup: a managed export to a private Cloud Storage bucket.

Creates the bucket (Mumbai, private, exports deleted after 30 days) on the
first run. Restore with: gcloud firestore import gs://<bucket>/<date>

Credentials: the service-account JSON in FIREBASE_SERVICE_ACCOUNT. It needs
the "Cloud Datastore Import Export Admin" and "Storage Admin" roles.
"""
import datetime
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = "votewala-a2dcd"
BUCKET = f"{PROJECT}-backups"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"


def fail(what, r):
    sys.exit(f"{what} failed: {r.status_code} {r.text[:800]}\n"
             "Give the service account the roles named at the top of tools/backup_firestore.py.")


r = s.get(f"https://storage.googleapis.com/storage/v1/b/{BUCKET}")
if r.status_code == 404:
    r = s.post("https://storage.googleapis.com/storage/v1/b", params={"project": PROJECT}, json={
        "name": BUCKET,
        "location": "ASIA-SOUTH1",
        "storageClass": "STANDARD",
        "iamConfiguration": {"uniformBucketLevelAccess": {"enabled": True}, "publicAccessPrevention": "enforced"},
        "lifecycle": {"rule": [{"action": {"type": "Delete"}, "condition": {"age": 30}}]},
    })
    if r.status_code >= 300:
        fail("Creating the backup bucket", r)
    print("Created bucket", BUCKET)
elif r.status_code >= 300:
    fail("Checking the backup bucket", r)

prefix = f"gs://{BUCKET}/{datetime.datetime.now(datetime.timezone.utc):%Y-%m-%d}"
r = s.post(f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default):exportDocuments",
           json={"outputUriPrefix": prefix})
if r.status_code >= 300:
    fail("Starting the export", r)
print("Export started:", prefix, r.json().get("name"))
