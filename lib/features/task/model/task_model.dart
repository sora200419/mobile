// lib/features/task/model/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String title;
  final String description;
  final String requesterId;
  final String requesterName;
  final String? providerId;
  final String? providerName;
  final String location;
  final int rewardPoints;
  final DateTime deadline;
  final String
  status; // 'open', 'assigned', 'in_transit', 'completed', 'cancelled'
  final DateTime createdAt;
  final String category; // e.g., 'delivery', 'printing', 'tutoring', etc.

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.requesterName,
    this.providerId,
    this.providerName,
    required this.location,
    required this.rewardPoints,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.category,
  });

  // Convert Task object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'providerId': providerId,
      'providerName': providerName,
      'location': location,
      'rewardPoints': rewardPoints,
      'deadline': deadline,
      'status': status,
      'createdAt': createdAt,
      'category': category,
    };
  }

  // Create a Task object from a Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      providerId: data['providerId'],
      providerName: data['providerName'],
      location: data['location'] ?? '',
      rewardPoints: data['rewardPoints'] ?? 0,
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] ?? 'other',
    );
  }
}
