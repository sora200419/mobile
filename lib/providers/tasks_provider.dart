// lib/providers/tasks_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/services/firebase_service.dart';
import 'package:mobiletesting/utils/constants/enums.dart';

class TasksProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  // Fetch tasks for a specific user (student)
  Future<void> fetchTasks(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .orderBy('postedAt', descending: true)
              .get();

      _tasks =
          querySnapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
      notifyListeners();
    } catch (error) {
      print("Error fetching tasks: $error");
      // Consider throwing the error or handling it with a user-friendly message.
    }
  }

  // Fetch all tasks (for runner)
  Future<void> fetchAllTasks() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .orderBy('postedAt', descending: true)
              .get();
      _tasks =
          querySnapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
      notifyListeners();
    } catch (error) {
      print("Error fetching all tasks: $error");
    }
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    try {
      String taskId = await _firebaseService.addTask(task);
      _tasks.add(task.copyWith(id: taskId));
      notifyListeners();
    } catch (error) {
      print("Error adding task: $error");
      // Consider throwing the error or handling it with a user-friendly message.
    }
  }

  // Update task status (e.g., when a runner accepts it) and runnerId
  Future<void> updateTaskStatus(
    String taskId,
    RunnerTaskStatus newStatus, [
    String? runnerId,
  ]) async {
    try {
      await _firebaseService.updateTaskStatus(taskId, newStatus, runnerId);
      // Optimistic update: update local list as well.
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(
          status: newStatus,
          runnerId: runnerId,
        );
        notifyListeners();
      }
    } catch (error) {
      print("Error updating task status: $error");
    }
  }

  // Update task details (if needed)
  Future<void> updateTask(String taskId, Task updatedTask) async {
    try {
      await _firebaseService.updateTask(taskId, updatedTask);
      //Optimistic update
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
        notifyListeners();
      }
    } catch (error) {
      print("Error updating task: $error");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firebaseService.deleteTask(taskId);
      //Optimistic update
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (error) {
      print("Error deleting task: $error");
    }
  }

  //get a single task by its ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      return await _firebaseService.getTaskById(taskId);
    } catch (error) {
      print("Error getting task by ID: $error");
      return null;
    }
  }
}
