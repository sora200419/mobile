// lib/features/gamification/models/level_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLevel {
  final String userId;
  final int level;
  final String levelName;
  final int currentPoints;
  final int pointsToNextLevel;
  final double progressPercent;

  UserLevel({
    required this.userId,
    required this.level,
    required this.levelName,
    required this.currentPoints,
    required this.pointsToNextLevel,
    required this.progressPercent,
  });

  factory UserLevel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserLevel(
      userId: doc.id,
      level: data['level'] ?? 1,
      levelName: data['levelName'] ?? 'Newcomer',
      currentPoints: data['points'] ?? 0,
      pointsToNextLevel: data['pointsToNextLevel'] ?? 50,
      progressPercent: data['progressPercent'] ?? 0.0,
    );
  }
}
