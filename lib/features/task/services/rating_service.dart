// lib\features\task\services\rating_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rate a user (only students can rate runners)
  Future<void> rateUser(
    String taskId,
    String userIdToRate,
    double rating, {
    String? comment,
  }) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Get the task details
      DocumentSnapshot taskDoc =
          await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');

      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      // Check if the task is completed
      if (taskData['status'] != 'completed') {
        throw Exception('Cannot rate a task that is not completed');
      }

      // Check if the current user is the requester (student)
      if (taskData['requesterId'] != currentUser.uid) {
        throw Exception('Only requesters can rate providers');
      }

      // Check if the user to rate is the provider (runner)
      if (taskData['providerId'] != userIdToRate) {
        throw Exception('Invalid rating target');
      }

      // Check if the user has already rated this task
      bool hasRated = await hasUserRatedTask(taskId);
      if (hasRated) {
        throw Exception('You have already rated this task');
      }

      // Get user info for the rating
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      String userName =
          (userDoc.data() as Map<String, dynamic>)['name'] ?? 'User';

      // Create the rating
      await _firestore.collection('ratings').add({
        'taskId': taskId,
        'raterId': currentUser.uid,
        'raterName': userName,
        'ratedUserId': userIdToRate,
        'rating': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the user's average rating
      await _updateUserAverageRating(userIdToRate);
    } catch (e) {
      print('Error rating user: $e');
      throw e;
    }
  }

  // Check if a user has already rated a task
  Future<bool> hasUserRatedTask(String taskId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      QuerySnapshot ratingSnapshot =
          await _firestore
              .collection('ratings')
              .where('taskId', isEqualTo: taskId)
              .where('raterId', isEqualTo: currentUser.uid)
              .get();

      return ratingSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user rated task: $e');
      return false;
    }
  }

  // Get ratings for a specific user
  Stream<List<Map<String, dynamic>>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Update user's average rating
  Future<void> _updateUserAverageRating(String userId) async {
    try {
      // Get all ratings for this user
      QuerySnapshot ratingsSnapshot =
          await _firestore
              .collection('ratings')
              .where('ratedUserId', isEqualTo: userId)
              .get();

      // Calculate average rating
      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in ratingsSnapshot.docs) {
          totalRating += (doc.data() as Map<String, dynamic>)['rating'];
        }
        double averageRating = totalRating / ratingsSnapshot.docs.length;

        // Update user's average rating in Firestore
        await _firestore.collection('users').doc(userId).update({
          'averageRating': averageRating,
          'totalRatings': ratingsSnapshot.docs.length,
        });

        // Check if user qualifies for any rating-based achievements
        if (averageRating >= 4.5 && ratingsSnapshot.docs.length >= 5) {
          // Award the five star achievement if not already awarded
          await _checkAndAwardAchievement(userId, 'five_star');
        }
      }
    } catch (e) {
      print('Error updating user average rating: $e');
    }
  }

  // Check and award an achievement if not already awarded
  Future<void> _checkAndAwardAchievement(
    String userId,
    String achievementId,
  ) async {
    try {
      // Check if user already has this achievement
      QuerySnapshot existingAchievement =
          await _firestore
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .where('achievementId', isEqualTo: achievementId)
              .get();

      if (existingAchievement.docs.isEmpty) {
        // Award the achievement
        await _firestore.collection('achievements').add({
          'userId': userId,
          'achievementId': achievementId,
          'awardedAt': FieldValue.serverTimestamp(),
        });

        // Award points for the achievement
        int pointsToAward = 30; // Points for five_star achievement
        await _awardPointsForAchievement(userId, pointsToAward);
      }
    } catch (e) {
      print('Error checking/awarding achievement: $e');
    }
  }

  // Award points for an achievement
  Future<void> _awardPointsForAchievement(String userId, int points) async {
    try {
      // Get current points
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        int currentPoints =
            (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;

        // Update points
        await _firestore.collection('users').doc(userId).update({
          'points': currentPoints + points,
        });
      }
    } catch (e) {
      print('Error awarding points: $e');
    }
  }
}
