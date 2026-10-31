"""Create the starting admin account (username "admin") if it does not exist.

The admin signs in at <site>/#/admin with username "admin" and the starting
password below, and must set a new password on the first sign-in. An existing
account is never changed, so re-running this is safe.

Credentials: the service-account JSON in FIREBASE_SERVICE_ACCOUNT.

    python3 tools/create_admin.py
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = "votewala-a2dcd"
EMAIL = "admin@admin.votewala.in"  # username "admin" (see FirebaseRest.loginEmail)
# Firebase requires at least 6 characters; changed on the first sign-in.
START_PASSWORD = "123456"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/datastore"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"
AUTH = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}"
DOCS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"


def check(r):
    if r.status_code >= 300:
        sys.exit(f"{r.request.method} {r.url} -> {r.status_code}\n{r.text[:1500]}")
    return r.json() if r.text else {}


users = check(s.post(f"{AUTH}/accounts:lookup", json={"email": [EMAIL]})).get("users", [])
if users:
    uid = users[0]["localId"]
    print("Admin account already exists:", uid)
else:
    uid = check(s.post(f"{AUTH}/accounts", json={
        "email": EMAIL, "password": START_PASSWORD, "displayName": "Admin", "emailVerified": True,
    }))["localId"]
    print("Created admin account:", uid)

existing = s.get(f"{DOCS}/admins/{uid}")
if existing.status_code == 200:
    print("admins document already exists; left unchanged")
else:
    check(s.patch(f"{DOCS}/admins/{uid}", json={"fields": {
        "role": {"stringValue": "owner"},
        "username": {"stringValue": "admin"},
        "displayName": {"stringValue": "Admin"},
        "mustChangePassword": {"booleanValue": True},
    }}))
    print("Added to admins (must change password on first sign-in)")
