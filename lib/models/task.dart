// lib/models/task.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/utils/constants/enums.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String? runnerId;
  final DateTime postedAt;
  final DateTime? deadline;
  final String category;
  final RunnerTaskStatus status;
  final double rewardPoints;
  final String? location;
  final String? imageUrl;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    this.runnerId,
    required this.postedAt,
    this.deadline,
    required this.category,
    required this.status,
    required this.rewardPoints,
    this.location,
    this.imageUrl,
    required this.isCompleted,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? runnerId,
    DateTime? postedAt,
    DateTime? deadline,
    String? category,
    RunnerTaskStatus? status,
    double? rewardPoints,
    String? location,
    String? imageUrl,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      runnerId: runnerId ?? this.runnerId,
      postedAt: postedAt ?? this.postedAt,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      status: status ?? this.status,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
      'runnerId': runnerId,
      'postedAt': Timestamp.fromDate(postedAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'category': category,
      'status': status.toString(),
      'rewardPoints': rewardPoints,
      'location': location,
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      runnerId: map['runnerId'],
      postedAt:
          (map['postedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(), // Handle potential null
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      category: map['category'] ?? '',
      status: _stringToTaskStatus(map['status']),
      rewardPoints: (map['rewardPoints'] ?? 0.0).toDouble(),
      location: map['location'],
      imageUrl: map['imageUrl'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  static RunnerTaskStatus _stringToTaskStatus(String? status) {
    return RunnerTaskStatus.values.firstWhere(
      (e) => e.toString() == status,
      orElse: () => RunnerTaskStatus.pending,
    );
  }
}
