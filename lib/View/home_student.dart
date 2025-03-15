// lib\View\home_student.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/tasks/views/task_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/providers/tasks_provider.dart';

class HomeStudent extends StatelessWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TasksProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Student Home')),
        body: TaskListScreen(),
      ),
    );
  }
}
