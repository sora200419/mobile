// lib/features/gamification/models/challenge_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final String challengeType; // 'weekly', 'seasonal', 'special'

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.pointsReward,
    required this.challengeType,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      pointsReward: data['pointsReward'] ?? 0,
      challengeType: data['challengeType'] ?? 'weekly',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'pointsReward': pointsReward,
      'challengeType': challengeType,
    };
  }

  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}
