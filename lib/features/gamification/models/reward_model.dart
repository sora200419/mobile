// lib/features/gamification/models/reward_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String rewardType; // 'discount', 'priority', 'premium', 'campus'
  final String rewardCode; // Optional redemption code
  final bool isAvailable;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.rewardType,
    required this.rewardCode,
    required this.isAvailable,
  });

  factory Reward.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Reward(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pointsCost: data['pointsCost'] ?? 0,
      rewardType: data['rewardType'] ?? 'discount',
      rewardCode: data['rewardCode'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'rewardType': rewardType,
      'rewardCode': rewardCode,
      'isAvailable': isAvailable,
    };
  }
}
