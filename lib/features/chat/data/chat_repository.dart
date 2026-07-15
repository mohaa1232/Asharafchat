import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/message_model.dart';

/// Real-time chat repository built directly on Cloud Firestore's live
/// listeners — this is what makes messages instant between any two users
/// on the same Firebase project, with zero custom server required.
class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Deterministic chat id for a 1:1 conversation so both users always
  /// resolve to the same document regardless of who starts the chat.
  String chatIdFor(String otherUid) {
    final ids = [_uid, otherUid]..sort();
    return ids.join('_');
  }

  Future<void> ensureChatDocument(String otherUid) async {
    final chatId = chatIdFor(otherUid);
    final ref = _db.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [_uid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
        'typing': <String, bool>{},
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myChatsStream() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<List<MessageModel>> messagesStream(String chatId, {int limit = 50}) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  Future<void> sendTextMessage(String chatId, String text,
      {String? replyToMessageId}) async {
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
    final message = MessageModel(
      id: msgRef.id,
      senderId: _uid,
      text: text,
      replyToMessageId: replyToMessageId,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    await msgRef.set(message.toMap());
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  /// Uploads media (image/video/audio/document) to Firebase Storage then
  /// writes a message pointing at the download URL.
  Future<void> sendMediaMessage({
    required String chatId,
    required File file,
    required MessageType type,
    String? caption,
  }) async {
    final ext = file.path.split('.').last;
    final path = 'chats/$chatId/media/${_uuid.v4()}.$ext';
    final ref = _storage.ref(path);
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
    final message = MessageModel(
      id: msgRef.id,
      senderId: _uid,
      text: caption,
      type: type,
      mediaUrl: url,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    await msgRef.set(message.toMap());
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': '[${type.name}]',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTyping(String chatId, bool isTyping) {
    return _db.collection('chats').doc(chatId).update({'typing.$_uid': isTyping});
  }

  Future<void> markDelivered(String chatId, String messageId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': MessageStatus.delivered.name});
  }

  Future<void> markRead(String chatId, String messageId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': MessageStatus.read.name});
  }

  Future<void> deleteForEveryone(String chatId, String messageId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'deletedForEveryone': true, 'text': null, 'mediaUrl': null});
  }

  Future<void> toggleStar(String chatId, String messageId, bool star) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'starredBy': star
          ? FieldValue.arrayUnion([_uid])
          : FieldValue.arrayRemove([_uid])
    });
  }

  Future<void> react(String chatId, String messageId, String emoji) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$_uid': emoji});
  }
}
