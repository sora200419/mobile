// lib\features\tasks\views\add_task_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/models/task.dart';
import 'package:mobiletesting/providers/tasks_provider.dart';
import 'package:mobiletesting/utils/constants/enums.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController =
      TextEditingController(); // For simplicity, using a text field
  DateTime? _selectedDeadline;
  // Add controllers for other fields as needed

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _addTask() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle the case where the user is not logged in.  This should not happen
        // if your app's flow is correct, but it's good to have a check.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not logged in!')));
        return;
      }

      final newTask = Task(
        id: '', // Firestore will generate the ID
        title: _titleController.text,
        description: _descriptionController.text,
        userId: user.uid, // Use the current user's UID
        postedAt: DateTime.now(),
        deadline: _selectedDeadline,
        category: _categoryController.text, // Get the category
        status: RunnerTaskStatus.pending, // Initial status
        rewardPoints: 10.0, // Set a default reward, or let the user choose
        isCompleted: false,
      );

      try {
        await Provider.of<TasksProvider>(
          context,
          listen: false,
        ).addTask(newTask);
        Navigator.pop(context); // Go back to the previous screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task added successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category (e.g., Errand, Tutoring)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Deadline: '),
                  TextButton(
                    onPressed: () => _selectDeadline(context),
                    child: Text(
                      _selectedDeadline == null
                          ? 'Select Date'
                          : "${_selectedDeadline!.toLocal()}".split(' ')[0],
                    ),
                  ),
                ],
              ),
              // Add more fields here as needed (e.g., location, image upload)
              SizedBox(height: 24),
              ElevatedButton(onPressed: _addTask, child: Text('Post Task')),
            ],
          ),
        ),
      ),
    );
  }
}
