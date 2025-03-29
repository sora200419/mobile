// // lib\features\task\views\task_list_screen.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:mobiletesting/features/task/model/task_model.dart';

// class TaskService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Points awarded for different activities
//   static const int POINTS_CREATE_TASK = 5;
//   static const int POINTS_COMPLETE_TASK = 10;
//   // Points for accepting a task will be based on the task's reward points

//   // Collection references
//   final CollectionReference tasksCollection = FirebaseFirestore.instance
//       .collection('tasks');
//   final CollectionReference usersCollection = FirebaseFirestore.instance
//       .collection('users');

//   // Create a new task
//   Future<String> createTask(Task task) async {
//     try {
//       // Add task to Firestore
//       DocumentReference docRef = await tasksCollection.add(task.toMap());

//       // Award points to the user for creating a task
//       await _awardPoints(task.requesterId, POINTS_CREATE_TASK);

//       return docRef.id;
//     } catch (e) {
//       print('Error creating task: $e');
//       throw e;
//     }
//   }

//   // Get all available tasks (status = 'open')
//   Stream<List<Task>> getAvailableTasks() {
//     return tasksCollection
//         .where('status', isEqualTo: 'open')
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
//         });
//   }

//   // Get my created tasks
//   Stream<List<Task>> getMyTasks() {
//     String userId = _auth.currentUser?.uid ?? '';

//     return tasksCollection
//         .where('requesterId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
//         });
//   }

//   // Get tasks I've accepted as a provider
//   Stream<List<Task>> getMyAcceptedTasks() {
//     String userId = _auth.currentUser?.uid ?? '';

//     return tasksCollection
//         .where('providerId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
//         });
//   }

//   // Accept a task (for service providers)
//   Future<void> acceptTask(String taskId) async {
//     try {
//       // Get current user
//       User? user = _auth.currentUser;
//       if (user == null) throw Exception('User not logged in');

//       // Get user name
//       DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();
//       String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '';

//       // Update task status
//       await tasksCollection.doc(taskId).update({
//         'providerId': user.uid,
//         'providerName': userName,
//         'status': 'assigned',
//       });

//       // Get task details for reward points
//       DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
//       Task task = Task.fromFirestore(taskDoc);

//       // Award points for accepting a task based on task's reward points
//       await _awardPoints(user.uid, task.rewardPoints);
//     } catch (e) {
//       print('Error accepting task: $e');
//       throw e;
//     }
//   }

//   // Mark task as completed
//   Future<void> completeTask(String taskId) async {
//     try {
//       // Get task details to find provider
//       DocumentSnapshot taskDoc = await tasksCollection.doc(taskId).get();
//       Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

//       String? providerId = taskData['providerId'];

//       // Update task status
//       await tasksCollection.doc(taskId).update({'status': 'completed'});

//       // Award points to provider for completing task
//       if (providerId != null) {
//         await _awardPoints(providerId, POINTS_COMPLETE_TASK);
//       }
//     } catch (e) {
//       print('Error completing task: $e');
//       throw e;
//     }
//   }

//   // Cancel a task
//   Future<void> cancelTask(String taskId) async {
//     try {
//       await tasksCollection.doc(taskId).update({'status': 'cancelled'});
//     } catch (e) {
//       print('Error cancelling task: $e');
//       throw e;
//     }
//   }

//   // Search tasks by title or category
//   Stream<List<Task>> searchTasks(String query) {
//     query = query.toLowerCase();

//     return tasksCollection.where('status', isEqualTo: 'open').snapshots().map((
//       snapshot,
//     ) {
//       return snapshot.docs
//           .map((doc) => Task.fromFirestore(doc))
//           .where(
//             (task) =>
//                 task.title.toLowerCase().contains(query) ||
//                 task.category.toLowerCase().contains(query) ||
//                 task.description.toLowerCase().contains(query),
//           )
//           .toList();
//     });
//   }

//   // Award points to a user
//   Future<void> _awardPoints(String userId, int points) async {
//     try {
//       // Get current points
//       DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
//       int currentPoints =
//           (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;

//       // Update points
//       await usersCollection.doc(userId).update({
//         'points': currentPoints + points,
//       });
//     } catch (e) {
//       print('Error awarding points: $e');
//       // Don't throw here to avoid disrupting the main flow if points can't be awarded
//     }
//   }

//   // Get user's points
//   Future<int> getUserPoints() async {
//     try {
//       String userId = _auth.currentUser?.uid ?? '';
//       if (userId.isEmpty) return 0;

//       DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
//       return (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;
//     } catch (e) {
//       print('Error getting user points: $e');
//       return 0;
//     }
//   }
// }
