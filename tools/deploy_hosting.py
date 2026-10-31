"""Deploy build/web to Firebase Hosting via the Hosting REST API.

Only needs the firebasehosting.sites.update permission (unlike the Firebase
CLI, which also checks Service Usage). Credentials: the service-account JSON in
the FIREBASE_SERVICE_ACCOUNT environment variable.

    python3 tools/deploy_hosting.py [site-id] [public-dir]
"""
import gzip
import hashlib
import json
import os
import sys
from pathlib import Path

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

SITE = sys.argv[1] if len(sys.argv) > 1 else "votewala-a2dcd"
PUBLIC = Path(sys.argv[2] if len(sys.argv) > 2 else "build/web")
API = "https://firebasehosting.googleapis.com/v1beta1"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/firebase.hosting", "https://www.googleapis.com/auth/cloud-platform"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"


def check(r):
    if r.status_code >= 300:
        sys.exit(f"{r.request.method} {r.url} -> {r.status_code}\n{r.text[:2000]}")
    return r.json() if r.text else {}


config = {
    "headers": [
        # App code keeps fixed file names: browsers must check for a new
        # release every time (cheap: unchanged files answer 304).
        {"glob": "**/*.@(js|json|mjs)", "headers": {"Cache-Control": "no-cache"}},
        {"glob": "**/*.@(wasm|png|jpg|webp|otf|ttf)", "headers": {"Cache-Control": "public, max-age=3600"}},
        {"glob": "/index.html", "headers": {"Cache-Control": "no-cache"}},
        {"glob": "/", "headers": {"Cache-Control": "no-cache"}},
    ]
}
version = check(s.post(f"{API}/sites/{SITE}/versions", json={"config": config}))["name"]
print("version", version)

files, blobs = {}, {}
for path in sorted(p for p in PUBLIC.rglob("*") if p.is_file() and not p.name.startswith(".")):
    data = gzip.compress(path.read_bytes(), mtime=0)
    digest = hashlib.sha256(data).hexdigest()
    files["/" + path.relative_to(PUBLIC).as_posix()] = digest
    blobs[digest] = data
print(len(files), "files")

pop = check(s.post(f"{API}/{version}:populateFiles", json={"files": files}))
needed = pop.get("uploadRequiredHashes", [])
for i, h in enumerate(needed, 1):
    check(s.post(f"{pop['uploadUrl']}/{h}", data=blobs[h], headers={"Content-Type": "application/octet-stream"}))
print("uploaded", len(needed), "files")

check(s.patch(f"{API}/{version}", params={"update_mask": "status"}, json={"status": "FINALIZED"}))
release = check(s.post(f"{API}/sites/{SITE}/releases", params={"versionName": version}))
print("released", release.get("name"), "->", f"https://{SITE}.web.app")
