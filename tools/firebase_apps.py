"""Print the Firebase app IDs the Flutter apps need, registering the Android
app (with the test key's fingerprints) when it is missing.

Credentials: the service-account JSON in the FIREBASE_SERVICE_ACCOUNT
environment variable. Nothing is deployed.

    python3 tools/firebase_apps.py
"""
import json
import os
import sys
import time

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = "votewala-a2dcd"
PACKAGE = "com.votewala.votewala"
# android/app/votewala-test.jks
SHAS = [
    ("SHA_1", "fbc37668cc2476a20446e6a3bfbdff05f90d7ebb"),
    ("SHA_256", "5a9027bbf6144375ad96a25a7b9657c74366f766342cae5f0798ab88e07f96f0"),
]
API = f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"


def call(method, url, **kw):
    r = s.request(method, url, **kw)
    if r.status_code >= 300:
        print(f"::error::{method} {url} -> {r.status_code}\n{r.text[:1500]}")
        sys.exit(1)
    return r.json() if r.text else {}


def wait(op):
    while not op.get("done"):
        time.sleep(2)
        op = call("GET", f"https://firebase.googleapis.com/v1beta1/{op['name']}")
    return op.get("response", {})


web = call("GET", f"{API}/webApps").get("apps", [])
for app in web:
    cfg = call("GET", f"{API}/webApps/{app['appId']}/config")
    print("WEB", app.get("displayName"), json.dumps(cfg))

android = [a for a in call("GET", f"{API}/androidApps").get("apps", []) if a.get("packageName") == PACKAGE]
if not android:
    print("Registering Android app", PACKAGE)
    android = [wait(call("POST", f"{API}/androidApps", json={"packageName": PACKAGE, "displayName": "VoteWala Android"}))]
app = android[0]
print("ANDROID", json.dumps(app))

have = {c["shaHash"].lower() for c in call("GET", f"{API}/androidApps/{app['appId']}/sha").get("certificates", [])}
for kind, sha in SHAS:
    if sha not in have:
        call("POST", f"{API}/androidApps/{app['appId']}/sha", json={"shaHash": sha, "certType": kind})
        print("Added", kind)
print("ANDROID_CONFIG", json.dumps(call("GET", f"{API}/androidApps/{app['appId']}/config")))
