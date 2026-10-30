# Website on Google Cloud Run

> తెలుగు సారాంశం: Firebase అంటే Google Cloud నే. Database (Firestore), login (Auth),
> photos (Storage) ఇప్పటికే మీ GCP project `votewala-a2dcd` లోనే ఉన్నాయి — వాటిని మార్చాల్సిన
> అవసరం లేదు, code అంతా అలాగే ఉంటుంది. మారేది website hosting మాత్రమే: Firebase Hosting
> బదులు Cloud Run (Mumbai). క్రింది steps ఒక్కసారి చేస్తే చాలు.

## What moves and what stays
| Part | Before | After |
|---|---|---|
| Website hosting | Firebase Hosting (`votewala-a2dcd.web.app`) | **Cloud Run** `votewala`, region `asia-south1` (Mumbai) |
| Database | Firestore (a Google Cloud service) | same, no change |
| Login (phone OTP, Google) | Firebase Authentication (Google Cloud Identity Platform) | same, no change |
| Photos, logos | Cloud Storage bucket `votewala-a2dcd.firebasestorage.app` | same, no change |
| App code, files, Android APK | | same, no change |

All of them already live in the Google Cloud project `votewala-a2dcd` (console.cloud.google.com).
Billing is the same Google Cloud billing account (Blaze).

New website address: **https://votewala-596383314349.asia-south1.run.app** (fixed by Cloud
Run), or your own domain (step 5).

## One-time setup
1. **Enable APIs** (console.cloud.google.com → APIs & Services → Enable):
   *Cloud Run Admin API* and *Artifact Registry API*.
2. **Service account for deploys.** IAM & Admin → IAM → the
   `firebase-adminsdk-…@votewala-a2dcd.iam.gserviceaccount.com` account (already in the GitHub
   secret `FIREBASE_SERVICE_ACCOUNT`) → **Edit** → add roles:
   - Cloud Run Admin
   - Artifact Registry Administrator
   - Service Account User

   (Or create a separate account with these roles and save its JSON key as the GitHub secret
   `GCP_SERVICE_ACCOUNT`; the workflow prefers it.)
3. **Allow sign-in from the new address.** Firebase console → Authentication → Settings →
   Authorized domains → **Add domain** → `votewala-596383314349.asia-south1.run.app`
   (and your custom domain if you use one). Without this, OTP and Google sign-in fail on the
   new site.
4. **Deploy:** GitHub → Actions → **Deploy website (Cloud Run)** → Run workflow. It builds the
   website, packs it into a small nginx container, pushes it to Artifact Registry and deploys
   Cloud Run. The last log line prints the address.
5. **Custom domain (optional, e.g. votewala.in):** Cloud Run → `votewala` → *Manage custom
   domains* → add the domain and set the DNS records it shows. Then run the workflow again
   with **site_url** = `https://votewala.in` so share links and QR codes use it.

## After the switch
- Share links/QR codes point to the address the site was built with (`site_url`). Android
  APKs built by the Build workflow keep linking to `votewala-a2dcd.web.app` unless built with
  `--dart-define=SITE_URL=...`; set it there too once the final address is decided.
- Keep Firebase Hosting until you are happy, so old shared links keep working. Later you can
  replace it with a redirect page or disable it (Firebase console → Hosting → *Disable site*).
- The old "Deploy website" (Firebase Hosting) workflow still works; use one or the other.

## Rollback
Cloud Run → `votewala` → **Revisions** → pick the previous revision → *Manage traffic* →
100% to it. Or switch users back to `votewala-a2dcd.web.app`, which is untouched.

## Cost
Cloud Run scales to zero; the free tier (2 million requests and 180,000 vCPU-seconds a
month) covers a small site. Static files are served from memory by nginx. Artifact Registry
stores each release image (~30 MB; 0.5 GB free). Delete old images there now and then.
