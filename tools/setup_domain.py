"""Connect votewala.in (and www) to Firebase Hosting and allow sign-in there.

Prints the DNS records to add at the domain registrar. Safe to re-run: it
only adds what is missing and then shows the current status.

Credentials: the service-account JSON in FIREBASE_SERVICE_ACCOUNT.

    python3 tools/setup_domain.py [domain]
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = "votewala-a2dcd"
SITE = "votewala-a2dcd"
DOMAIN = sys.argv[1] if len(sys.argv) > 1 else "votewala.in"
WWW = f"www.{DOMAIN}"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"
HOSTING = f"https://firebasehosting.googleapis.com/v1beta1/projects/{PROJECT}/sites/{SITE}/customDomains"
AUTH = f"https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config"
problems = []


def add_domain(name, body):
    r = s.post(HOSTING, params={"customDomainId": name}, json=body)
    if r.status_code in (200, 201):
        print(f"Added {name} to Firebase Hosting")
    elif r.status_code == 409 or "ALREADY_EXISTS" in r.text:
        print(f"{name} is already connected")
    else:
        problems.append(f"Hosting {name}: {r.status_code} {r.text[:500]}")


add_domain(DOMAIN, {})
add_domain(WWW, {"redirectTarget": DOMAIN})

# Sign-in (Google popup, email links) must be allowed on the new domain.
r = s.get(AUTH)
if r.status_code == 200:
    domains = r.json().get("authorizedDomains", [])
    wanted = [d for d in (DOMAIN, WWW) if d not in domains]
    if wanted:
        u = s.patch(AUTH, params={"updateMask": "authorizedDomains"}, json={"authorizedDomains": domains + wanted})
        if u.status_code == 200:
            print("Authorized for sign-in:", ", ".join(wanted))
        else:
            problems.append(f"Authorized domains: {u.status_code} {u.text[:400]}")
    else:
        print("Sign-in already allowed on", DOMAIN)
else:
    problems.append(f"Auth config: {r.status_code} {r.text[:400]}")

print("\n=========== DNS RECORDS TO ADD AT YOUR DOMAIN REGISTRAR ===========")
for name in (DOMAIN, WWW):
    r = s.get(f"{HOSTING}/{name}")
    if r.status_code != 200:
        print(f"{name}: status unavailable ({r.status_code})")
        continue
    d = r.json()
    print(f"\n# {name}  host={d.get('hostState')}  ownership={d.get('ownershipState')}  cert={d.get('cert', {}).get('state')}")
    for rs in d.get("requiredDnsUpdates", {}).get("desired", []):
        for rec in rs.get("records", []):
            action = rec.get("requiredAction", "ADD")
            if action == "NONE":
                continue
            print(f"{action:7} {rec.get('type'):6} {rs.get('domainName'):40} {rec.get('rdata')}")
    for rs in d.get("requiredDnsUpdates", {}).get("discovered", []):
        for rec in rs.get("records", []):
            if rec.get("requiredAction") == "REMOVE":
                print(f"REMOVE  {rec.get('type'):6} {rs.get('domainName'):40} {rec.get('rdata')}")
print("====================================================================")

if problems:
    print("\nProblems:")
    for p in problems:
        print(" -", p)
    sys.exit(1)
