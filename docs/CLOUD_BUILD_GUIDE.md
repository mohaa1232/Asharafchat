# Building AsharafChat from Your Android Phone — No Computer, No `flutter create`

This project deliberately does **not** include a generated `android/` or
`ios/` folder. Instead, **Codemagic generates them automatically at the
start of every build**, using its own Flutter installation, on its own
cloud machine. You never install Flutter and never run `flutter create`
yourself — that's baked into `codemagic.yaml` in this repo.

You'll use two services:
- **GitHub + GitHub Codespaces** — just to get the code and your Firebase
  config file onto GitHub (basically a file manager in your browser; no
  Flutter needed here at all now).
- **Codemagic** — pulls the code, generates the native folders, builds,
  signs, and gives you a downloadable APK.

---

## Step 1 — Get the project onto GitHub

1. On your phone browser: **github.com** → sign up / log in.
2. **+ → New repository** → name it `asharafchat` → **Private** → check
   "Add a README" → **Create repository**.
3. On the repo page: **Code → Codespaces tab → Create codespace on main**.
   This opens a browser-based VS Code — give it a minute to load.
4. In the Explorer sidebar, tap **⋯ → Upload...** and pick
   `AsharafChat_source.zip` from your phone's downloads.
5. Open **Terminal → New Terminal** and run:
   ```bash
   unzip AsharafChat_source.zip -d .
   mv asharaf_chat/* asharaf_chat/.[!.]* . 2>/dev/null; rmdir asharaf_chat
   rm AsharafChat_source.zip
   git add -A
   git commit -m "Initial AsharafChat commit"
   git push
   ```

No Flutter installation, no `flutter create` — that's it for this step.

---

## Step 2 — Configure Firebase

1. **console.firebase.google.com** → **Add project** → `asharafchat-prod`.
2. **Add app → Android**. Package name — use exactly:
   ```
   com.jiyaad.asharaf_chat
   ```
   (This must match what Codemagic's `flutter create --org com.jiyaad .`
   will generate, since the Flutter project is named `asharaf_chat`. The
   included `codemagic.yaml` also stores this as `PACKAGE_NAME` for
   reference.)
3. Download **`google-services.json`**.
4. Back in your Codespace: Explorer → ⋯ → **Upload...** → place this file
   at `firebase_config/google-services.json` (a folder already exists there
   with a README explaining why it's staged here rather than inside
   `android/app/` — that folder doesn't exist yet in the repo).
5. In Firebase Console → **Project settings → General**, note the **API
   key**, **App ID**, **Project ID**, **Storage bucket**, **Messaging
   sender ID** for your Android app.
6. In the Codespace, create `lib/firebase_options.dart`:
   ```dart
   import 'package:firebase_core/firebase_core.dart';

   class DefaultFirebaseOptions {
     static FirebaseOptions get currentPlatform => android;

     static const FirebaseOptions android = FirebaseOptions(
       apiKey: 'PASTE_API_KEY',
       appId: 'PASTE_APP_ID',
       messagingSenderId: 'PASTE_SENDER_ID',
       projectId: 'PASTE_PROJECT_ID',
       storageBucket: 'PASTE_STORAGE_BUCKET',
     );
   }
   ```
7. In Firebase Console, enable: **Authentication** (Phone, Email/Password,
   Google), **Firestore Database** (production mode), **Storage**.
8. Paste the contents of `firebase/firestore.rules` into **Firestore →
   Rules** and **Publish**. Do the same for `firebase/storage.rules` under
   **Storage → Rules**.
9. Commit and push:
   ```bash
   git add -A
   git commit -m "Add Firebase config"
   git push
   ```

Cloud Functions (`functions/index.js`, for push notifications) need the
Blaze plan and the `firebase` CLI — optional for now, the app works for
chat without them. See the CLI snippet in the previous guide version if you
want to set these up later; do it as a one-off in this same Codespace.

---

## Step 3 — `flutter pub get`

Nothing to do — Codemagic runs this automatically as part of the workflow
defined in `codemagic.yaml`.

---

## Step 4 — Connect Codemagic

1. **codemagic.io** → sign up with your **GitHub** account.
2. **Add application** → select your `asharafchat` repo.
3. Codemagic detects `codemagic.yaml` in the repo root and offers the
   **android-release** workflow defined in it — select it.

---

## Step 5 — Set up signing, then build

1. In your Codemagic app → **Team settings → Code signing identities →
   Android keystores** → either:
   - **Generate a new keystore** (simplest) — Codemagic creates one and
     lets you download it. **Save that download somewhere safe** (e.g.
     your own Google Drive) — every future update needs the *same*
     keystore, or existing users can't install the update over the old
     app.
   - Or upload a keystore you already made elsewhere.
2. Name the keystore reference **exactly** `asharafchat_keystore` (or edit
   that name in `codemagic.yaml` to match whatever you called it).
3. Go to your app → **Start new build** → pick workflow **android-release**
   → **Start new build**.
4. Watch the build log — you'll see it run `flutter create` automatically
   (only because `android/` doesn't exist yet), copy your Firebase config
   into place, `flutter pub get`, then `flutter build apk --release`.
5. When it finishes, open the build → **Artifacts** → `app-release.apk`
   has a direct download link.

---

## Step 6 — Get the APK onto your phone

Tap the `.apk` link in Codemagic's Artifacts tab — it downloads straight to
your phone's Downloads folder. No transfer step needed since you never left
the phone.

---

## Step 7 — Share the APK with your friends (no Google Play)

Send `app-release.apk` via:
- **WhatsApp / Telegram** — attach it like any file.
- **Email** — attach it (some providers block `.apk`; if so, rename to
  `.zip`, send, have them rename it back).
- **Bluetooth / Nearby Share** — fine in person.
- **A direct link** — upload to Google Drive, set "anyone with the link,"
  send that link — most reliable for reaching many people at once.

Each friend, when opening the file:
1. Android warns: *"not allowed to install unknown apps from this
   source"* → tap **Settings**.
2. Toggle **"Allow from this source"** on (one-time, per app they opened
   it with).
3. Tap the APK again → **Install**.
4. Open AsharafChat, sign up, start chatting — everyone's on the same
   Firebase backend you set up above.

---

## Updating the app later

Push new commits to GitHub → **Start new build** in Codemagic (same
workflow, same keystore reference) → share the new APK the same way.
`android/` and `ios/` get regenerated fresh on that build too, so any
manual edits you made inside a previous build's generated `android/`
folder won't persist — if you ever need to customize native Android files
long-term (e.g. permissions, custom launcher icon), commit `android/` to
the repo yourself once you're past this getting-started stage, and the
"skip if it exists" check in `codemagic.yaml` will leave it alone from
then on.
