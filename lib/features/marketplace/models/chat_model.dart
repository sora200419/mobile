// lib/features/marketplace/models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  String? id;
  String transactionId;
  String productId;
  String productTitle;
  String buyerId;
  String buyerName;
  String sellerId;
  String sellerName;
  DateTime createdAt;
  DateTime? lastMessageAt;
  String? lastMessageText;
  Map<String, int> unreadCount;

  Chat({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    DateTime? createdAt,
    this.lastMessageAt,
    this.lastMessageText,
    Map<String, int>? unreadCount,
  }) : this.createdAt = createdAt ?? DateTime.now(),
       this.unreadCount = unreadCount ?? {buyerId: 0, sellerId: 0};

  // Factory method to create Chat from Firestore data
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Chat(
      id: doc.id,
      transactionId: data['transactionId'] ?? '',
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageText: data['lastMessageText'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  // Convert Chat to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'productId': productId,
      'productTitle': productTitle,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessageText': lastMessageText,
      'unreadCount': unreadCount,
    };
  }

  // Get the other user's ID based on the current user
  String getOtherUserId(String currentUserId) {
    return currentUserId == buyerId ? sellerId : buyerId;
  }

  // Get the other user's name based on the current user
  String getOtherUserName(String currentUserId) {
    return currentUserId == buyerId ? sellerName : buyerName;
  }

  // Reset unread count for a specific user
  void resetUnreadCount(String userId) {
    if (unreadCount.containsKey(userId)) {
      unreadCount[userId] = 0;
    }
  }

  // Increment unread count for a specific user
  void incrementUnreadCount(String userId) {
    final otherUserId = getOtherUserId(userId);
    if (unreadCount.containsKey(otherUserId)) {
      unreadCount[otherUserId] = (unreadCount[otherUserId] ?? 0) + 1;
    }
  }
}
