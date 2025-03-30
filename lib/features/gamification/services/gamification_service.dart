// lib/features/gamification/services/gamification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuslink/features/gamification/constants/gamification_rules.dart';
import 'package:campuslink/features/gamification/models/leaderboard_model.dart';
import 'package:campuslink/features/gamification/models/user_progress_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference achievementsCollection = FirebaseFirestore.instance
      .collection('achievements');
  final CollectionReference tasksCollection = FirebaseFirestore.instance
      .collection('tasks');
  final CollectionReference streaksCollection = FirebaseFirestore.instance
      .collection('streaks');
  final CollectionReference challengesCollection = FirebaseFirestore.instance
      .collection('challenges');
  final CollectionReference userActivitiesCollection = FirebaseFirestore
      .instance
      .collection('user_activities');

  // Award points to a user for an activity
  Future<void> awardPoints(String userId, int points, String activity) async {
    try {
      // Get current points
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();

      // Check if user document exists
      if (!userDoc.exists) {
        print('User document does not exist for ID: $userId');
        // Create user document with initial points (only if positive)
        int initialPoints = points > 0 ? points : 0;
        await usersCollection.doc(userId).set({
          'points': initialPoints,
          'level': 1,
          'levelName': GamificationRules.getLevelName(1),
        });

        // Record the activity
        await _recordActivity(userId, activity, 'Earned $initialPoints points');
        return;
      }

      int currentPoints =
          (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;

      // Calculate new points, ensuring we don't go below 0
      int newPoints = currentPoints + points;
      if (newPoints < 0) newPoints = 0;

      // Check if this changes the level
      int currentLevel = (userDoc.data() as Map<String, dynamic>)['level'] ?? 1;
      int newLevel = _calculateLevel(newPoints);
      bool levelChanged = newLevel != currentLevel;

      // Update user's points and level if needed
      if (levelChanged) {
        await usersCollection.doc(userId).update({
          'points': newPoints,
          'level': newLevel,
          'levelName': GamificationRules.getLevelName(newLevel),
        });

        if (newLevel > currentLevel) {
          // Level up notification
          await _recordActivity(
            userId,
            'level_up',
            'Reached level $newLevel: ${GamificationRules.getLevelName(newLevel)}',
          );
        } else {
          // Level down notification
          await _recordActivity(
            userId,
            'level_down',
            'Dropped to level $newLevel: ${GamificationRules.getLevelName(newLevel)}',
          );
        }
      } else {
        await usersCollection.doc(userId).update({'points': newPoints});
      }

      // Record the activity with appropriate message based on point change
      String actionMsg = points >= 0 ? 'Earned' : 'Lost';
      int absPoints = points.abs();
      await _recordActivity(userId, activity, '$actionMsg $absPoints points');

      // Also store in the points_earned activity type for leaderboard calculations
      await userActivitiesCollection.add({
        'userId': userId,
        'type': 'points_earned',
        'points': points,
        'activityType': activity,
        'timestamp': DateTime.now(),
      });

      // Check for achievements after point update
      await checkForAchievements(userId);
    } catch (e) {
      print('Error awarding points: $e');
    }
  }

  // Record user activity for analytics and achievement tracking
  Future<void> _recordActivity(
    String userId,
    String type,
    String description,
  ) async {
    try {
      await userActivitiesCollection.add({
        'userId': userId,
        'type': type,
        'description': description,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error recording activity: $e');
    }
  }

  // Calculate user level based on total points
  int _calculateLevel(int points) {
    int level = 1;
    for (var entry in GamificationRules.LEVEL_THRESHOLDS.entries) {
      if (points >= entry.value) {
        level = entry.key;
      } else {
        break;
      }
    }
    return level;
  }

  // Get user's current progress (points, level, etc.)
  Future<UserProgress> getUserProgress(String userId) async {
    try {
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();

      // If user document doesn't exist, create it with default values
      if (!userDoc.exists) {
        await usersCollection.doc(userId).set({
          'points': 0,
          'level': 1,
          'levelName': GamificationRules.getLevelName(1),
        });
        userDoc = await usersCollection.doc(userId).get();
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      int points = userData['points'] ?? 0;
      int level = userData['level'] ?? 1;
      String levelName =
          userData['levelName'] ?? GamificationRules.getLevelName(1);

      // Calculate points needed for next level
      int nextLevel = level + 1;
      int pointsForCurrentLevel =
          GamificationRules.LEVEL_THRESHOLDS[level] ?? 0;
      int pointsForNextLevel =
          GamificationRules.LEVEL_THRESHOLDS[nextLevel] ?? 0;
      int pointsNeeded = pointsForNextLevel - pointsForCurrentLevel;
      int currentLevelPoints = points - pointsForCurrentLevel;
      double progressPercent =
          pointsNeeded > 0 ? currentLevelPoints / pointsNeeded : 1.0;

      // Get user's rank on the leaderboard
      int rank = await getUserRank(userId);

      return UserProgress(
        userId: userId,
        points: points,
        level: level,
        levelName: levelName,
        progressToNextLevel: progressPercent,
        pointsToNextLevel: pointsNeeded - currentLevelPoints,
        rank: rank,
      );
    } catch (e) {
      print('Error getting user progress: $e');
      return UserProgress(
        userId: userId,
        points: 0,
        level: 1,
        levelName: GamificationRules.getLevelName(1),
        progressToNextLevel: 0.0,
        pointsToNextLevel: GamificationRules.LEVEL_THRESHOLDS[2] ?? 50,
        rank: 0,
      );
    }
  }

  // Check and award achievements based on user activity
  Future<void> checkForAchievements(String userId) async {
    try {
      print('Checking achievements for user: $userId');

      // Get user's current achievements
      QuerySnapshot achievementsSnapshot =
          await achievementsCollection.where('userId', isEqualTo: userId).get();

      List<String> currentAchievements =
          achievementsSnapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['achievementId']
                        as String,
              )
              .toList();

      print('Current achievements: $currentAchievements');

      // Check each possible achievement
      await _checkTaskMasterAchievement(userId, currentAchievements);
      await _checkFiveStarAchievement(userId, currentAchievements);
      await _checkTrustedPartnerAchievement(userId, currentAchievements);
      await _checkCategorySpecificAchievements(userId, currentAchievements);
      await _checkEarlyBirdAchievement(userId, currentAchievements);
      await _checkSpeedyDeliveryAchievement(userId, currentAchievements);

      // Add more achievement checks as needed
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Example achievement check: Task Master (complete 10 tasks)
  Future<void> _checkTaskMasterAchievement(
    String userId,
    List<String> currentAchievements,
  ) async {
    if (currentAchievements.contains('task_master')) return;

    try {
      // Count completed tasks for this user
      QuerySnapshot completedTasksSnapshot =
          await tasksCollection
              .where('providerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      print(
        'Task master check: Found ${completedTasksSnapshot.docs.length} completed tasks',
      );

      if (completedTasksSnapshot.docs.length >= 10) {
        // Award the achievement
        await _awardAchievement(userId, 'task_master');
        print('Awarded task_master achievement to user: $userId');
      }
    } catch (e) {
      print('Error checking task master achievement: $e');
    }
  }

  // Example achievement check: Five Star (receive 5 five-star ratings)
  Future<void> _checkFiveStarAchievement(
    String userId,
    List<String> currentAchievements,
  ) async {
    if (currentAchievements.contains('five_star')) return;

    try {
      // Count 5-star ratings for this user
      QuerySnapshot ratingsSnapshot =
          await _firestore
              .collection('ratings')
              .where('userId', isEqualTo: userId)
              .where('rating', isEqualTo: 5.0)
              .get();

      print(
        'Five star check: Found ${ratingsSnapshot.docs.length} 5-star ratings',
      );

      if (ratingsSnapshot.docs.length >= 5) {
        // Award the achievement
        await _awardAchievement(userId, 'five_star');
        print('Awarded five_star achievement to user: $userId');
      }
    } catch (e) {
      print('Error checking five star achievement: $e');
    }
  }

  // Achievement check: Early Bird (accept 5 tasks within 10 minutes of posting)
  Future<void> _checkEarlyBirdAchievement(
    String userId,
    List<String> currentAchievements,
  ) async {
    if (currentAchievements.contains('early_bird')) return;

    try {
      // Count quick acceptances activities
      QuerySnapshot quickAcceptanceSnapshot =
          await userActivitiesCollection
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: 'quick_acceptance')
              .get();

      print(
        'Early bird check: Found ${quickAcceptanceSnapshot.docs.length} quick acceptances',
      );

      if (quickAcceptanceSnapshot.docs.length >= 5) {
        // Award the achievement
        await _awardAchievement(userId, 'early_bird');
        print('Awarded early_bird achievement to user: $userId');
      }
    } catch (e) {
      print('Error checking early bird achievement: $e');
    }
  }

  // Achievement check: Speedy Delivery (complete 5 tasks ahead of schedule)
  Future<void> _checkSpeedyDeliveryAchievement(
    String userId,
    List<String> currentAchievements,
  ) async {
    if (currentAchievements.contains('speedy_delivery')) return;

    try {
      // Get tasks completed by this user
      QuerySnapshot completedTasksSnapshot =
          await tasksCollection
              .where('providerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      // Count tasks completed early
      int earlyCompletions = 0;

      for (var doc in completedTasksSnapshot.docs) {
        // Get associated activity for early completion
        QuerySnapshot earlyCompletionSnapshot =
            await userActivitiesCollection
                .where('userId', isEqualTo: userId)
                .where('taskId', isEqualTo: doc.id)
                .where('type', isEqualTo: 'early_completion')
                .get();

        if (earlyCompletionSnapshot.docs.isNotEmpty) {
          earlyCompletions++;
        }
      }

      print('Speedy delivery check: Found $earlyCompletions early completions');

      if (earlyCompletions >= 5) {
        // Award the achievement
        await _awardAchievement(userId, 'speedy_delivery');
        print('Awarded speedy_delivery achievement to user: $userId');
      }
    } catch (e) {
      print('Error checking speedy delivery achievement: $e');
    }
  }

  // Example achievement check: Trusted Partner (complete tasks for 10 different requesters)
  Future<void> _checkTrustedPartnerAchievement(
    String userId,
    List<String> currentAchievements,
  ) async {
    if (currentAchievements.contains('trusted_partner')) return;

    try {
      // Get completed tasks for this user
      QuerySnapshot completedTasksSnapshot =
          await tasksCollection
              .where('providerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      // Count unique requesters
      Set<String> uniqueRequesters =
          completedTasksSnapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['requesterId']
                        as String,
              )
              .toSet();

      print(
        'Trusted partner check: Found ${uniqueRequesters.length} unique requesters',
      );

      if (uniqueRequesters.length >= 10) {
        // Award the achievement
        await _awardAchievement(userId, 'trusted_partner');
        print('Awarded trusted_partner achievement to user: $userId');
      }
    } catch (e) {
      print('Error checking trusted partner achievement: $e');
    }
  }

  // Example achievement check: Category specific achievements (e.g., Bookworm)
  Future<void> _checkCategorySpecificAchievements(
    String userId,
    List<String> currentAchievements,
  ) async {
    Map<String, String> categoryAchievements = {
      'textbooks': 'bookworm',
      'tech': 'tech_savvy',
      'food': 'food_runner',
    };

    for (var entry in categoryAchievements.entries) {
      String category = entry.key;
      String achievement = entry.value;

      if (currentAchievements.contains(achievement)) continue;

      try {
        // Count completed tasks in this category
        QuerySnapshot categoryTasksSnapshot =
            await tasksCollection
                .where('providerId', isEqualTo: userId)
                .where('status', isEqualTo: 'completed')
                .where('category', isEqualTo: category)
                .get();

        print(
          'Category achievement check for $category: Found ${categoryTasksSnapshot.docs.length} tasks',
        );

        if (categoryTasksSnapshot.docs.length >= 5) {
          // Award the achievement
          await _awardAchievement(userId, achievement);
          print('Awarded $achievement achievement to user: $userId');
        }
      } catch (e) {
        print('Error checking $achievement achievement: $e');
      }
    }
  }

  // Award an achievement to a user
  Future<void> _awardAchievement(String userId, String achievementId) async {
    try {
      // Create the achievement record
      await achievementsCollection.add({
        'userId': userId,
        'achievementId': achievementId,
        'awardedAt': DateTime.now(),
      });

      // Award points for the achievement
      int pointsForAchievement =
          GamificationRules.ACHIEVEMENT_POINTS[achievementId] ?? 0;
      if (pointsForAchievement > 0) {
        await awardPoints(
          userId,
          pointsForAchievement,
          'achievement_$achievementId',
        );
      }

      // Send notification
      String achievementName =
          GamificationRules.ACHIEVEMENTS[achievementId] ?? 'Achievement';
      await _recordActivity(
        userId,
        'achievement',
        'Earned achievement: $achievementName',
      );
    } catch (e) {
      print('Error awarding achievement: $e');
    }
  }

  // Get user's rank on the leaderboard
  Future<int> getUserRank(String userId) async {
    try {
      // Get all users ordered by points
      QuerySnapshot usersSnapshot =
          await usersCollection.orderBy('points', descending: true).get();

      // Find user's position in the ordered list
      for (int i = 0; i < usersSnapshot.docs.length; i++) {
        if (usersSnapshot.docs[i].id == userId) {
          return i + 1; // Rank is 1-based
        }
      }

      return 0; // User not found
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  // Get leaderboard data
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      // Get top users ordered by points
      QuerySnapshot usersSnapshot =
          await usersCollection
              .orderBy('points', descending: true)
              .limit(limit)
              .get();

      // Convert to leaderboard entries
      List<LeaderboardEntry> leaderboard = [];
      for (int i = 0; i < usersSnapshot.docs.length; i++) {
        DocumentSnapshot doc = usersSnapshot.docs[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        leaderboard.add(
          LeaderboardEntry(
            userId: doc.id,
            rank: i + 1,
            username: data['name'] ?? 'Unknown',
            points: data['points'] ?? 0,
            level: data['level'] ?? 1,
          ),
        );
      }

      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Record user login (for streak tracking)
  Future<void> recordUserLogin(String userId) async {
    try {
      // Get current date (normalized to remove time component)
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // Get user's streak document
      DocumentSnapshot streakDoc = await streaksCollection.doc(userId).get();

      if (!streakDoc.exists) {
        // First login - create streak document
        await streaksCollection.doc(userId).set({
          'userId': userId,
          'currentStreak': 1,
          'longestStreak': 1,
          'lastLoginDate': today,
          'loginDates': [today],
        });

        // Award points for first login
        await awardPoints(
          userId,
          GamificationRules.POINTS_DAILY_LOGIN,
          'daily_login',
        );
        return;
      }

      // Get existing streak data
      Map<String, dynamic> streakData =
          streakDoc.data() as Map<String, dynamic>;
      DateTime lastLoginDate =
          (streakData['lastLoginDate'] as Timestamp).toDate();
      int currentStreak = streakData['currentStreak'] ?? 0;
      int longestStreak = streakData['longestStreak'] ?? 0;
      List<Timestamp> loginDates =
          (streakData['loginDates'] as List<dynamic>?)?.cast<Timestamp>() ?? [];

      // Check if user already logged in today
      if (lastLoginDate.year == today.year &&
          lastLoginDate.month == today.month &&
          lastLoginDate.day == today.day) {
        // Already logged in today, nothing to update
        return;
      }

      // Check if this continues a streak (yesterday's login)
      DateTime yesterday = today.subtract(const Duration(days: 1));
      bool continuesStreak =
          lastLoginDate.year == yesterday.year &&
          lastLoginDate.month == yesterday.month &&
          lastLoginDate.day == yesterday.day;

      if (continuesStreak) {
        // Increment streak
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        // Streak broken, start new streak
        currentStreak = 1;
      }

      // Update streak document
      loginDates.add(Timestamp.fromDate(today));
      await streaksCollection.doc(userId).update({
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastLoginDate': today,
        'loginDates': loginDates,
      });

      // Award points for daily login
      await awardPoints(
        userId,
        GamificationRules.POINTS_DAILY_LOGIN,
        'daily_login',
      );

      // Check for streak achievements
      if (currentStreak == 7) {
        await awardPoints(
          userId,
          GamificationRules.POINTS_WEEKLY_LOGIN,
          'login_streak_7_days',
        );
      } else if (currentStreak == 30) {
        await awardPoints(
          userId,
          GamificationRules.POINTS_MONTHLY_LOGIN,
          'login_streak_30_days',
        );

        // Also award the loyal user achievement
        List<String> currentAchievements = await getUserAchievements(userId);
        if (!currentAchievements.contains('loyal_user')) {
          await _awardAchievement(userId, 'loyal_user');
        }
      }
    } catch (e) {
      print('Error recording user login: $e');
    }
  }

  // Get user's current achievements
  Future<List<String>> getUserAchievements(String userId) async {
    try {
      QuerySnapshot achievementsSnapshot =
          await FirebaseFirestore.instance
              .collection('achievements')
              .where('userId', isEqualTo: userId)
              .get();

      return achievementsSnapshot.docs
          .map(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['achievementId'] as String,
          )
          .toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }

  // Award points for early task completion
  Future<void> awardEarlyCompletionPoints(
    String taskId,
    String providerId,
  ) async {
    try {
      // Get task details
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      // Check if task was completed before deadline
      DateTime deadline = (taskData['deadline'] as Timestamp).toDate();
      DateTime now = DateTime.now();

      if (now.isBefore(deadline)) {
        // Task completed early, award bonus points
        await awardPoints(
          providerId,
          GamificationRules.POINTS_EARLY_COMPLETION,
          'early_completion',
        );

        // Log task ID with the early completion for achievement tracking
        await userActivitiesCollection.add({
          'userId': providerId,
          'type': 'early_completion',
          'taskId': taskId,
          'timestamp': DateTime.now(),
        });

        print(
          'Awarded early completion points to user: $providerId for task: $taskId',
        );
      }
    } catch (e) {
      print('Error awarding early completion points: $e');
    }
  }

  // Award points for quick task acceptance
  Future<void> awardQuickAcceptancePoints(
    String taskId,
    String providerId,
  ) async {
    try {
      // Get task details
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      // Check if task was accepted quickly
      DateTime createdAt = (taskData['createdAt'] as Timestamp).toDate();
      DateTime now = DateTime.now();

      // Check if acceptance is within 30 minutes of creation
      if (now.difference(createdAt).inMinutes <= 30) {
        // Task accepted quickly, award bonus points
        await awardPoints(
          providerId,
          GamificationRules.POINTS_QUICK_ACCEPTANCE,
          'quick_acceptance',
        );

        // Log task ID with the quick acceptance for achievement tracking
        await userActivitiesCollection.add({
          'userId': providerId,
          'type': 'quick_acceptance',
          'taskId': taskId,
          'timestamp': DateTime.now(),
        });

        print(
          'Awarded quick acceptance points to user: $providerId for task: $taskId',
        );
      }
    } catch (e) {
      print('Error awarding quick acceptance points: $e');
    }
  }

  // Award points for first task of the day
  Future<void> awardFirstTaskOfDayPoints(String userId, String activity) async {
    try {
      // Get current date (normalized to remove time component)
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // Check if user has already been awarded points for first task today
      QuerySnapshot activitySnapshot =
          await userActivitiesCollection
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: 'first_task_of_day')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(today),
              )
              .where(
                'timestamp',
                isLessThan: Timestamp.fromDate(
                  today.add(const Duration(days: 1)),
                ),
              )
              .get();

      if (activitySnapshot.docs.isEmpty) {
        // First task of the day, award bonus points
        await awardPoints(
          userId,
          GamificationRules.POINTS_FIRST_TASK_OF_DAY,
          'first_task_of_day',
        );
        print('Awarded first task of day points to user: $userId');
      }
    } catch (e) {
      print('Error awarding first task of day points: $e');
    }
  }

  // Check for weekly perfect completion
  Future<void> checkWeeklyPerfectCompletion(String userId) async {
    try {
      // Get current date information for week calculation
      DateTime now = DateTime.now();
      // Start of current week (Sunday)
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      startOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      // End of current week (Saturday)
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

      // Get all tasks assigned to this provider this week
      QuerySnapshot assignedTasksSnapshot =
          await tasksCollection
              .where('providerId', isEqualTo: userId)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(endOfWeek))
              .get();

      // Check if there are any assigned tasks
      if (assignedTasksSnapshot.docs.isEmpty) {
        return;
      }

      // Check if all assigned tasks are completed
      bool allCompleted = assignedTasksSnapshot.docs.every((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'completed';
      });

      print(
        'Weekly perfect completion check: All completed: $allCompleted, Task count: ${assignedTasksSnapshot.docs.length}',
      );

      if (allCompleted) {
        // Check if user has already been awarded points for perfect week
        QuerySnapshot perfectWeekSnapshot =
            await userActivitiesCollection
                .where('userId', isEqualTo: userId)
                .where('type', isEqualTo: 'perfect_week')
                .where(
                  'timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
                )
                .where('timestamp', isLessThan: Timestamp.fromDate(endOfWeek))
                .get();

        if (perfectWeekSnapshot.docs.isEmpty) {
          // Award points for perfect week
          await awardPoints(
            userId,
            GamificationRules.POINTS_PERFECT_WEEK,
            'perfect_week',
          );

          // Check for perfect week achievement
          List<String> currentAchievements = await getUserAchievements(userId);
          if (!currentAchievements.contains('perfect_week')) {
            await _awardAchievement(userId, 'perfect_week');
            print('Awarded perfect_week achievement to user: $userId');
          }
        }
      }
    } catch (e) {
      print('Error checking weekly perfect completion: $e');
    }
  }

  // Public method for unlocking achievements - to be used by other services
  Future<void> unlockAchievement(
    String userId,
    String achievementId,
    String achievementName,
  ) async {
    try {
      // Check if user already has this achievement
      List<String> currentAchievements = await getUserAchievements(userId);
      if (currentAchievements.contains(achievementId)) {
        // Already has achievement, nothing to do
        return;
      }

      // Award the achievement using the private method
      await _awardAchievement(userId, achievementId);

      // Record a more descriptive activity
      await _recordActivity(
        userId,
        'achievement',
        'Earned achievement: $achievementName',
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }
}
