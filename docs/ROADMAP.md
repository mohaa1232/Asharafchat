# Roadmap — What's Done vs. What's Left

## Done and working (once you configure Firebase)
- Phone OTP, email/password, Google sign-in, shared `users/` directory
- 1:1 real-time chat: text, image messages, typing indicator, read
  receipts, delete-for-everyone, starring, reactions
- Group chat: create, send/receive messages, admin/member lists
- Presence: online/offline, last-seen timestamp
- Profile + privacy toggles (last seen, photo, status, read receipts)
- Firestore + Storage security rules scoped to participants only
- Cloud Functions: push notification on new 1:1/group message, phone
  number lookup, basic spam-report flagging

## Scaffolded (package installed, integration point marked, not wired)
- **Voice/video calling (Agora):** `agora_rtc_engine` is in `pubspec.yaml`.
  To finish: create an Agora account, get an App ID, write a small Cloud
  Function that mints RTC tokens (Agora requires this for production
  security), and build the call UI screens. Budget this as its own
  focused session — calling UX (ringing state, call history, CallKit/
  ConnectionService for native lock-screen call UI) is a substantial
  chunk of work on its own.
- **Voice notes:** `record` + `just_audio` are installed; the record →
  upload → playback flow follows the same pattern as `sendMediaMessage`
  in `chat_repository.dart`, just with `MessageType.audio`.
- **Video/document/contact messages:** same upload pattern as images,
  swap the picker (`file_picker`, `contacts_service`) and `MessageType`.
- **Stickers/GIF picker:** `emoji_picker_flutter` covers emoji; sticker/GIF
  packs need actual asset content or a GIF API (e.g. Giphy) integration.
- **Chat/App lock:** `local_auth` + `flutter_secure_storage` are installed;
  add a lock screen shown on app resume that checks a stored PIN/biometric
  before revealing chats.
- **Polls, events, announcements, communities/channels:** these are
  Firestore-schema extensions of the existing group model — each is a
  focused, addable feature rather than architectural work.
- **Disappearing messages cleanup:** the `expiresAt` field exists on
  `MessageModel`; add a scheduled Cloud Function (`onSchedule`, e.g. hourly)
  that deletes expired messages.
- **QR code login / multi-device:** `qr_flutter` + `mobile_scanner` are
  installed; this needs a short-lived pairing-token flow via Firestore.

## Not started — needs a dedicated effort
- **Signal Protocol end-to-end encryption.** This is real cryptographic
  engineering (per-device key pairs, X3DH key agreement, Double Ratchet
  session state, safety-number verification UI). It's the single biggest
  remaining piece and deserves its own careful build rather than being
  rushed in alongside everything else. Firestore rules + TLS + at-rest
  encryption already protect the ~100-user deployment reasonably well in
  the meantime.
- **Admin dashboard** (web-based user/group management, analytics, spam
  review UI) — a separate small web app (e.g. a React or Flutter Web
  project) reading the same Firestore project.
- **Automated test suite + CI/CD pipeline** (unit/widget/integration tests,
  GitHub Actions building & signing on push) — straightforward to add
  incrementally as features stabilize; not included here since it multiplies
  fastest once the app's shape is finalized.
- **CallKit (iOS) / ConnectionService (Android)** native call-screen
  integration — requires native Swift/Kotlin code beyond Flutter's
  cross-platform layer.

## Suggested order if you keep building this with me
1. Finish media messages (voice notes, video, documents) — same pattern,
   quick wins.
2. Wire up Agora calling (voice first, then video).
3. Add chat/app lock (biometric).
4. Then decide whether Signal Protocol E2EE is worth the investment for
   your user base, or whether Firestore-rule-based access control is
   sufficient given it's ~100 known people.
