"""Diagnose votewala.in: DNS, HTTP/HTTPS responses and the Firebase Hosting
domain state. Prints only; changes nothing.

    python3 tools/check_site.py [domain]
"""
import json
import os
import socket
import subprocess
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

DOMAIN = sys.argv[1] if len(sys.argv) > 1 else "votewala.in"
PROJECT = SITE = "votewala-a2dcd"


def sh(cmd):
    print("$", cmd)
    print(subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout.strip() or "(none)")


print("=== DNS (public resolvers) ===")
for host in (DOMAIN, f"www.{DOMAIN}"):
    for rtype in ("A", "AAAA", "CNAME", "TXT"):
        for ns in ("8.8.8.8", "1.1.1.1"):
            sh(f"dig +short @{ns} {host} {rtype}")
sh(f"dig +short NS {DOMAIN}")
try:
    print("system resolver:", socket.gethostbyname_ex(DOMAIN))
except OSError as e:
    print("system resolver failed:", e)

print("\n=== HTTP responses ===")
for url in (f"http://{DOMAIN}/", f"https://{DOMAIN}/", f"https://www.{DOMAIN}/", f"https://{SITE}.web.app/"):
    try:
        r = requests.get(url, timeout=20, allow_redirects=False)
        title = r.text.split("<title>")[1].split("</title>")[0] if "<title>" in r.text else ""
        print(f"{url} -> {r.status_code} {r.headers.get('location', '')} title={title!r} server={r.headers.get('server')}")
    except Exception as e:  # noqa: BLE001
        print(f"{url} -> ERROR {e}")

print("\n=== Firebase Hosting domain state ===")
creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"
base = f"https://firebasehosting.googleapis.com/v1beta1/projects/{PROJECT}/sites/{SITE}"
for name in (DOMAIN, f"www.{DOMAIN}"):
    r = s.get(f"{base}/customDomains/{name}")
    d = r.json()
    d.get("cert", {}).pop("verification", None)
    print(name, json.dumps(d, indent=1)[:3000])
print("legacy domains:", s.get(f"https://firebasehosting.googleapis.com/v1beta1/sites/{SITE}/domains").text[:2000])
print("releases:", s.get(f"https://firebasehosting.googleapis.com/v1beta1/sites/{SITE}/releases", params={"pageSize": 2}).text[:1500])

print("\n=== From other countries (check-host.net) ===")
import time  # noqa: E402

try:
    nodes = requests.get("https://check-host.net/nodes/hosts", timeout=20).json()["nodes"]
    pick = [n for n, v in nodes.items() if v.get("location", [""])[0] in ("in", "sg", "ae", "jp")][:6]
    print("nodes:", pick)
    for url in (f"https://{DOMAIN}/", f"http://{DOMAIN}/"):
        q = "&".join(f"node={n}" for n in pick)
        req = requests.get(f"https://check-host.net/check-http?host={url}&{q}", headers={"Accept": "application/json"}, timeout=20).json()
        time.sleep(15)
        res = requests.get(f"https://check-host.net/check-result/{req['request_id']}", headers={"Accept": "application/json"}, timeout=20).json()
        for node, r in res.items():
            print(url, nodes[node]["location"][1:3], r)
except Exception as e:  # noqa: BLE001
    print("check-host failed:", e)
