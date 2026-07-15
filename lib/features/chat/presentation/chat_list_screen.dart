import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../data/chat_repository.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ChatRepository();
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AsharafChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.myChatsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet — tap + to start one'));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final data = chats[i].data();
              final participants = List<String>.from(data['participants']);
              final otherUid = participants.firstWhere((id) => id != myUid);
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future:
                    FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                builder: (context, userSnap) {
                  final name =
                      userSnap.data?.data()?['displayName'] ?? 'Loading...';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(name),
                    subtitle: Text(data['lastMessage'] ?? ''),
                    onTap: () => context.push(
                      '/chat/${chats[i].id}',
                      extra: {'peerName': name},
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context, repo),
        child: const Icon(Icons.chat),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context, ChatRepository repo) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              labelText: 'Enter friend\'s phone number or user ID'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              // In production: look up the user by phone number/username
              // via a Cloud Function (see functions/index.js: lookupUser).
              final otherUid = controller.text.trim();
              await repo.ensureChatDocument(otherUid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
