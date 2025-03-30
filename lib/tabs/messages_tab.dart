// lib/tabs/messages_tab.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuslink/features/task/model/task_model.dart';
import 'package:campuslink/features/task/services/chat_service.dart';
import 'package:campuslink/features/task/views/task_chat_screen.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({Key? key}) : super(key: key);

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search messages...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Chat rooms list
        Expanded(child: _buildChatRoomsList()),
      ],
    );
  }

  // Chat rooms list
  Widget _buildChatRoomsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var chatRooms = snapshot.data?.docs ?? [];

        if (chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Messages Yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Your conversations with task providers and requesters will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            var chatRoom = chatRooms[index];
            Map<String, dynamic> data = chatRoom.data() as Map<String, dynamic>;

            String taskId = data['taskId'] ?? '';
            String lastMessage = data['lastMessage'] ?? '';
            String lastSenderName = data['lastSenderName'] ?? '';
            Timestamp lastMessageTime =
                data['lastMessageTime'] ?? Timestamp.now();

            return _buildChatRoomCard(
              taskId: taskId,
              lastMessage: lastMessage,
              lastSenderName: lastSenderName,
              lastMessageTime: lastMessageTime.toDate(),
            );
          },
        );
      },
    );
  }

  // Chat room card
  Widget _buildChatRoomCard({
    required String taskId,
    required String lastMessage,
    required String lastSenderName,
    required DateTime lastMessageTime,
  }) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('tasks').doc(taskId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        var taskData = snapshot.data?.data() as Map<String, dynamic>?;
        if (taskData == null) {
          return const SizedBox.shrink();
        }

        Task task = Task.fromFirestore(snapshot.data!);
        String currentUserId = _auth.currentUser?.uid ?? '';
        bool isRequester = task.requesterId == currentUserId;
        String otherUserName =
            isRequester
                ? (task.providerName ?? 'Provider')
                : task.requesterName;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ),
            title: Text(
              otherUserName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    '$lastSenderName: $lastMessage',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                Text(
                  _formatTimestamp(lastMessageTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            trailing: FutureBuilder<int>(
              future: _chatService.countUnreadMessages(
                _chatService.getChatRoomId(taskId),
              ),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data ?? 0;
                if (unreadCount > 0) {
                  return Container(
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
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskChatScreen(task: task),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }

  // Format timestamp for chat messages
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
