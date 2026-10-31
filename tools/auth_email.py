"""Configure the sign-in emails (verification, password reset, email change).

- Sender name "VoteWala", replies go to contact@votewala.in.
- Links in the emails open https://votewala.in/__/auth/action.
- If SMTP_PASSWORD is set (GitHub secret), the emails are sent through the
  contact@votewala.in mailbox itself (GoDaddy SMTP), so they come FROM
  contact@votewala.in.

Credentials: FIREBASE_SERVICE_ACCOUNT. Optional: SMTP_PASSWORD, SMTP_HOST,
SMTP_PORT, SMTP_SECURITY (SSL or START_TLS), SENDER_EMAIL.

    python3 tools/auth_email.py
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROJECT = "votewala-a2dcd"
SITE = os.environ.get("SITE_URL", "https://votewala.in").rstrip("/")
SENDER = os.environ.get("SENDER_EMAIL") or "contact@votewala.in"
NAME = "VoteWala"

creds = service_account.Credentials.from_service_account_info(
    json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"]),
    scopes=["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase"],
)
creds.refresh(Request())
s = requests.Session()
s.headers["Authorization"] = f"Bearer {creds.token}"
CONFIG = f"https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config"

TEMPLATES = ("verifyEmailTemplate", "resetPasswordTemplate", "changeEmailTemplate")
body = {"notification": {"sendEmail": {"callbackUri": f"{SITE}/__/auth/action"}}}
mask = ["notification.sendEmail.callbackUri"]
for t in TEMPLATES:
    body["notification"]["sendEmail"][t] = {"senderDisplayName": NAME, "replyTo": SENDER}
    mask += [f"notification.sendEmail.{t}.senderDisplayName", f"notification.sendEmail.{t}.replyTo"]

password = os.environ.get("SMTP_PASSWORD", "")
if password:
    body["notification"]["sendEmail"]["method"] = "CUSTOM_SMTP"
    body["notification"]["sendEmail"]["smtp"] = {
        "senderEmail": SENDER,
        "host": os.environ.get("SMTP_HOST") or "smtpout.secureserver.net",
        "port": int(os.environ.get("SMTP_PORT") or 465),
        "username": SENDER,
        "password": password,
        "securityMode": os.environ.get("SMTP_SECURITY") or "SSL",
    }
    mask += ["notification.sendEmail.method", "notification.sendEmail.smtp"]
else:
    print("SMTP_PASSWORD not set: emails keep Google's sender address (noreply@...firebaseapp.com),"
          f" with sender name {NAME} and replies to {SENDER}.")

r = s.patch(CONFIG, params={"updateMask": ",".join(mask)}, json=body)
if r.status_code != 200:
    sys.exit(f"Update failed: {r.status_code}\n{r.text[:2000]}")

send = r.json().get("notification", {}).get("sendEmail", {})
smtp = send.get("smtp", {})
print("method:", send.get("method", "DEFAULT"))
print("links open:", send.get("callbackUri"))
if smtp:
    print(f"SMTP: {smtp.get('senderEmail')} via {smtp.get('host')}:{smtp.get('port')} {smtp.get('securityMode')}")
for t in TEMPLATES:
    tpl = send.get(t, {})
    print(f"{t}: name={tpl.get('senderDisplayName')!r} replyTo={tpl.get('replyTo')!r}")
