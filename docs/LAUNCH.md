# VoteWala launch checklist

## Hosting at a glance
| Address | Served by | Notes |
|---|---|---|
| **https://votewala.in** | Firebase Hosting (Google's global CDN, part of the same Google Cloud project) | Main address. `www.votewala.in` redirects here. Free SSL. |
| https://votewala-a2dcd.web.app | Firebase Hosting | Same site (no longer the old demo). |
| https://votewala-596383314349.asia-south1.run.app | Cloud Run, Mumbai | Same site; kept up to date as a backup. |

Cloud Run in Mumbai cannot attach a custom domain without a paid load balancer
(about ₹1,500/month), so votewala.in is served from Firebase Hosting for free.
Database, login and photos are the same Google Cloud services either way.

Every release (`hosting/RELEASE` changed) publishes all three, built with the
address in `hosting/SITE_URL` so share links and QR codes point to votewala.in.

## Done
- Website, mobile website and Android app with Google + email sign-in, one vote
  per person per poll enforced by the database rules.
- Admin panel at `/#/admin`: content, polls, candidates, local issues, photo
  review, grievances + PDF, analytics, users (block / unblock), admins, legal
  pages, settings, profile and password.
- Legal pages with public addresses (`/#/legal/privacy`, `/#/legal/terms`, ...).
- Link previews (title, description, image) for WhatsApp, Facebook, X.
- votewala.in connected on the Firebase side and allowed for sign-in.
- Daily database backup to a private bucket (30 days kept).

## Owner: before announcing
1. **DNS** at the domain registrar (where you bought votewala.in):

   | Type | Name / Host | Value | Action |
   |---|---|---|---|
   | A | @ (votewala.in) | `199.36.158.100` | add |
   | TXT | @ (votewala.in) | `hosting-site=votewala-a2dcd` | add |
   | A | @ | `15.197.148.33` | delete (registrar parking) |
   | A | @ | `3.33.130.190` | delete (registrar parking) |
   | CNAME | www | `votewala-a2dcd.web.app` | add / replace the existing www record |

   SSL is issued automatically, usually within 1–24 hours. Check with
   Actions → "Connect domain" → Run workflow (prints the status).
2. **Admin password**: sign in at https://votewala.in/#/admin with `admin` and
   the starting password, set your own password, then add other admins
   (Admins page) instead of sharing yours.
3. **Google sign-in screen** (Google Cloud → APIs & Services → OAuth consent
   screen / Branding): set the home page `https://votewala.in`, privacy policy
   `https://votewala.in/#/legal/privacy`, terms `https://votewala.in/#/legal/terms`,
   and add `votewala.in` under Authorized domains.
4. **Email templates** (Firebase → Authentication → Templates): sender name
   "VoteWala", reply-to `contact@votewala.in`.
5. **contact@votewala.in** must receive mail (the legal pages list it).
6. Test once more on votewala.in after DNS is live: Google sign-in, email
   sign-up, a vote, a share link from a phone (WhatsApp preview).

7. **Backups**: Google Cloud → IAM → the `firebase-adminsdk-…` service account
   → add the role **Cloud Datastore Import Export Admin**. The backup bucket
   `votewala-a2dcd-backups` already exists; the nightly "Daily backup" workflow
   starts working once the role is added (until then it reports a failure).

## Owner: right after launch
- Budget alert (Google Cloud → Billing → Budgets) if not done.
- Uptime check (Google Cloud → Monitoring → Uptime checks → `https://votewala.in`, alert to your email).
- Watch the admin panel daily for threshold alerts, photos to review and blocked users.
- Lawyer review of the legal pages (edit them in Admin → Legal pages).
- Delete the unused Google Cloud project "VoteWala" (number 579871497318).

## Later
- Play Store: Google Play Console account, a release signing key (the current one
  is for testing only), Data safety form, privacy link.
- iPhone app: Apple Developer account.
- Mobile OTP login: Blaze + Phone sign-in, then build with `--dart-define=PHONE_LOGIN=true`.
