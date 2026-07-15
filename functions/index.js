const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Sends a push notification whenever a new 1:1 message is created.
 * This is what lets a user who has the app closed still get notified
 * the instant a friend messages them.
 */
exports.onNewChatMessage = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      const chatId = event.params.chatId;

      const chatDoc = await db.collection("chats").doc(chatId).get();
      const participants = chatDoc.data().participants || [];
      const recipientUid = participants.find((uid) => uid !== message.senderId);
      if (!recipientUid) return;

      const [senderSnap, recipientSnap] = await Promise.all([
        db.collection("users").doc(message.senderId).get(),
        db.collection("users").doc(recipientUid).get(),
      ]);

      const tokens = recipientSnap.data()?.fcmTokens || [];
      if (tokens.length === 0) return;

      const senderName = senderSnap.data()?.displayName || "New message";
      const body = message.type === "text" ? message.text : `Sent a ${message.type}`;

      await messaging.sendEachForMulticast({
        tokens,
        notification: {title: senderName, body: body || ""},
        data: {chatId, type: "chat_message"},
        android: {priority: "high"},
        apns: {payload: {aps: {sound: "default"}}},
      });
    },
);

/** Same idea, for group messages. */
exports.onNewGroupMessage = onDocumentCreated(
    "groups/{groupId}/messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      const groupId = event.params.groupId;

      const groupDoc = await db.collection("groups").doc(groupId).get();
      const group = groupDoc.data();
      const recipients = (group.members || []).filter((uid) => uid !== message.senderId);
      if (recipients.length === 0) return;

      const userDocs = await db.getAll(
          ...recipients.map((uid) => db.collection("users").doc(uid)),
      );
      const tokens = userDocs.flatMap((d) => d.data()?.fcmTokens || []);
      if (tokens.length === 0) return;

      await messaging.sendEachForMulticast({
        tokens,
        notification: {title: group.name, body: message.text || "New message"},
        data: {groupId, type: "group_message"},
        android: {priority: "high"},
      });
    },
);

/**
 * Callable function so the app can find a friend by phone number without
 * every client needing broad read access to the full phone-number index.
 */
exports.lookupUserByPhone = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const phoneNumber = request.data.phoneNumber;
  const snap = await db.collection("users")
      .where("phoneNumber", "==", phoneNumber).limit(1).get();
  if (snap.empty) return {found: false};
  const doc = snap.docs[0];
  return {found: true, uid: doc.id, displayName: doc.data().displayName};
});

/** Basic spam/report handling — flags a user after repeated reports. */
exports.onUserReported = onDocumentCreated("reports/{reportId}", async (event) => {
  const report = event.data.data();
  const reportsSnap = await db.collection("reports")
      .where("reportedUid", "==", report.reportedUid).get();
  if (reportsSnap.size >= 3) {
    await db.collection("users").doc(report.reportedUid).update({flagged: true});
  }
});
