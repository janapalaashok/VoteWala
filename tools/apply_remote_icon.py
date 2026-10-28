"""Before an app build: if the admin uploaded an app icon, download it to
brand/app-icon-override.png so make_brand_assets.py uses it.

Needs FIREBASE_API_KEY and FIREBASE_PROJECT_ID in the environment; does
nothing without them.
"""
import json
import os
import urllib.request

key, project = os.environ.get("FIREBASE_API_KEY"), os.environ.get("FIREBASE_PROJECT_ID")
if not key or not project:
    print("Firebase not configured; using bundled icon")
    raise SystemExit(0)

url = f"https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/config/app?key={key}"
try:
    with urllib.request.urlopen(url, timeout=30) as r:
        doc = json.load(r)
except Exception as e:  # no published config yet
    print("No published config:", e)
    raise SystemExit(0)

config = json.loads(doc["fields"]["json"]["stringValue"])
icon = config.get("branding", {}).get("appIconUrl")
if not icon or icon.startswith("data:"):
    print("No uploaded app icon; using bundled icon")
    raise SystemExit(0)

with urllib.request.urlopen(icon, timeout=60) as r, open("brand/app-icon-override.png", "wb") as f:
    f.write(r.read())
print("Using admin app icon from", icon)
