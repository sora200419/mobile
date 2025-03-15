// lib/features/tasks/views/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/providers/tasks_provider.dart';
import 'package:mobiletesting/utils/constants/enums.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  TaskDetailScreen({required this.taskId});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTask();
  }

  Future<void> _fetchTask() async {
    try {
      Task? fetchedTask = await Provider.of<TasksProvider>(
        context,
        listen: false,
      ).getTaskById(widget.taskId);
      setState(() {
        _task = fetchedTask;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors, e.g., show an error message
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching task details: $e')),
      );
    }
  }

  Future<void> _updateTaskStatus(RunnerTaskStatus newStatus) async {
    try {
      final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      String? runnerId =
          (newStatus == RunnerTaskStatus.inProgress)
              ? currentUser?.uid
              : null; // Set runnerId on accept
      await Provider.of<TasksProvider>(
        context,
        listen: false,
      ).updateTaskStatus(widget.taskId, newStatus, runnerId);
      // Refresh the task details after updating
      _fetchTask();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task status: $e')),
      );
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Task'),
            content: Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Cancel
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Confirm
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<TasksProvider>(
          context,
          listen: false,
        ).deleteTask(widget.taskId);
        Navigator.pop(context); // Go back to previous page
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task deleted successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete task: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Task Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Task Details')),
        body: Center(child: Text('Task not found.')),
      );
    }

    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    final isOwner = _task!.userId == currentUser?.uid;
    final isRunner = _task!.runnerId == currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
        actions: [
          if (isOwner) // Only show delete button to owner
            IconButton(icon: Icon(Icons.delete), onPressed: _deleteTask),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${_task!.title}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Description: ${_task!.description}'),
            SizedBox(height: 8),
            Text('Category: ${_task!.category}'),
            SizedBox(height: 8),
            Text('Status: ${_task!.status.toString().split('.').last}'),
            SizedBox(height: 8),
            Text('Posted At: ${_task!.postedAt.toLocal()}'),
            SizedBox(height: 8),
            Text('Deadline: ${_task!.deadline?.toLocal() ?? "No Deadline"}'),
            SizedBox(height: 8),
            Text('Reward Points: ${_task!.rewardPoints}'),
            SizedBox(height: 8),
            Text('Location: ${_task!.location ?? "No Location"}'),
            SizedBox(height: 8),
            //  if(_task!.imageUrl != null)
            //     Image.network(_task!.imageUrl!), // Display image if available
            Text('Completed: ${_task!.isCompleted ? "Yes" : "No"}'),
            SizedBox(height: 16),

            // Conditional Buttons (Runner actions)
            if (_task!.status == RunnerTaskStatus.pending &&
                currentUser != null)
              ElevatedButton(
                onPressed: () => _updateTaskStatus(RunnerTaskStatus.inProgress),
                child: Text('Accept Task (Runner)'),
              ),

            if (_task!.status == RunnerTaskStatus.inProgress && isRunner)
              ElevatedButton(
                onPressed: () => _updateTaskStatus(RunnerTaskStatus.completed),
                child: Text('Complete Task (Runner)'),
              ),
          ],
        ),
      ),
    );
  }
}
