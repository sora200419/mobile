// lib/features/task/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/gamification/constants/gamification_rules.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/location_service.dart';

class TaskService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();

  // Collection references
  final CollectionReference tasksCollection = FirebaseFirestore.instance
      .collection('tasks');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Create a new task
  Future<String> createTask(Task task) async {
    try {
      // Add task to Firestore
      DocumentReference docRef = await tasksCollection.add(task.toMap());

      // Award points to the user for creating a task through the gamification service
      await _gamificationService.awardPoints(
        task.requesterId,
        GamificationRules.POINTS_CREATE_TASK,
        'create_task',
      );

      // Award first task of day bonus if applicable
      await _gamificationService.awardFirstTaskOfDayPoints(
        task.requesterId,
        'create_task',
      );

      // Log the activity for achievement tracking
      await _recordTaskActivity(task.requesterId, 'create_task', docRef.id);

      return docRef.id;
    } catch (e) {
      print('Error creating task: $e');
      throw e;
    }
  }

  // Get all available tasks (status = 'open')
  Stream<List<Task>> getAvailableTasks() {
    return tasksCollection
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Get my created tasks
  Stream<List<Task>> getMyTasks() {
    String userId = _auth.currentUser?.uid ?? '';

    return tasksCollection
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Get tasks I've accepted as a provider
  Stream<List<Task>> getMyAcceptedTasks() {
    String userId = _auth.currentUser?.uid ?? '';

    return tasksCollection
        .where('providerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  // Accept a task (for service providers)
  Future<void> acceptTask(String taskId) async {
    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name
      DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();
      String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

      // Get task creation time to check for quick acceptance
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Task task = Task.fromFirestore(taskDoc);

      // Update task status
      await tasksCollection.doc(taskId).update({
        'providerId': user.uid,
        'providerName': userName,
        'status': 'assigned',
      });

      // Award points for accepting a task based on task's reward points
      await _gamificationService.awardPoints(
        user.uid,
        task.rewardPoints,
        'accept_task',
      );

      // Log the activity for achievement tracking
      await _recordTaskActivity(user.uid, 'accept_task', taskId);

      // Award quick acceptance bonus if applicable
      DateTime createdAt = task.createdAt;
      DateTime now = DateTime.now();
      if (now.difference(createdAt).inMinutes <= 30) {
        await _gamificationService.awardPoints(
          user.uid,
          GamificationRules.POINTS_QUICK_ACCEPTANCE,
          'quick_acceptance',
        );
      }

      // Award first task of day bonus if applicable
      await _gamificationService.awardFirstTaskOfDayPoints(
        user.uid,
        'accept_task',
      );

      // Check for achievements explicitly
      await _gamificationService.checkForAchievements(user.uid);
    } catch (e) {
      print('Error accepting task: $e');
      throw e;
    }
  }

  // Mark task as in transit
  Future<void> markTaskInTransit(String taskId) async {
    try {
      // Get task details to find provider
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      String? providerId = taskData['providerId'];
      if (providerId == null) {
        throw Exception('Task does not have a provider assigned');
      }

      // Check if current user is the provider
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      if (currentUser.uid != providerId) {
        throw Exception(
          'Only the assigned runner can mark a task as in transit',
        );
      }

      // Update task status
      await tasksCollection.doc(taskId).update({'status': 'in_transit'});

      // Start location tracking
      RunnerLocationService locationService = RunnerLocationService(providerId);
      await locationService.startSharingLocation(taskId);

      // Award points to provider for starting delivery through gamification service
      await _gamificationService.awardPoints(
        providerId,
        GamificationRules.POINTS_IN_TRANSIT,
        'task_in_transit',
      );

      // Log the activity for achievement tracking
      await _recordTaskActivity(providerId, 'task_in_transit', taskId);

      // Check for achievements explicitly
      await _gamificationService.checkForAchievements(providerId);
    } catch (e) {
      print('Error marking task as in transit: $e');
      throw e;
    }
  }

  // Mark task as completed
  Future<void> completeTask(String taskId) async {
    try {
      // Get task details
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Task task = Task.fromFirestore(taskDoc);

      // Stop location tracking if active
      if (task.providerId != null) {
        RunnerLocationService locationService = RunnerLocationService(
          task.providerId!,
        );
        await locationService.stopSharingLocation(taskId);
      }

      // Update task status
      await tasksCollection.doc(taskId).update({'status': 'completed'});

      // Award points to provider for completing task
      if (task.providerId != null) {
        await _gamificationService.awardPoints(
          task.providerId!,
          GamificationRules.POINTS_COMPLETE_TASK_PROVIDER,
          'complete_task_provider',
        );

        // Log the activity for achievement tracking
        await _recordTaskActivity(
          task.providerId!,
          'complete_task_provider',
          taskId,
        );

        // Award points to requester for task completion
        await _gamificationService.awardPoints(
          task.requesterId,
          GamificationRules.POINTS_COMPLETE_TASK_REQUESTER,
          'complete_task_requester',
        );

        // Log the activity for requester achievement tracking
        await _recordTaskActivity(
          task.requesterId,
          'complete_task_requester',
          taskId,
        );

        // Check for early completion bonus
        await _gamificationService.awardEarlyCompletionPoints(
          taskId,
          task.providerId!,
        );

        // Check for perfect week completion
        await _gamificationService.checkWeeklyPerfectCompletion(
          task.providerId!,
        );

        // Check for achievements explicitly for both provider and requester
        await _gamificationService.checkForAchievements(task.providerId!);
        await _gamificationService.checkForAchievements(task.requesterId);
      }
    } catch (e) {
      print('Error completing task: $e');
      throw e;
    }
  }

  // Cancel a task
  Future<void> cancelTask(String taskId) async {
    try {
      // Get task details
      DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
      Task task = Task.fromFirestore(taskDoc);

      // Only deduct points if the task is still in 'open' status
      // This ensures we only deduct points if the task hasn't been accepted yet
      if (task.status == 'open') {
        // Deduct the points that were awarded for creating the task
        await _gamificationService.awardPoints(
          task.requesterId,
          -GamificationRules
              .POINTS_CREATE_TASK, // Negative value to deduct points
          'cancel_task',
        );
      }

      // Stop location tracking if task is in transit
      if (task.status == 'in_transit' && task.providerId != null) {
        RunnerLocationService locationService = RunnerLocationService(
          task.providerId!,
        );
        await locationService.stopSharingLocation(taskId);
      }

      await tasksCollection.doc(taskId).update({'status': 'cancelled'});

      // Log cancellation for both requester and provider (if assigned)
      await _recordTaskActivity(task.requesterId, 'cancel_task', taskId);

      if (task.providerId != null) {
        await _recordTaskActivity(task.providerId!, 'cancel_task', taskId);
      }
    } catch (e) {
      print('Error cancelling task: $e');
      throw e;
    }
  }

  // Record task activity for achievement tracking
  Future<void> _recordTaskActivity(
    String userId,
    String activityType,
    String taskId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('user_activities').add({
        'userId': userId,
        'type': activityType,
        'taskId': taskId,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error recording task activity: $e');
      // Don't throw here to avoid disrupting the main flow
    }
  }

  // Search tasks by title or category
  Stream<List<Task>> searchTasks(String query) {
    query = query.toLowerCase();

    return tasksCollection.where('status', isEqualTo: 'open').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .where(
            (task) =>
                task.title.toLowerCase().contains(query) ||
                task.category.toLowerCase().contains(query) ||
                task.description.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  // Get user's points
  Future<int> getUserPoints() async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return 0;

      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
      return (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;
    } catch (e) {
      print('Error getting user points: $e');
      return 0;
    }
  }

  // Get task by status
  Stream<List<Task>> getTasksByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }
}
