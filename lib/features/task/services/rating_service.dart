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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Points awarded for different activities
  static const int POINTS_GOOD_RATING = 2; // For ratings >= 4
  // Points awarded to requester for good service received
  static const int POINTS_REQUESTER_GOOD_SERVICE = 3; // For good ratings
  // Points awarded to requester for completing the task
  static const int POINTS_REQUESTER_TASK_COMPLETED = 2; // For task completion

  // Collection references
  final CollectionReference ratingsCollection = FirebaseFirestore.instance
      .collection('ratings');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference tasksCollection = FirebaseFirestore.instance
      .collection('tasks');

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

      // Check if user has already rated this task
      bool alreadyRated = await hasUserRatedTask(taskId);
      if (alreadyRated) {
        throw Exception('You have already rated this task');
      }

      // Add rating to Firestore
      await ratingsCollection.add({
        'taskId': taskId,
        'userId': userId,
        'ratedByUserId': currentUser.uid,
        'rating': rating,
        'comment': comment,
        'timestamp': DateTime.now(),
      });

      // Get task details to identify roles
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      String requesterId = taskData['requesterId'] ?? '';
      String? providerId = taskData['providerId'];

      // Check if the current user is the requester rating the provider
      bool isRequesterRatingProvider =
          currentUser.uid == requesterId && userId == providerId;

      // Check if the current user is the provider rating the requester
      bool isProviderRatingRequester =
          providerId != null &&
          currentUser.uid == providerId &&
          userId == requesterId;

      // Award points for good ratings to service provider
      if (isRequesterRatingProvider && rating >= 4.0) {
        // Get provider's current points
        DocumentSnapshot providerDoc =
            await usersCollection.doc(providerId).get();
        int providerPoints =
            (providerDoc.data() as Map<String, dynamic>)['points'] ?? 0;

        // Update provider's points
        await usersCollection.doc(providerId).update({
          'points': providerPoints + POINTS_GOOD_RATING,
        });
      }

      // Award points to requester for receiving good service or completion
      if (isProviderRatingRequester) {
        // Get requester's current points
        DocumentSnapshot requesterDoc =
            await usersCollection.doc(requesterId).get();
        int requesterPoints =
            (requesterDoc.data() as Map<String, dynamic>)['points'] ?? 0;

        // Determine points to award
        int pointsToAward = POINTS_REQUESTER_TASK_COMPLETED;
        if (rating >= 4.0) {
          pointsToAward += POINTS_REQUESTER_GOOD_SERVICE;
        }

        // Update requester's points
        await usersCollection.doc(requesterId).update({
          'points': requesterPoints + pointsToAward,
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

  // Get specific rating for a task by current user
  Future<Rating?> getUserRatingForTask(String taskId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      QuerySnapshot ratingSnapshot =
          await ratingsCollection
              .where('taskId', isEqualTo: taskId)
              .where('ratedByUserId', isEqualTo: currentUser.uid)
              .get();

      if (ratingSnapshot.docs.isEmpty) {
        return null;
      }

      return Rating.fromFirestore(ratingSnapshot.docs.first);
    } catch (e) {
      print('Error getting user rating for task: $e');
      return null;
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
