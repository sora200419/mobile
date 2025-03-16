// lib/features/task/services/rating_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Rating {
  final String id;
  final String taskId;
  final String userId; // User who is being rated
  final String ratedByUserId; // User who gave the rating
  final double rating; // 1-5 stars
  final String? comment;
  final DateTime timestamp;

  Rating({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.ratedByUserId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory Rating.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      ratedByUserId: data['ratedByUserId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'ratedByUserId': ratedByUserId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }
}

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Points awarded for receiving a good rating
  static const int POINTS_GOOD_RATING = 2; // For ratings >= 4

  // Collection references
  final CollectionReference ratingsCollection = FirebaseFirestore.instance
      .collection('ratings');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Rate a user
  Future<void> rateUser(
    String taskId,
    String userId,
    double rating, {
    String? comment,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Add rating to Firestore
      await ratingsCollection.add({
        'taskId': taskId,
        'userId': userId,
        'ratedByUserId': currentUser.uid,
        'rating': rating,
        'comment': comment,
        'timestamp': DateTime.now(),
      });

      // Award points for good ratings
      if (rating >= 4.0) {
        // Get current points
        DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
        int currentPoints =
            (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;

        // Update points
        await usersCollection.doc(userId).update({
          'points': currentPoints + POINTS_GOOD_RATING,
        });
      }

      // Update user's average rating
      await _updateUserAverageRating(userId);
    } catch (e) {
      print('Error rating user: $e');
      throw e;
    }
  }

  // Get ratings for a specific user
  Stream<List<Rating>> getUserRatings(String userId) {
    return ratingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
        });
  }

  // Get ratings for a specific task
  Stream<List<Rating>> getTaskRatings(String taskId) {
    return ratingsCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
        });
  }

  // Get user's average rating
  Future<double> getUserAverageRating(String userId) async {
    try {
      // Get user document
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();

      // Return average rating if it exists
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return (data['averageRating'] ?? 0.0).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Error getting user average rating: $e');
      return 0.0;
    }
  }

  // Update a user's average rating
  Future<void> _updateUserAverageRating(String userId) async {
    try {
      // Get all ratings for the user
      QuerySnapshot ratingsSnapshot =
          await ratingsCollection.where('userId', isEqualTo: userId).get();

      if (ratingsSnapshot.docs.isEmpty) {
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] ?? 0).toDouble();
      }

      double averageRating = totalRating / ratingsSnapshot.docs.length;

      // Update user's average rating
      await usersCollection.doc(userId).update({
        'averageRating': averageRating,
        'ratingCount': ratingsSnapshot.docs.length,
      });
    } catch (e) {
      print('Error updating user average rating: $e');
    }
  }

  // Check if current user has already rated a task
  Future<bool> hasUserRatedTask(String taskId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      QuerySnapshot ratingSnapshot =
          await ratingsCollection
              .where('taskId', isEqualTo: taskId)
              .where('ratedByUserId', isEqualTo: currentUser.uid)
              .get();

      return ratingSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user has rated task: $e');
      return false;
    }
  }

  // Get all ratings given by current user
  Stream<List<Rating>> getRatingsByUser() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return ratingsCollection
        .where('ratedByUserId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
        });
  }
}
