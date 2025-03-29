// lib/features/community/models/comment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String? id;
  final String postId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final int likes;

  Comment({
    this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.likes = 0,
  });

  // Create from Firebase document
  factory Comment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
    );
  }

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }
}
