// lib/providers/tasks_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/services/firebase_service.dart'; // We'll create this
import 'package:mobiletesting/utils/constants/enums.dart';

class TasksProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService =
      FirebaseService(); // Instance of the service
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  // Fetch tasks for a specific user (student)
  Future<void> fetchTasks(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              // .orderBy('postedAt', descending: true) // Optional: Order by posting time
              .get();

      _tasks =
          querySnapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
      notifyListeners();
    } catch (error) {
      print("Error fetching tasks: $error");
      // Handle error appropriately (e.g., show a message to the user)
    }
  }

  // Fetch all tasks for runner
  Future<void> fetchAllTasks() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('tasks')
              //.where('userId', isEqualTo: userId)
              .orderBy(
                'postedAt',
                descending: true,
              ) // Optional: Order by posting time
              .get();

      _tasks =
          querySnapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
      notifyListeners();
    } catch (error) {
      print("Error fetching tasks: $error");
      // Handle error appropriately (e.g., show a message to the user)
    }
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    try {
      // Use FirebaseService to add the task and get the generated ID
      String taskId = await _firebaseService.addTask(task);

      // Update local task list
      _tasks.add(task.copyWith(id: taskId)); // Add task with Firestore ID
      notifyListeners();
    } catch (error) {
      print("Error adding task: $error");
      // Handle the error appropriately
    }
  }

  // Update task status (e.g., when a runner accepts it)
  Future<void> updateTaskStatus(
    String taskId,
    RunnerTaskStatus newStatus,
  ) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus.toString(),
      });
      //Optimistic update: update local list as well.
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (error) {
      print("Error updaing task: $error");
    }
  }

  // Update task details (if needed)
  Future<void> updateTask(String taskId, Task updatedTask) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update(updatedTask.toMap());

      //Optimistic update
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
        notifyListeners();
      }
    } catch (error) {
      print("Error updaing task: $error");
    }
  }

  //get a single task by its ID
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
      return null;
    }
  }
}
