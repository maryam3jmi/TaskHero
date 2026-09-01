import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskhero/services/chat/chatting_servise.dart';
import 'package:taskhero/services/session.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String parentId = AppSession.userRole == "parent"
        ? AppSession.userId!
        : AppSession.parentId!;

    String childId = AppSession.userRole == "child"
        ? AppSession.userId!
        : widget.receiverId;

    return Scaffold(
      backgroundColor: Color(0xFFA9CDE3),

      appBar: AppBar(
        backgroundColor: Color(0xFFA9CDE3),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),

            const SizedBox(height: 6),

            Container(height: 3, width: double.infinity, color: Colors.black12),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(parentId, childId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  markMessagesAsRead(messages);
                });

                return ListView(
                  children: messages.map((doc) {
                    final data = doc.data() as Map;

                    bool isMe = data['senderId'] == AppSession.userId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),

                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],

                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['message'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),

                            if (isMe && (data['isRead'] ?? false))
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  "Seen",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Send button
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9CF45),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;

                      _chatService.sendMessage(
                        receiverId: widget.receiverId,
                        message: _controller.text.trim(),
                      );

                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void markMessagesAsRead(List messages) async {
    for (var doc in messages) {
      final data = doc.data() as Map<String, dynamic>;

      final isForMe = data['receiverId'] == AppSession.userId;
      final isUnread = (data['isRead'] ?? false) == false;

      if (isForMe && isUnread) {
        await doc.reference.update({'isRead': true});
      }
    }
  }
}
