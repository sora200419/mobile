import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:campuslink/features/task/model/task_model.dart';
import 'package:campuslink/features/task/services/chat_service.dart';

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
  bool _isAuthorized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  void _checkAuthorization() {
    String currentUserId = _auth.currentUser?.uid ?? '';
    String requesterId = widget.task.requesterId;
    String? providerId = widget.task.providerId;

    // Only requester and provider can chat
    setState(() {
      _isAuthorized =
          (currentUserId == requesterId || currentUserId == providerId);
      if (!_isAuthorized) {
        _errorMessage = 'You are not authorized to view this chat.';
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isAuthorized) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Send the message
      await _chatService.sendMessage(
        widget.task.id!,
        _messageController.text.trim(),
      );

      // Clear input field
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat: ${widget.task.title}', style: TextStyle(fontSize: 16)),
            Text(
              widget.task.status.toUpperCase(),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body:
          !_isAuthorized
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Chat messages
                  Expanded(
                    child: StreamBuilder<List<Message>>(
                      stream: _chatService.getMessages(widget.task.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text('Error: ${snapshot.error}'),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet.\nStart the conversation!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
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
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),

                        // Send button
                        IconButton(
                          icon:
                              _isSending
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              radius: 16,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(fontSize: 14),
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
                        fontSize: 12,
                      ),
                    ),

                  Text(
                    message.message,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),

                  const SizedBox(height: 4),

                  // Timestamp
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
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
              radius: 16,
              child: Text(
                _auth.currentUser?.displayName?.isNotEmpty == true
                    ? _auth.currentUser!.displayName![0].toUpperCase()
                    : 'Y',
                style: TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  // Format timestamp for chat messages
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today, show time only
      return "Today ${DateFormat('HH:mm').format(timestamp)}";
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      // Yesterday
      return "Yesterday ${DateFormat('HH:mm').format(timestamp)}";
    } else {
      // Other days, show date and time
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }
}
