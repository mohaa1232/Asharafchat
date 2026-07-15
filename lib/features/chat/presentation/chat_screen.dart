import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../data/chat_repository.dart';
import '../domain/message_model.dart';
import '../../../shared/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String peerName;
  const ChatScreen({super.key, required this.chatId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = ChatRepository();
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _repo.sendTextMessage(widget.chatId, text);
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _repo.sendMediaMessage(
      chatId: widget.chatId,
      file: File(picked.path),
      type: MessageType.image,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {
            // TODO: launch Agora voice call — see docs/CALLING.md
          }),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {
            // TODO: launch Agora video call — see docs/CALLING.md
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _repo.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) => MessageBubble(message: messages[i]),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.attach_file), onPressed: _sendImage),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (v) => _repo.setTyping(widget.chatId, v.isNotEmpty),
                      decoration: const InputDecoration(
                          hintText: 'Message', border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
