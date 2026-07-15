# AsharafChat

A premium, blue-themed messaging app built on Flutter + Firebase, designed so
you (Mohamed) can privately distribute it to ~100 people — friends, family,
and Jiyaad Travel Agency staff/clients — without publishing to Google Play.

## What's included in this codebase

- **Working core:** phone OTP + email/password + Google sign-in, real-time
  1:1 chat, group chat, presence (online/last seen), typing indicators, read
  receipts, message reactions, starring, delete-for-everyone, media messages
  (image upload shown, same pattern extends to video/audio/docs), profile +
  privacy settings, Firestore security rules, Storage rules, and Cloud
  Functions for push notifications and phone-number lookup.
- **Scaffolded / documented, not fully implemented:** voice/video calling
  (Agora), Signal-Protocol end-to-end encryption, CallKit/ConnectionService
  native integration, chat lock biometrics, stickers/GIF picker UI, polls,
  channels/communities, disappearing messages cron cleanup, admin dashboard.
  These are the parts that need real infrastructure decisions (an Agora
  account and App ID, a signing key, native platform code) that only you can
  provide — see `docs/ROADMAP.md` for exactly what's left and how to add it.

## Why calling and full E2EE aren't turnkey here

- **Agora calling** needs a real Agora App ID + token server (their free tier
  covers ~10,000 minutes/month, which comfortably covers 100 users). The
  Flutter package is already in `pubspec.yaml`; you need to add your App ID
  and a small token-generation Cloud Function.
- **Signal Protocol E2EE** is a serious cryptographic subsystem (key
  exchange, double ratchet, session state per-device) — implementing it
  correctly is not something to bolt on casually, since a bug there is a
  security bug, not a UI bug. For 100 known/trusted users, Firestore's rules
  (only participants can read a chat) combined with **TLS in transit** and
  **Firebase's at-rest encryption** already gives you meaningfully strong
  protection. If you want true E2EE later, budget it as its own project and
  I'm glad to help you build it deliberately, function by function.

## Getting the app running

1. Install Flutter (stable channel): https://docs.flutter.dev/get-started/install
2. `flutter pub get` inside this project folder.
3. Create a Firebase project (see `docs/FIREBASE_SETUP.md`) and run
   `flutterfire configure` to generate `lib/firebase_options.dart`.
4. Deploy `firebase/firestore.rules`, `firebase/storage.rules`, and the
   `functions/` folder (commands in `docs/FIREBASE_SETUP.md`).
5. `flutter run` to test on a connected device/emulator.
6. When ready to share with friends, follow `docs/BUILD_AND_DISTRIBUTE.md`.

## About the missing `android/` and `ios/` folders

This repo intentionally ships without generated native platform folders —
they can only be produced by running `flutter create`, which needs the real
Flutter SDK. Rather than requiring you to install that anywhere, this
project's `codemagic.yaml` has Codemagic generate `android/` and `ios/`
automatically at the start of every cloud build, then copies your Firebase
config into place. You never run `flutter create` yourself. Full walkthrough
in `docs/CLOUD_BUILD_GUIDE.md`.

## Project structure

```
lib/
  core/            theme, router, shared services
  features/
    auth/          phone OTP, email, Google sign-in
    chat/          1:1 messaging (data + UI)
    groups/        group messaging (data + UI)
    profile/       profile & privacy settings
  shared/widgets/  reusable UI (message bubble, etc.)
firebase/          firestore.rules, storage.rules
functions/         Cloud Functions (push notifications, user lookup)
docs/              setup, deployment, distribution, roadmap guides
```

## Full guides

- `docs/FIREBASE_SETUP.md` — creating and configuring the shared backend
- `docs/BUILD_AND_DISTRIBUTE.md` — building, signing, and sharing the APK
- `docs/ROADMAP.md` — what's scaffolded vs. what still needs building
