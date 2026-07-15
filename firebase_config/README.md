# Firebase config staging folder

Put your downloaded `google-services.json` (from the Firebase Console) here
at `firebase_config/google-services.json`.

Why here and not directly in `android/app/`? Because this repo doesn't
contain a generated `android/` folder yet (see the root README) — Codemagic
generates it fresh on every build. The Codemagic post-clone script copies
this file into `android/app/google-services.json` automatically right after
`flutter create` runs, so it ends up in the right place every single build.
