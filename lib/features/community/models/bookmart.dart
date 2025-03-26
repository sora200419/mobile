// lib/features/community/models/bookmark.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  final String? id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  // Create from Firebase document
  factory Bookmark.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bookmark(
      id: doc.id,
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
