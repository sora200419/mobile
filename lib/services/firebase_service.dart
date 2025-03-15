// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/utils/constants/enums.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addTask(Task task) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('tasks')
          .add(task.toMap());
      return docRef.id; // Return the generated ID
    } catch (e) {
      print("Error adding task to Firestore: $e");
      rethrow; // Re-throw the error so the caller can handle it
    }
  }

  Future<void> updateTask(String taskId, Task updatedTask) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update(updatedTask.toMap());
    } catch (error) {
      print("Error updating task: $error");
      rethrow;
    }
  }

  Future<void> updateTaskStatus(
    String taskId,
    RunnerTaskStatus newStatus, [
    String? runnerId,
  ]) async {
    try {
      Map<String, dynamic> updates = {'status': newStatus.toString()};
      // Only update runnerId if it's provided (for accepting tasks)
      if (runnerId != null) {
        updates['runnerId'] = runnerId;
      }
      await _firestore.collection('tasks').doc(taskId).update(updates);
    } catch (error) {
      print("Error updating task status: $error");
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (error) {
      print("Error deleting task: $error");
      rethrow;
    }
  }

  // Add other Firestore methods here (e.g., updateTask, deleteTask, etc.)
  Future<Task?> getTaskById(String taskId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        return Task.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return null; //Task not found
      }
    } catch (error) {
      print("Error getting task by ID: $error");
      rethrow;
    }
  }
}
