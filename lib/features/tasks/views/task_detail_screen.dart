// lib\features\tasks\views\task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/providers/tasks_provider.dart';
import 'package:mobiletesting/utils/constants/enums.dart';
import 'package:provider/provider.dart';

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
    _task = await Provider.of<TasksProvider>(
      context,
      listen: false,
    ).getTaskById(widget.taskId);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateTaskStatus(RunnerTaskStatus newStatus) async {
    try {
      await Provider.of<TasksProvider>(
        context,
        listen: false,
      ).updateTaskStatus(widget.taskId, newStatus);
      // Refresh the task details after updating the status
      await _fetchTask();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task status updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task status: $e')),
      );
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
    return Scaffold(
      appBar: AppBar(title: Text('Task Details')),
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
            Text('Status: ${_task!.status}'),
            SizedBox(height: 8),
            Text('Posted At: ${_task!.postedAt.toLocal()}'),
            SizedBox(height: 8),
            Text('Deadline: ${_task!.deadline?.toLocal() ?? "No Deadline"}'),
            SizedBox(height: 8),
            Text('Reward Points: ${_task!.rewardPoints}'),
            SizedBox(height: 8),
            Text('Location: ${_task!.location ?? "No Location"}'),
            //SizedBox(height: 8),
            //Text('Image: ${_task!.imageUrl ?? "No Image"}'), // Display the image later
            SizedBox(height: 8),
            Text('Completed: ${_task!.isCompleted ? "Yes" : "No"}'),
            SizedBox(height: 16),
            if (_task!.status ==
                RunnerTaskStatus.pending) // Only show if pending
              ElevatedButton(
                onPressed: () => _updateTaskStatus(RunnerTaskStatus.inProgress),
                child: Text(
                  'Accept Task (Runner)',
                ), // This button is for Runner, so you might want to show in other UI
              ),
            if (_task!.status ==
                RunnerTaskStatus.inProgress) // Only show if in progress
              ElevatedButton(
                onPressed: () => _updateTaskStatus(RunnerTaskStatus.completed),
                child: Text(
                  'Complete Task (Runner)',
                ), // This button is for Runner, so you might want to show in other UI
              ),
            // Add more details here
          ],
        ),
      ),
    );
  }
}
