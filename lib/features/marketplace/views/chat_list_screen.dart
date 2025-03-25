// lib/features/marketplace/views/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart'; // Make sure this is imported correctly

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Chat>>(
        stream:
            _chatService
                .getUserChats(), // This method is defined in ChatService
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Chat> chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Your conversations will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              Chat chat = chats[index];
              String? currentUserId =
                  _chatService
                      .currentUserId; // This property is defined in ChatService

              if (currentUserId == null) return Container();

              // Get unread messages count for current user
              int unreadCount = chat.unreadCount[currentUserId] ?? 0;

              return _buildChatListItem(context, chat, unreadCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, Chat chat, int unreadCount) {
    String? currentUserId = _chatService.currentUserId;

    if (currentUserId == null) return Container();

    String otherUserName = chat.getOtherUserName(currentUserId);

    return ListTile(
      leading: CircleAvatar(
        child: Text(
          otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
        ),
      ),
      title: Text(otherUserName),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessageText ?? 'Start a conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.lastMessageAt != null)
            Text(
              DateFormat('MMM d, h:mm a').format(chat.lastMessageAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
      trailing:
          unreadCount > 0
              ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  chatId: chat.id!,
                ), // Using ChatScreen as a component, not a method
          ),
        );
      },
    );
  }
}
