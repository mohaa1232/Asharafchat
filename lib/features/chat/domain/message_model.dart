import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, audio, document, location, contact, sticker, gif }

enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String senderId;
  final String? text;
  final MessageType type;
  final String? mediaUrl;
  final String? replyToMessageId;
  final List<String> starredBy;
  final Map<String, String> reactions; // uid -> emoji
  final bool deletedForEveryone;
  final bool edited;
  final DateTime? scheduledFor;
  final DateTime? expiresAt; // auto-delete / disappearing messages
  final MessageStatus status;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    this.replyToMessageId,
    this.starredBy = const [],
    this.reactions = const {},
    this.deletedForEveryone = false,
    this.edited = false,
    this.scheduledFor,
    this.expiresAt,
    this.status = MessageStatus.sending,
    required this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'],
      text: data['text'],
      type: MessageType.values.firstWhere(
        (t) => t.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      mediaUrl: data['mediaUrl'],
      replyToMessageId: data['replyToMessageId'],
      starredBy: List<String>.from(data['starredBy'] ?? []),
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      deletedForEveryone: data['deletedForEveryone'] ?? false,
      edited: data['edited'] ?? false,
      scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'type': type.name,
        'mediaUrl': mediaUrl,
        'replyToMessageId': replyToMessageId,
        'starredBy': starredBy,
        'reactions': reactions,
        'deletedForEveryone': deletedForEveryone,
        'edited': edited,
        'scheduledFor': scheduledFor,
        'expiresAt': expiresAt,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
