# Connect the admin panel to Firebase (≈ 10 minutes)

The admin panel (`https://<website>/#/admin`) saves everything — branding, colours,
logos, parties, candidate names & photos, constituency names, featured polls and home
page content — into **one Firebase document**. The Android/iOS app and the website read
it on every launch. Until Firebase is connected, the panel runs in **demo mode**
(changes stay in that browser).

> తెలుగు సారాంశం: Firebase project create చేసి, admin user add చేసి, rules paste చేసి,
> 3 keys (API key, Project ID, Storage bucket) GitHub secrets లో పెట్టండి. అంతే — admin
> panel లో Publish చేసిన మార్పులు app మరియు website లో వెంటనే కనిపిస్తాయి.

## 1. Create the project
1. Open <https://console.firebase.google.com> → **Add project** → name it `votewala`.
2. Google Analytics is optional.

## 2. Admin login (Authentication)
1. **Build → Authentication → Get started → Email/Password → Enable**.
2. **Users → Add user**: the admin's email + a strong password.
3. Copy the new user's **User UID**.

## 3. Database (Firestore)
1. **Build → Firestore Database → Create database** → production mode → location
   `asia-south1 (Mumbai)`.
2. **Rules** tab → paste the contents of [`firestore.rules`](../firestore.rules) → **Publish**.
3. **Data** tab → **Start collection** → ID `admins` → Document ID = the **UID** from step 2.3
   → add a field `role` = `owner` → Save. Repeat for every admin.

## 4. Photos & logos (Storage)
1. **Build → Storage → Get started** (new projects need the pay-as-you-go *Blaze* plan for
   Storage; usage at VoteWala's size stays within the free allowance).
2. **Rules** tab → paste [`storage.rules`](../storage.rules) → **Publish**.
3. Allow the website to load images (once, in Google Cloud Shell):
   ```bash
   gsutil cors set storage-cors.json gs://<your-bucket>
   ```
   (upload `storage-cors.json` from this repo to Cloud Shell first).

## 5. Keys for the app
**Project settings → General → Your apps → Add app → Web (</>)**, then copy:
`apiKey`, `projectId`, `storageBucket`.

The VoteWala project's keys are already the defaults in
`lib/config/firebase_rest.dart` (they are public by design; security comes from the rules
above). To point a build at a different Firebase project, set these GitHub secrets / dart-defines:

**GitHub → repo → Settings → Secrets and variables → Actions → New repository secret**
- `FIREBASE_API_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`

The next push builds an APK connected to Firebase. To build locally:
```bash
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

## 6. Website hosting
The website (and its admin panel) is published to **https://votewala-a2dcd.web.app** by
`.github/workflows/deploy-web.yml` when you run it from the Actions tab (pushes never
deploy). One-time setup:
1. Firebase console → **Build → Hosting → Get started** → click through (skip the CLI steps).
2. ⚙️ **Project settings → Service accounts → Generate new private key** → downloads a JSON file.
3. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**:
   name `FIREBASE_SERVICE_ACCOUNT`, value = the whole JSON file content.
4. Run the "Deploy website" workflow (Actions tab).

The service-account key is a real secret: store it only in GitHub secrets, never in chat or code.

## 7. Voter login (phone OTP) and live votes
Votes, results, badges, local issues and grievances are stored in Firestore and checked by
`firestore.rules`. One-time setup (needs the **Blaze** plan: phone OTP SMS and Storage):
1. **Authentication → Sign-in method → Phone → Enable.** Optional: **Google → Enable** (website).
2. **Authentication → Settings → Authorized domains**: `votewala-a2dcd.web.app` and
   `votewala-a2dcd.firebaseapp.com` must be listed (they are by default).
3. Android app: already registered (`com.votewala.votewala`) with the test key's SHA-1/SHA-256
   by the "Firebase app IDs" workflow. For a Play Store build, add the release key's SHA-1 and
   SHA-256 in **Project settings → Your apps → Android**.
4. Google Cloud console → **APIs & Services → Library → "Play Integrity API" → Enable**
   (Android phone sign-in uses it; without it Android falls back to a reCAPTCHA page).
5. **Storage → Get started** (Blaze), then publish the rules (step 8).
6. Billing → **Budgets & alerts** → create a budget (e.g. ₹1,000/month) with email alerts.
   SMS for OTP is charged per message; Firestore and Storage stay in the free allowance at
   small scale.

## 8. Publish the security rules
Run **Actions → Deploy security rules** (manual). It runs the rule tests against the emulator
first, then publishes `firestore.rules` and `storage.rules`. The service account needs the
**Firebase Rules Admin** role (Google Cloud console → IAM → the
`firebase-adminsdk-…@…` account → add role). Alternatively paste both files in the console
(Firestore → Rules, Storage → Rules) and click Publish.

## Using the admin panel
1. Open `https://<website>/#/admin` and sign in with the admin email/password.
2. Edit anything; changes go into a **draft** (kept in your browser).
3. Click **Publish** — users get the changes the next time they open the app or website.
4. **Publish & backup → Export JSON** before big changes.

### What updates instantly vs. on the next app build
| Change | Website | Installed app |
|---|---|---|
| Colours, names, photos, polls, home content, logos | next page load | next app launch |
| App icon (home-screen icon) | – | next APK build (CI downloads it) |
