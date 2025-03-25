// lib/features/marketplace/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String? id;
  String chatId;
  String senderId;
  String senderName;
  String content;
  String? imageUrl;
  GeoPoint? location;
  DateTime createdAt;
  bool isRead;
  String messageType;

  static const String TYPE_TEXT = 'text';
  static const String TYPE_IMAGE = 'image';
  static const String TYPE_LOCATION = 'location';
  static const String TYPE_MEETING_REQUEST = 'meeting_request';

  Message({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.imageUrl,
    this.location,
    DateTime? createdAt,
    this.isRead = false,
    this.messageType = TYPE_TEXT,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory method to create Message from Firestore data
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? TYPE_TEXT,
    );
  }

  // Convert Message to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'imageUrl': imageUrl,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'messageType': messageType,
    };
  }

  // Create a meeting request message
  static Message createMeetingRequest({
    required String chatId,
    required String senderId,
    required String senderName,
    required DateTime meetingDateTime,
    required GeoPoint location,
    String locationName = '',
  }) {
    final content = '$locationName|${meetingDateTime.millisecondsSinceEpoch}';

    return Message(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      location: location,
      messageType: TYPE_MEETING_REQUEST,
    );
  }
}
