// lib/features/gamification/models/achievement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime awardedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.awardedAt,
  });

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      userId: data['userId'] ?? '',
      achievementId: data['achievementId'] ?? '',
      awardedAt: (data['awardedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'awardedAt': awardedAt,
    };
  }
}
