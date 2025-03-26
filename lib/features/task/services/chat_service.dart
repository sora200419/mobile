import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'read': isRead,
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
  final CollectionReference tasksCollection = FirebaseFirestore.instance
      .collection('tasks');

  // Send a message in a task chat
  Future<void> sendMessage(String taskId, String message) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name
      DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();
      String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

      // Get task details to validate participants
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
      String requesterId = taskData['requesterId'] ?? '';
      String? providerId = taskData['providerId'];

      // Verify the current user is either the requester or provider
      if (user.uid != requesterId && user.uid != providerId) {
        throw Exception('You are not authorized to send messages in this chat');
      }

      // Create chat room ID based on task ID
      String chatRoomId = 'task_$taskId';

      // Add message to chat room
      await chatsCollection.doc(chatRoomId).collection('messages').add({
        'senderId': user.uid,
        'senderName': userName,
        'message': message,
        'timestamp': DateTime.now(),
        'taskId': taskId,
        'read': false,
      });

      // Update the chat room's last message info
      await chatsCollection.doc(chatRoomId).set({
        'taskId': taskId,
        'requesterId': requesterId,
        'providerId': providerId,
        'lastMessage': message,
        'lastSenderId': user.uid,
        'lastSenderName': userName,
        'lastMessageTime': DateTime.now(),
        'participants': [requesterId, providerId],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Get messages from a task chat
  Stream<List<Message>> getMessages(String taskId) {
    String chatRoomId = 'task_$taskId';
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value([]);
    }

    // First, check if the task exists and if the user is a participant
    return FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .asyncMap((taskSnapshot) async {
          if (!taskSnapshot.exists) {
            return <Message>[];
          }

          Map<String, dynamic> taskData =
              taskSnapshot.data() as Map<String, dynamic>;
          String requesterId = taskData['requesterId'] ?? '';
          String? providerId = taskData['providerId'];

          // Verify the current user is a participant
          if (currentUser.uid != requesterId && currentUser.uid != providerId) {
            print('Current user is not authorized to view this chat');
            return <Message>[];
          }

          // If authorized, get and return messages
          QuerySnapshot snapshot =
              await chatsCollection
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .get();

          List<Message> messages =
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();

          // Mark messages as read if they're from the other user
          _markMessagesAsRead(chatRoomId, currentUser.uid);

          return messages;
        });
  }

  // Get all chat rooms where the current user is involved
  Stream<QuerySnapshot> getUserChatRooms() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    // Get chat rooms where current user is either requester or provider
    return chatsCollection
        .where('participants', arrayContains: user.uid)
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
  Future<void> _markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      QuerySnapshot unreadMessages =
          await chatsCollection
              .doc(chatRoomId)
              .collection('messages')
              .where('senderId', isNotEqualTo: userId)
              .where('read', isEqualTo: false)
              .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get total unread count across all chats
  Stream<int> getTotalUnreadCount() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return chatsCollection
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .asyncMap((chatRooms) async {
          int totalUnread = 0;

          for (var doc in chatRooms.docs) {
            String chatId = doc.id;
            QuerySnapshot unreadMessages =
                await chatsCollection
                    .doc(chatId)
                    .collection('messages')
                    .where('senderId', isNotEqualTo: user.uid)
                    .where('read', isEqualTo: false)
                    .get();

            totalUnread += unreadMessages.docs.length;
          }

          return totalUnread;
        });
  }
}
