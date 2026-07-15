# Building, Signing, and Distributing AsharafChat

You do this part on your own computer (or a cloud CI runner) — it needs the
Android SDK and Flutter installed, which isn't available in this chat
environment. Here is the exact, complete process.

## 1. One-time: create your signing key

A signed release build needs a keystore. Generate one and **keep it safe
forever** — every future update must be signed with the same key, or
existing users won't be able to install the update over the old app.

```bash
keytool -genkey -v -keystore asharafchat-release.keystore \
  -alias asharafchat -keyalg RSA -keysize 2048 -validity 10000
```

Answer the prompts (name, organization, etc.) and choose strong passwords.
Store `asharafchat-release.keystore` somewhere backed up (e.g. your own
encrypted cloud storage) — not in Git.

Create `android/key.properties`:

```
storePassword=<your password>
keyPassword=<your password>
keyAlias=asharafchat
storeFile=../asharafchat-release.keystore
```

And point `android/app/build.gradle`'s `signingConfigs` block at it (the
standard Flutter release-signing snippet — Flutter's own docs at
https://docs.flutter.dev/deployment/android#signing-the-app cover the exact
lines to paste, since this varies slightly by Flutter version).

## 2. Build the release APK and AAB

```bash
flutter build apk --release
flutter build appbundle --release   # only needed if you later go to Play Store
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

The APK is what you'll share directly with friends. The AAB is only useful
if you later decide to publish on Google Play — you don't need it for
private distribution.

## 3. Get the SHA-1/SHA-256 fingerprint for Firebase Phone Auth

```bash
keytool -list -v -keystore asharafchat-release.keystore -alias asharafchat
```

Copy the SHA-1 and SHA-256 values into Firebase Console → Project settings →
your Android app → **Add fingerprint**. Without this, phone OTP sign-in can
fail in release builds.

## 4. How your friends install the APK

Because it's not from the Play Store, Android calls it an app from an
"unknown source." Send them these steps:

1. Receive the `app-release.apk` file (via WhatsApp, Telegram, email,
   Bluetooth, Nearby Share, or a direct download link — all work fine, the
   file itself is just a normal file).
2. Tap the file to open it.
3. Android will prompt: **"For your security, your phone is not allowed to
   install unknown apps from this source."** → tap **Settings**.
4. Toggle **"Allow from this source"** on (the exact wording is "Install
   unknown apps" in Settings → Apps → Special app access, per-app, e.g. for
   WhatsApp or Chrome, whichever app they used to open the file).
5. Go back and tap the APK again → **Install**.
6. Open AsharafChat, sign up with phone or email, and start chatting.

This is a one-time permission per source app, not per install — once
granted for e.g. WhatsApp or Files, future updates install without the
prompt reappearing.

## 5. Distributing to ~100 people practically

Options, roughly in order of convenience for a group this size:

- **WhatsApp group / broadcast list:** share the APK directly in a group
  chat you already have with them — simplest for immediate reach.
- **Telegram channel:** create a private channel, pin the APK there — good
  if you'll be pushing multiple updates over time, since Telegram keeps
  file history tidy.
- **Direct download link:** upload the APK to Google Drive / Dropbox, set
  link sharing to "anyone with the link," and send that single link — best
  if some recipients have flaky WhatsApp/Telegram media limits.
- **Bluetooth / Nearby Share:** fine for in-person handoffs, impractical for
  100 people spread out.

A single shared link is usually least error-prone for 100 people since
everyone gets the identical file with no re-compression from chat apps.

## 6. Updating the app later

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+2`).
2. Rebuild: `flutter build apk --release` (same keystore — do not lose it).
3. Share the new APK the same way as before.
4. Users tap the new file → Android installs it as an update **as long as
   the package name and signing key match** — their chat history in
   Firestore is untouched since that lives in the cloud, not on-device.

Optional nicety: use **Firebase Remote Config** to show an in-app "Update
available" banner with a link, so you don't have to chase people down every
time — this is already wired into the dependency list; wiring the banner UI
is a small addition described in `docs/ROADMAP.md`.

## 7. Scaling beyond ~100 users later

The Firestore + Cloud Functions architecture here scales horizontally by
default (Google manages the sharding) — you won't need to re-architect to
go from 100 to a few thousand users. The main things to revisit at larger
scale: Firestore composite indexes for more complex queries, Cloud
Functions concurrency limits, and eventually moving from "any signed-in
user can read any user profile" rules to more granular, contact-based
visibility.
