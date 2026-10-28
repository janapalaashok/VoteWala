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

These are not secret passwords (security comes from the rules above), but keep them in
GitHub secrets so builds pick them up:

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
