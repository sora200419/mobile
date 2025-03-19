// lib/features/task/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference chatsCollection = FirebaseFirestore.instance
      .collection('chats');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Send a message in a task chat
  Future<void> sendMessage(String taskId, String message) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name
      DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();
      String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

      // Create chat room ID based on task ID
      String chatRoomId = 'task_$taskId';

      // Add message to chat room
      await chatsCollection.doc(chatRoomId).collection('messages').add({
        'senderId': user.uid,
        'senderName': userName,
        'message': message,
        'timestamp': DateTime.now(),
      });

      // Update the chat room's last message info
      await chatsCollection.doc(chatRoomId).set({
        'taskId': taskId,
        'lastMessage': message,
        'lastSenderId': user.uid,
        'lastSenderName': userName,
        'lastMessageTime': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Get messages from a task chat
  Stream<List<Message>> getMessages(String taskId) {
    String chatRoomId = 'task_$taskId';

    return chatsCollection
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
        });
  }

  // Get all chat rooms where the current user is involved
  Stream<QuerySnapshot> getUserChatRooms() {
    User? user = _auth.currentUser;
    if (user == null) {
      // Return an empty stream instead of trying to create an empty QuerySnapshot
      return Stream.empty();
    }

    // This is a simplified approach. In a complete app, you'd need to
    // track which chats a user is part of (e.g., by adding a 'participants' array to each chat)
    return chatsCollection
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Check if a chat room exists for a specific task
  Future<bool> chatRoomExists(String taskId) async {
    String chatRoomId = 'task_$taskId';
    DocumentSnapshot chatDoc = await chatsCollection.doc(chatRoomId).get();
    return chatDoc.exists;
  }

  // Get chat room ID for a task
  String getChatRoomId(String taskId) {
    return 'task_$taskId';
  }

  // Count unread messages in a specific chat room
  Future<int> countUnreadMessages(String chatRoomId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 0;

      QuerySnapshot unreadMessages =
          await chatsCollection
              .doc(chatRoomId)
              .collection('messages')
              .where('senderId', isNotEqualTo: user.uid)
              .where('read', isEqualTo: false)
              .get();

      return unreadMessages.docs.length;
    } catch (e) {
      print('Error counting unread messages: $e');
      return 0;
    }
  }

  // Mark all messages in a chat room as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot unreadMessages =
          await chatsCollection
              .doc(chatRoomId)
              .collection('messages')
              .where('senderId', isNotEqualTo: user.uid)
              .where('read', isEqualTo: false)
              .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
