// lib/features/gamification/models/badge_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int pointsRequired;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.pointsRequired,
  });

  factory Badge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Badge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? '',
      pointsRequired: data['pointsRequired'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'pointsRequired': pointsRequired,
    };
  }
}
