// lib\features\tasks\views\task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/tasks/views/add_task_screen.dart'
    show AddTaskScreen;
import 'package:mobiletesting/features/tasks/views/task_detail_screen.dart'
    show TaskDetailScreen;
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/providers/tasks_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch tasks when the screen is initialized
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Provider.of<TasksProvider>(
        context,
        listen: false,
      ).fetchTasks(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Tasks')),
      body: Consumer<TasksProvider>(
        builder: (context, tasksProvider, child) {
          if (tasksProvider.tasks.isEmpty) {
            return Center(child: Text('No tasks posted yet.'));
          }

          return ListView.builder(
            itemCount: tasksProvider.tasks.length,
            itemBuilder: (context, index) {
              Task task = tasksProvider.tasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Text(task.status.toString()), // Display the status
                onTap: () {
                  // Navigate to task detail screen (to be implemented)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(taskId: task.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AddTaskScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
