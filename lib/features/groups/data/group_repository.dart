import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupRepository {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<String> createGroup({
    required String name,
    required List<String> memberUids,
  }) async {
    final ref = _db.collection('groups').doc();
    await ref.set({
      'name': name,
      'photoUrl': null,
      'members': [_uid, ...memberUids],
      'admins': [_uid],
      'moderators': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'inviteCode': ref.id.substring(0, 8),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myGroupsStream() {
    return _db
        .collection('groups')
        .where('members', arrayContains: _uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> groupMessagesStream(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> sendGroupMessage(String groupId, String text) async {
    final msgRef =
        _db.collection('groups').doc(groupId).collection('messages').doc();
    await msgRef.set({
      'senderId': _uid,
      'text': text,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('groups').doc(groupId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMember(String groupId, String uid) {
    return _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid])
    });
  }

  Future<void> promoteToAdmin(String groupId, String uid) {
    return _db.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayUnion([uid])
    });
  }

  Future<void> removeMember(String groupId, String uid) {
    return _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
      'admins': FieldValue.arrayRemove([uid]),
    });
  }
}
