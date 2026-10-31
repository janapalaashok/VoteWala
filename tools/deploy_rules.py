"""Publish firestore.rules and storage.rules with the Firebase Rules REST API.

Needs the service account in FIREBASE_SERVICE_ACCOUNT with the "Firebase
Rules Admin" role. Prints the previous ruleset of each service so a release
can be rolled back (see docs/DEPLOYMENT.md).

    python3 tools/deploy_rules.py [project-id] [storage-bucket]
"""
import json
import os
import sys
from pathlib import Path

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = sys.argv[1] if len(sys.argv) > 1 else "votewala-a2dcd"
BUCKET = sys.argv[2] if len(sys.argv) > 2 else "votewala-a2dcd.firebasestorage.app"
API = f"https://firebaserules.googleapis.com/v1/projects/{PROJECT}"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/firebase", "https://www.googleapis.com/auth/cloud-platform"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"


class Failed(Exception):
    pass


def check(r):
    if r.status_code >= 300:
        raise Failed(f"{r.request.method} {r.url} -> {r.status_code}\n{r.text[:2000]}")
    return r.json() if r.text else {}


def publish(release, file):
    content = Path(file).read_text()
    ruleset = check(s.post(f"{API}/rulesets", json={"source": {"files": [{"name": file, "content": content}]}}))["name"]
    name = f"projects/{PROJECT}/releases/{release}"
    current = s.get(f"https://firebaserules.googleapis.com/v1/{name}")
    if current.status_code == 200:
        print(f"{release}: previous ruleset {current.json().get('rulesetName')}")
        check(s.patch(f"https://firebaserules.googleapis.com/v1/{name}",
                      json={"release": {"name": name, "rulesetName": ruleset}}))
    else:
        check(s.post(f"{API}/releases", json={"name": name, "rulesetName": ruleset}))
    print(f"{release}: now {ruleset}")


try:
    publish("cloud.firestore", "firestore.rules")
except Failed as e:
    sys.exit(f"Firestore rules NOT published:\n{e}")
try:
    publish(f"firebase.storage/{BUCKET}", "storage.rules")
except Failed as e:
    # Storage needs the Blaze plan; photo uploads stay off until it is enabled.
    print(f"::warning::Storage rules not published (is Storage enabled?): {e}")
