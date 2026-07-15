# Firebase Setup Guide — AsharafChat

This is the step that makes every user who installs the app land on the
**same backend**, so they can all see and message each other. Do this once.

## 1. Create the Firebase project

1. Go to https://console.firebase.google.com → **Add project**.
2. Name it e.g. `asharafchat-prod`. Disable Google Analytics or enable it
   (recommended, since it's already in the dependency list) — your call.
3. Once created, click **Add app → Android**. Package name: something like
   `com.jiyaad.asharafchat` (must match `android/app/build.gradle`).
4. Download `google-services.json` → place it in `android/app/`.
5. (Optional, for iOS later) Add an iOS app too, download `GoogleService-Info.plist`.

## 2. Enable the services you're using

In the Firebase console, turn on:

- **Authentication** → Sign-in method → enable *Phone*, *Email/Password*,
  *Google*. For Phone auth you'll need to add a test/production SHA-1 and
  SHA-256 fingerprint for Android (Firebase console will show you exactly
  where to get this from your keystore — see `BUILD_AND_DISTRIBUTE.md`).
- **Firestore Database** → Create database → start in **production mode**
  (rules are provided in `firebase/firestore.rules`).
- **Storage** → Get started (rules provided in `firebase/storage.rules`).
- **Cloud Messaging** → nothing to configure manually; it activates once
  the app registers a token.
- **Remote Config** → Create config (optional — useful later for feature
  flags like "maintenance mode" or forcing an update banner).
- **Crashlytics** → Enable; it activates automatically once the app runs.
- **App Check** → Register your Android app with **Play Integrity API**
  (works even for apps not on the Play Store, as long as the device has
  Play Services). For local development, use the **Debug provider** instead
  so App Check doesn't block your test builds.

## 3. Install the CLI tools

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

## 4. Wire the Flutter app to this project

From the project root:

```bash
flutterfire configure --project=asharafchat-prod
```

This generates `lib/firebase_options.dart` automatically — do not write this
file by hand; the placeholder in this repo (`lib/main.dart` imports it) will
be replaced by the real one this command produces.

## 5. Deploy security rules and Cloud Functions

```bash
firebase init firestore storage functions
# When prompted, point Firestore rules to firebase/firestore.rules
# and Storage rules to firebase/storage.rules (or copy them into the
# default locations firebase init creates).

cd functions
npm install
cd ..

firebase deploy --only firestore:rules,storage:rules,functions
```

After this, every phone that installs the app and signs in is reading and
writing to this one project — real-time chat between all of them works
immediately, no extra per-user setup needed.

## 6. Cost expectations at ~100 users

Firebase's free "Spark" plan will likely not be enough because Cloud
Functions require the pay-as-you-go **Blaze** plan (it still has a generous
free tier). For ~100 active users chatting daily with photos/voice notes,
expect a low monthly bill (commonly under the cost of a coffee subscription)
— but you should:

1. Set a **budget alert** in Google Cloud Console (Billing → Budgets).
2. Keep an eye on Storage usage (photos/videos add up fastest).

## 7. Before your first real user signs up

- Test phone OTP with your own number first — carrier SMS delivery can be
  finicky in Kenya depending on the number range; Firebase's phone auth
  works but do one end-to-end test yourself before sharing the APK.
- Confirm `firestore.rules` and `storage.rules` are deployed (not just
  written locally) — check the **Rules** tab in the console shows the same
  content as your local files.
