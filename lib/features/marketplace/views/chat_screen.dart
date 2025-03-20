// lib/features/marketplace/views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';

class ChatScreen extends StatefulWidget {
  final Product product;
  final String receiverId;
  final String receiverName;
  final String? initialMessage;

  const ChatScreen({
    Key? key,
    required this.product,
    required this.receiverId,
    required this.receiverName,
    this.initialMessage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // If there's an initial message (e.g., from making an offer)
    if (widget.initialMessage != null && _isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialMessage!;
        _isFirstLoad = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _chatId {
    List<String> ids = [_auth.currentUser!.uid, widget.receiverId];
    ids.sort(); // Sort to ensure consistent chat ID regardless of who initiates
    return ids.join('_');
  }

  Stream<QuerySnapshot> _getMessages() {
    return _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    // Get user name
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    String senderName =
        (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

    // Save the message
    await _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
          'message': message,
          'senderId': user.uid,
          'senderName': senderName,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Update chat metadata
    await _firestore.collection('chats').doc(_chatId).set({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [user.uid, widget.receiverId],
      'participantNames': {
        user.uid: senderName,
        widget.receiverId: widget.receiverName,
      },
      'unreadCount': {widget.receiverId: FieldValue.increment(1)},
      'productId': widget.product.id,
      'productTitle': widget.product.title,
      'productImage': widget.product.imageUrl,
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: TextStyle(fontSize: 16)),
            Text(
              widget.product.title,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product info bar
          _buildProductInfoBar(),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Reset unread count for current user
                _resetUnreadCount();

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    bool isMe = data['senderId'] == _auth.currentUser!.uid;
                    Timestamp? timestamp = data['timestamp'] as Timestamp?;
                    String timeString =
                        timestamp != null ? _formatTimestamp(timestamp) : '';

                    return _buildMessageBubble(
                      data['message'] ?? '',
                      isMe,
                      timeString,
                    );
                  },
                );
              },
            ),
          ),

          // Message input area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoBar() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(widget.product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'RM ${widget.product.price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.product.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.product.status,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: 24), // Space for symmetry with avatar
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      // Today, show time only
      return DateFormat('h:mm a').format(dateTime);
    } else if (dateTime.year == now.year) {
      // This year, show month and day
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else {
      // Different year, show full date
      return DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
    }
  }

  Future<void> _resetUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Reset unread counter for current user
    await _firestore.collection('chats').doc(_chatId).set({
      'unreadCount': {user.uid: 0},
    }, SetOptions(merge: true));
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case Product.STATUS_AVAILABLE:
        return Colors.green;
      case Product.STATUS_RESERVED:
        return Colors.orange;
      case Product.STATUS_SOLD:
        return Colors.red;
      default:
        return Colors.green;
    }
  }
}
