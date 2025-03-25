// lib/features/community/models/community_post.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { general, lostFound, jobPosting, studyMaterial, event }

class CommunityPost {
  final String? id;
  final String userId;
  final String userName;
  final PostType type;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likes;
  final int commentCount;
  final int reportCount;
  final Map<String, dynamic>? metadata;

  CommunityPost({
    this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.likes = 0,
    this.commentCount = 0,
    this.reportCount = 0,
    this.metadata,
  });

  // Create from Firebase document
  factory CommunityPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: PostType.values[data['type'] ?? 0],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      reportCount: data['reportCount'] ?? 0,
      metadata: data['metadata'],
    );
  }

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.index,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'commentCount': commentCount,
      'reportCount': reportCount,
      'metadata': metadata ?? {},
    };
  }

  // Create copy with updated fields
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    PostType? type,
    String? title,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    int? likes,
    int? commentCount,
    int? reportCount,
    Map<String, dynamic>? metadata,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      reportCount: reportCount ?? this.reportCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
