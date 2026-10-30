# VoteWala release guide

Nothing is published by a push. Every release step below is a manual GitHub Actions run
(Actions tab → choose the workflow → **Run workflow** → branch). Do them in this order.

## What this release adds
| Area | Where |
|---|---|
| Real phone OTP login (Google on the website) | `lib/services/firebase_auth_service.dart` |
| Votes, results, badges from Firestore (sample numbers removed) | `lib/services/vote_service.dart`, `lib/state/app_state.dart` |
| One vote per user per poll, counts and badges enforced by the database | `firestore.rules` (tests: `test/rules`) |
| Badges & achievements | `lib/data/civic.dart`, `lib/screens/achievements_screen.dart` |
| Share card: question, optional "my choice", WhatsApp, download, copy link | `lib/widgets/share_card.dart` |
| Your Constituency: GOOD/BAD feedback, evidence photos, "If you were the MLA" | `lib/screens/my_constituency_screen.dart` |
| People's Priorities dashboard | `lib/screens/priorities_dashboard_screen.dart` |
| Admin: local issues & alerts, photo review, grievances + PDF, analytics, settings | `lib/admin/pages/*` |

## Before the first release (one time)
Follow `docs/FIREBASE_SETUP.md` steps 7 and 8: Blaze plan, Phone sign-in, Play Integrity
API, Storage, budget alert, and the **Firebase Rules Admin** role for the service account.

## Release steps
1. **Check CI is green** on the commit (Build workflow: rule tests, app tests, APK build).
2. **Deploy security rules** workflow. The new app needs the new rules; the old website keeps
   working with them (it only reads `config/app`).
3. **Settings documents (optional)**: admin panel → *Issues, badges & sharing* → set
   thresholds → **Save thresholds & milestones**. Without them, rules use the defaults
   (threshold 100, badges 1/5/10/25/50/100).
4. **Deploy website (Cloud Run)** workflow (see `docs/GCP_HOSTING.md`), or the Firebase
   Hosting **Deploy website** workflow.
5. **Build** workflow (Run workflow) to replace the testers' APK
   (`releases/download/test-build/VoteWala.apk`).
6. Smoke test: sign in with OTP on the website and the APK, vote once in an MLA poll, try a
   second vote (must be refused), submit local feedback with a photo, open the admin panel →
   *Photo review* and approve it, generate a PDF from *Local issues & alerts*.

## Data migration
No existing data is changed. Before this release only `config/app` and `admins/*` existed in
Firestore; new collections (`votes`, `tallies`, `users`, `photos`, `alerts`, `grievances`,
`otherIssues`, `settings`) are created by use. Votes previously stored on phones (demo
login) are not imported: they were not tied to verified accounts. The admin config gains a
`civic` section; older documents load with defaults.

Indexes: none to create. All queries are single-collection lists or a count on
`users.voteCount`, which Firestore indexes automatically.

## Configuration
Public identifiers are compiled in as defaults (override with `--dart-define`):

| Name | Default |
|---|---|
| `FIREBASE_API_KEY` | web API key of `votewala-a2dcd` |
| `FIREBASE_PROJECT_ID` | `votewala-a2dcd` |
| `FIREBASE_STORAGE_BUCKET` | `votewala-a2dcd.firebasestorage.app` |
| `FIREBASE_WEB_APP_ID` | `1:596383314349:web:719240a1d80d3b14097124` |
| `FIREBASE_ANDROID_APP_ID` / `FIREBASE_ANDROID_API_KEY` | the registered Android app |
| `VOTEWALA_DEMO` | `false`; `true` builds an offline UI-review site (fake sign-in, in-memory votes). Never deploy it. |

Secrets (GitHub → Settings → Secrets → Actions): `FIREBASE_SERVICE_ACCOUNT` only.

## Rollback
- **Website**: Firebase console → Hosting → *Release history* → previous release →
  **Rollback** (instant).
- **Security rules**: the deploy log prints the previous ruleset for each service. Firebase
  console → Firestore/Storage → *Rules* → history → select the previous version → **Publish**.
  Roll back rules only together with the website and app, because the new app needs them.
- **App**: create a tag on the previous commit (GitHub → Releases/Tags) and run the Build
  workflow on that tag to republish the earlier test APK. Installed apps keep working against
  the rules they were built for.
- **Admin settings**: *Publish & backup → Import* a JSON exported before the change.
- **Votes**: ballots are immutable by design and are never rolled back.

## Costs to expect
- Phone OTP SMS: charged per SMS (see Firebase pricing for India). Budget alert recommended.
- Firestore: results pages read one small document per constituency; a statewide view reads
  up to 175 documents. At 10,000 statewide views a day that is about 1.75M reads, a few
  dollars a month. Counts are cached in the app for 2 minutes.
- Storage: photos are resized to at most 1280 px (~200 KB). 10,000 photos ≈ 2 GB, within
  the free 5 GB.
