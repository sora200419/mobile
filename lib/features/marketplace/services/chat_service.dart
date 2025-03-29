// lib/features/marketplace/services/chat_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/transaction_model.dart' as models;
import 'cloudinary_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _chatsRef => _firestore.collection('chats');
  CollectionReference _messagesCollection(String chatId) =>
      _firestore.collection('chats/$chatId/messages');

  // Create a new chat for a transaction
  Future<String> createChat(models.Transaction transaction) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if chat already exists for this transaction
    QuerySnapshot existingChats =
        await _chatsRef
            .where('transactionId', isEqualTo: transaction.id)
            .limit(1)
            .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    // Create new chat
    Chat chat = Chat(
      transactionId: transaction.id!,
      productId: transaction.productId,
      productTitle: transaction.productTitle,
      buyerId: transaction.buyerId,
      buyerName: transaction.buyerName,
      sellerId: transaction.sellerId,
      sellerName: transaction.sellerName,
      createdAt: DateTime.now(),
    );

    // Add to Firestore
    DocumentReference docRef = await _chatsRef.add(chat.toFirestore());

    // Create initial system message
    await sendSystemMessage(
      docRef.id,
      'Chat started for ${transaction.productTitle}. You can discuss details here.',
    );

    return docRef.id;
  }

  // Get all chats for current user
  Stream<List<Chat>> getUserChats() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where(
          Filter.or(
            Filter('buyerId', isEqualTo: currentUserId),
            Filter('sellerId', isEqualTo: currentUserId),
          ),
        )
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
        });
  }

  // Get chat by ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      DocumentSnapshot doc = await _chatsRef.doc(chatId).get();
      if (doc.exists) {
        return Chat.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  // Get chat by transaction ID
  Future<Chat?> getChatByTransactionId(String transactionId) async {
    try {
      QuerySnapshot querySnapshot =
          await _chatsRef
              .where('transactionId', isEqualTo: transactionId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Chat.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting chat by transaction ID: $e');
      return null;
    }
  }

  // Get messages for a chat
  Stream<List<Message>> getChatMessages(String chatId) {
    return _messagesCollection(
      chatId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Send a text message
  Future<String> sendTextMessage(String chatId, String content) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the chat to access participant information
    Chat? chat = await getChatById(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    // Get the current user's name based on their role in the chat
    String senderName =
        chat.buyerId == currentUserId ? chat.buyerName : chat.sellerName;

    // Create message
    Message message = Message(
      chatId: chatId,
      senderId: currentUserId!,
      senderName: senderName,
      content: content,
      createdAt: DateTime.now(),
      messageType: Message.TYPE_TEXT,
    );

    // Add message to Firestore
    DocumentReference docRef = await _messagesCollection(
      chatId,
    ).add(message.toFirestore());

    // Update the chat with last message information
    chat.lastMessageAt = message.createdAt;
    chat.lastMessageText = content;
    chat.incrementUnreadCount(currentUserId!);

    await _chatsRef.doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageText': content,
      'unreadCount': chat.unreadCount,
    });

    return docRef.id;
  }

  // Send a system message (for notifications within the chat)
  Future<String> sendSystemMessage(String chatId, String content) async {
    // Create message
    Message message = Message(
      chatId: chatId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      createdAt: DateTime.now(),
      isRead: true, // System messages are considered read by default
      messageType: Message.TYPE_TEXT,
    );

    // Add message to Firestore
    DocumentReference docRef = await _messagesCollection(
      chatId,
    ).add(message.toFirestore());

    // Update the chat with last message information
    await _chatsRef.doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageText': content,
    });

    return docRef.id;
  }

  // Send an image message
  Future<String> sendImageMessage(String chatId, File imageFile) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the chat to access participant information
    Chat? chat = await getChatById(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    // Upload image to Cloudinary
    String folder = 'marketplace/chats/$chatId';
    String imageUrl = await _cloudinaryService.uploadImage(
      imageFile,
      folder: folder,
    );

    // Get the current user's name based on their role in the chat
    String senderName =
        chat.buyerId == currentUserId ? chat.buyerName : chat.sellerName;

    // Create message
    Message message = Message(
      chatId: chatId,
      senderId: currentUserId!,
      senderName: senderName,
      content: 'Image',
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      messageType: Message.TYPE_IMAGE,
    );

    // Add message to Firestore
    DocumentReference docRef = await _messagesCollection(
      chatId,
    ).add(message.toFirestore());

    // Update the chat with last message information
    chat.lastMessageAt = message.createdAt;
    chat.lastMessageText = 'Image';
    chat.incrementUnreadCount(currentUserId!);

    await _chatsRef.doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageText': 'Image',
      'unreadCount': chat.unreadCount,
    });

    return docRef.id;
  }

  // Send a location message
  Future<String> sendLocationMessage(
    String chatId,
    GeoPoint location,
    String locationName,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the chat to access participant information
    Chat? chat = await getChatById(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    // Get the current user's name based on their role in the chat
    String senderName =
        chat.buyerId == currentUserId ? chat.buyerName : chat.sellerName;

    // Create message
    Message message = Message(
      chatId: chatId,
      senderId: currentUserId!,
      senderName: senderName,
      content: locationName,
      location: location,
      createdAt: DateTime.now(),
      messageType: Message.TYPE_LOCATION,
    );

    // Add message to Firestore
    DocumentReference docRef = await _messagesCollection(
      chatId,
    ).add(message.toFirestore());

    // Update the chat with last message information
    chat.lastMessageAt = message.createdAt;
    chat.lastMessageText = 'Location: $locationName';
    chat.incrementUnreadCount(currentUserId!);

    await _chatsRef.doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageText': 'Location: $locationName',
      'unreadCount': chat.unreadCount,
    });

    return docRef.id;
  }

  // Send a meeting request message
  Future<String> sendMeetingRequest(
    String chatId,
    DateTime meetingDateTime,
    GeoPoint location,
    String locationName,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the chat to access participant information
    Chat? chat = await getChatById(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    // Get the current user's name based on their role in the chat
    String senderName =
        chat.buyerId == currentUserId ? chat.buyerName : chat.sellerName;

    // Create message
    Message message = Message.createMeetingRequest(
      chatId: chatId,
      senderId: currentUserId!,
      senderName: senderName,
      meetingDateTime: meetingDateTime,
      location: location,
      locationName: locationName,
    );

    // Add message to Firestore
    DocumentReference docRef = await _messagesCollection(
      chatId,
    ).add(message.toFirestore());

    // Update the chat with last message information
    chat.lastMessageAt = message.createdAt;
    chat.lastMessageText = 'Meeting request: $locationName';
    chat.incrementUnreadCount(currentUserId!);

    await _chatsRef.doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageText': 'Meeting request: $locationName',
      'unreadCount': chat.unreadCount,
    });

    return docRef.id;
  }

  // Mark messages as read in a chat
  Future<void> markChatAsRead(String chatId) async {
    if (currentUserId == null) {
      return;
    }

    // Get the chat
    Chat? chat = await getChatById(chatId);
    if (chat == null) {
      return;
    }

    // Reset unread counter for current user
    chat.resetUnreadCount(currentUserId!);
    await _chatsRef.doc(chatId).update({'unreadCount': chat.unreadCount});

    // Mark all messages from other user as read
    String otherUserId = chat.getOtherUserId(currentUserId!);

    QuerySnapshot unreadMessages =
        await _messagesCollection(chatId)
            .where('senderId', isEqualTo: otherUserId)
            .where('isRead', isEqualTo: false)
            .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Get total unread messages count for current user
  Stream<int> getTotalUnreadCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _chatsRef
        .where(
          Filter.or(
            Filter('buyerId', isEqualTo: currentUserId),
            Filter('sellerId', isEqualTo: currentUserId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Map<String, dynamic> unreadCount = Map<String, dynamic>.from(
              data['unreadCount'] ?? {},
            );

            if (unreadCount.containsKey(currentUserId)) {
              total += (unreadCount[currentUserId] ?? 0) as int;
            }
          }
          return total;
        });
  }
}
