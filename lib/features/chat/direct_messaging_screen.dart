// lib\features\chat\direct_messaging_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DirectMessageScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const DirectMessageScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _chatRoomId = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _getChatRoomId();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Get or create a chat room ID for direct messaging
  void _getChatRoomId() {
    String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    // Sort IDs to ensure consistency
    List<String> ids = [currentUserId, widget.otherUserId];
    ids.sort();

    // Create chat room ID
    _chatRoomId = 'direct_${ids[0]}_${ids[1]}';
  }

  // Send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_chatRoomId.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Get current user's name
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      String senderName =
          (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

      // Check if chat room exists
      DocumentSnapshot chatRoomDoc =
          await _firestore.collection('chats').doc(_chatRoomId).get();

      // Get current timestamp
      DateTime now = DateTime.now();

      if (!chatRoomDoc.exists) {
        // Create new chat room
        await _firestore.collection('chats').doc(_chatRoomId).set({
          'participants': [currentUser.uid, widget.otherUserId],
          'lastMessage': _messageController.text.trim(),
          'lastSenderId': currentUser.uid,
          'lastSenderName': senderName,
          'lastMessageTime': now,
          'createdAt': now,
        });
      } else {
        // Update existing chat room
        await _firestore.collection('chats').doc(_chatRoomId).update({
          'lastMessage': _messageController.text.trim(),
          'lastSenderId': currentUser.uid,
          'lastSenderName': senderName,
          'lastMessageTime': now,
        });
      }

      // Add message to chat room
      await _firestore
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'senderName': senderName,
            'message': _messageController.text.trim(),
            'timestamp': now,
            'read': false,
          });

      // Clear message field
      _messageController.clear();

      // Scroll to bottom
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
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
        title: Text(widget.otherUserName),
        actions: [
          // User profile button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show user info dialog
              _showUserProfileDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('chats')
                      .doc(_chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation with ${widget.otherUserName}',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Mark messages as read
                _markMessagesAsRead(messages);

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Latest messages at the bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData =
                        messageDoc.data() as Map<String, dynamic>;

                    final senderId = messageData['senderId'] as String? ?? '';
                    final senderName =
                        messageData['senderName'] as String? ?? 'Unknown';
                    final messageText = messageData['message'] as String? ?? '';
                    final timestamp =
                        (messageData['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    final isMe = senderId == _auth.currentUser?.uid;

                    return _buildMessageBubble(
                      senderName: senderName,
                      message: messageText,
                      timestamp: timestamp,
                      isMe: isMe,
                    );
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

  // Mark messages as read
  void _markMessagesAsRead(List<QueryDocumentSnapshot> messages) async {
    try {
      String currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      bool hasUpdates = false;

      for (var message in messages) {
        Map<String, dynamic> data = message.data() as Map<String, dynamic>;
        // Only mark others' messages as read
        if (data['senderId'] != currentUserId && data['read'] == false) {
          batch.update(message.reference, {'read': true});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Build message bubble
  Widget _buildMessageBubble({
    required String senderName,
    required String message,
    required DateTime timestamp,
    required bool isMe,
  }) {
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
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.grey),
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
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),

                  Text(
                    message,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),

                  const SizedBox(height: 4),

                  // Timestamp
                  Text(
                    DateFormat('HH:mm, dd MMM').format(timestamp),
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
                style: const TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  // Show user profile dialog
  void _showUserProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(widget.otherUserId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return AlertDialog(
                title: const Text('User Info'),
                content: const Text('Could not load user information.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final name = userData['name'] ?? 'Unknown';
            final role = userData['role'] ?? 'Unknown';

            // Get user's average rating
            return FutureBuilder<DocumentSnapshot>(
              future:
                  _firestore.collection('users').doc(widget.otherUserId).get(),
              builder: (context, ratingSnapshot) {
                double averageRating = 0;
                int ratingCount = 0;

                if (ratingSnapshot.hasData && ratingSnapshot.data!.exists) {
                  final userRatingData =
                      ratingSnapshot.data!.data() as Map<String, dynamic>;
                  averageRating =
                      (userRatingData['averageRating'] ?? 0.0).toDouble();
                  ratingCount = (userRatingData['ratingCount'] ?? 0);
                }

                return AlertDialog(
                  title: const Text('User Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        role,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (averageRating > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${averageRating.toStringAsFixed(1)} (${ratingCount} ${ratingCount == 1 ? 'rating' : 'ratings'})',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
