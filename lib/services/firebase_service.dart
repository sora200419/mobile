// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/models/task.dart';

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
      rethrow; // Re-throw the error to be handled by the caller
    }
  }

  Future<void> updateTask(
    String taskId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update(updatedData);
    } catch (e) {
      print("Error updating task in Firestore: $e");
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      print("Error deleting task from Firestore: $e");
      rethrow;
    }
  }

  // Add other Firestore-related methods here (e.g., getTask, updateTask, deleteTask)
}
