"""Reset an admin's password to a temporary one chosen by the owner.

The temporary password comes from the ADMIN_RESET_PASSWORD GitHub secret, so
it never appears in the code, the logs or a chat. The admin signs in at
<site>/#/admin with it and must set a new password straight away.

Credentials: FIREBASE_SERVICE_ACCOUNT, ADMIN_RESET_PASSWORD.
Optional: ADMIN_USERNAME (default "admin").

    python3 tools/reset_admin_password.py
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = "votewala-a2dcd"
USERNAME = (os.environ.get("ADMIN_USERNAME") or "admin").strip().lower()
EMAIL = f"{USERNAME}@admin.votewala.in"  # see FirebaseRest.loginEmail
PASSWORD = os.environ.get("ADMIN_RESET_PASSWORD", "")

if len(PASSWORD) < 6:
    sys.exit("Add the GitHub secret ADMIN_RESET_PASSWORD (at least 6 characters) first.")

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
        sys.exit(f"{r.request.method} {r.url.split('?')[0]} -> {r.status_code}\n{r.text[:800]}")
    return r.json() if r.text else {}


users = check(s.post(f"{AUTH}/accounts:lookup", json={"email": [EMAIL]})).get("users", [])
if not users:
    sys.exit(f"No admin with the username '{USERNAME}'.")
uid = users[0]["localId"]
if s.get(f"{DOCS}/admins/{uid}").status_code != 200:
    sys.exit(f"'{USERNAME}' is not on the admin team.")

# New password; signs the account out everywhere else.
check(s.post(f"{AUTH}/accounts:update", json={"localId": uid, "password": PASSWORD, "disableUser": False}))
check(s.patch(f"{DOCS}/admins/{uid}", params={"updateMask.fieldPaths": "mustChangePassword"},
              json={"fields": {"mustChangePassword": {"booleanValue": True}}}))
print(f"Password for '{USERNAME}' reset to the ADMIN_RESET_PASSWORD secret. "
      "Sign in at https://votewala.in/#/admin and set a new password.")
