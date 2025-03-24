// lib/features/notifications/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'marketplace', 'task', 'community', etc.
  final String? subtype; // 'chat', 'status', 'deadline', etc.
  final String? sourceId; // ID of the related item (product, task, post)
  final String? sourceTitle; // Title of the related item
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.subtype,
    this.sourceId,
    this.sourceTitle,
    this.imageUrl,
    required this.createdAt,
    required this.isRead,
    this.additionalData,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      subtype: data['subtype'],
      sourceId: data['sourceId'],
      sourceTitle: data['sourceTitle'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'subtype': subtype,
      'sourceId': sourceId,
      'sourceTitle': sourceTitle,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }
}
