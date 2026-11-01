"""Diagnose admin image uploads: bucket, uploaded files, CORS, the Storage
rules' access to Firestore, and the image addresses in the published config.
Prints only; changes nothing.

    python3 tools/check_storage.py
"""
import json
import os
import re

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT, NUMBER = "votewala-a2dcd", "596383314349"
BUCKET = "votewala-a2dcd.firebasestorage.app"
creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"


def show(title, r):
    print(f"\n=== {title}: {r.status_code}")
    print(r.text[:2500])


show("bucket", s.get(f"https://storage.googleapis.com/storage/v1/b/{BUCKET}", params={"fields": "name,location,cors,iamConfiguration"}))
r = s.get(f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o", params={"fields": "items(name,size,contentType,updated)", "maxResults": 1000})
items = r.json().get("items", []) if r.ok else []
print(f"\n=== objects: {r.status_code}, {len(items)} files")
folders = {}
for it in items:
    folders.setdefault(it["name"].split("/")[0], []).append(it)
for f, its in sorted(folders.items()):
    latest = max(its, key=lambda x: x["updated"])
    print(f"  {f}: {len(its)} files, latest {latest['updated']} {latest['name']} ({latest['contentType']})")

pol = s.post(f"https://cloudresourcemanager.googleapis.com/v1/projects/{PROJECT}:getIamPolicy", json={})
print(f"\n=== project IAM: {pol.status_code}")
agent = f"service-{NUMBER}@gcp-sa-firebasestorage.iam.gserviceaccount.com"
if pol.ok:
    for b in pol.json().get("bindings", []):
        if any(agent in m for m in b["members"]) or "firebaserules" in b["role"]:
            print(" ", b["role"], [m for m in b["members"] if "gcp-sa" in m or "firebase" in m])
else:
    print(pol.text[:500])

doc = s.get(f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/config/app")
print(f"\n=== config/app: {doc.status_code}")
if doc.ok:
    text = json.dumps(doc.json())
    print("updateTime", doc.json().get("updateTime"))
    urls = sorted(set(re.findall(r'https?://[^"\\\\]+', text.replace('\\\\/', '/'))))
    data = [u for u in re.findall(r'data:image/[a-z]+', text)]
    print(f"{len(urls)} image/http addresses, {len(data)} data: images")
    for u in urls[:40]:
        try:
            h = requests.get(u, headers={"Origin": "https://votewala.in"}, timeout=15, stream=True)
            print(f"  {h.status_code} cors={h.headers.get('access-control-allow-origin')} {h.headers.get('content-type')} {u[:140]}")
        except Exception as e:  # noqa: BLE001
            print("  ERR", e, u[:140])
