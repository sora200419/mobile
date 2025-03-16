// lib\features\task\views\task_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/chat_service.dart';

class TaskChatScreen extends StatefulWidget {
  final Task task;

  const TaskChatScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskChatScreen> createState() => _TaskChatScreenState();
}

class _TaskChatScreenState extends State<TaskChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send a new message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Determine who to send the message to
      String currentUserId = _auth.currentUser?.uid ?? '';
      String recipientId = '';

      // If current user is the requester, send to provider
      if (currentUserId == widget.task.requesterId) {
        recipientId = widget.task.providerId ?? '';
      }
      // If current user is the provider, send to requester
      else if (currentUserId == widget.task.providerId) {
        recipientId = widget.task.requesterId;
      }

      if (recipientId.isEmpty) {
        throw Exception('Recipient not found');
      }

      // Send the message
      await _chatService.sendMessage(
        widget.task.id!,
        _messageController.text.trim(),
      );

      // Clear the input field
      _messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat: ${widget.task.title}')),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.task.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                String currentUserId = _auth.currentUser?.uid ?? '';

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Latest messages at the bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                // Message text field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),

                // Send button
                IconButton(
                  icon:
                      _isSending
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build message bubble
  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
              ),
            ),

          const SizedBox(width: 8),

          // Message content
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),

                  Text(
                    message.message,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),

                  const SizedBox(height: 4),

                  // Timestamp
                  Text(
                    DateFormat('HH:mm, dd MMM').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (isMe)
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _auth.currentUser?.displayName?.isNotEmpty == true
                    ? _auth.currentUser!.displayName![0].toUpperCase()
                    : '?',
              ),
            ),
        ],
      ),
    );
  }
}
