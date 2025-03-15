// lib/View/tabs/task_tab.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/tasks/views/add_task_screen.dart';
import 'package:mobiletesting/features/tasks/views/task_detail_screen.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/providers/tasks_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class TaskTab extends StatefulWidget {
  const TaskTab({Key? key}) : super(key: key);

  @override
  State<TaskTab> createState() => _TaskTabState();
}

class _TaskTabState extends State<TaskTab> {
  @override
  void initState() {
    super.initState();
    _fetchTasks(); // Good!  Fetch tasks in initState.
  }

  Future<void> _fetchTasks() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Now, this correctly uses the provider, which is available globally.
      await Provider.of<TasksProvider>(
        context,
        listen: false,
      ).fetchTasks(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep the Scaffold here
      body: Consumer<TasksProvider>(
        builder: (context, tasksProvider, child) {
          if (tasksProvider.tasks.isEmpty) {
            return Center(child: Text('No tasks posted yet.'));
          }
          return ListView.builder(
            itemCount: tasksProvider.tasks.length,
            itemBuilder: (context, index) {
              Task task = tasksProvider.tasks[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Text(task.status.toString().split('.').last),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(taskId: task.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Add FAB
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Task', // Good for accessibility
      ),
    );
  }
}
