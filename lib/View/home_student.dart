// lib\View\home_student.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/tasks/views/task_list_screen.dart'; // Import
import 'package:provider/provider.dart'; // Import
import 'package:mobiletesting/providers/tasks_provider.dart'; // Import

class HomeStudent extends StatelessWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Wrap with ChangeNotifierProvider
      create: (context) => TasksProvider(),
      child: Scaffold(
        // Add Scaffold here
        appBar: AppBar(title: const Text('Student Home')),
        body: TaskListScreen(), // Use TaskListScreen
      ),
    );
  }
}
