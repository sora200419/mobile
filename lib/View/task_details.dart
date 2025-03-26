import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/status_tag.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/features/task/views/task_chat_screen.dart';

class TaskDetailsPage extends StatelessWidget {
  final Task task;

  String _getButtonLabel(String status) {
    switch (status) {
      case 'open':
        return 'Accept';
      case 'assigned':
        return 'Picked Up';
      case 'in_transit':
        return 'Completed';
      default:
        return 'Accept';
    }
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green[50]!;
      case 'assigned':
        return Colors.orange[50]!;
      case 'in_transit':
        return Colors.lightBlue[50]!;
      default:
        return Colors.green[50]!;
    }
  }

  TaskDetailsPage({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusTag(status: task.status),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      task.category,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),
            _buildDetailRow("Description", task.description),
            SizedBox(height: 16),
            _buildDetailRow(
              "Reward Points",
              "${task.rewardPoints} points",
              icon: Icons.stars_rounded,
              iconColor: Colors.amber,
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              "Location",
              task.location,
              icon: Icons.location_on,
              iconColor: Colors.red,
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              "Deadline",
              DateFormat('dd/MM/yyyy').format(task.deadline),
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              "Requested By",
              task.requesterName,
              icon: Icons.person,
              iconColor: Colors.purple,
            ),
            SizedBox(height: 25),
            Divider(),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (task.status != 'completed')
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _updateTask(context, task.id!, task.status);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getButtonColor(task.status),
                        ),
                        icon: Icon(Icons.check_circle),
                        label: Text(_getButtonLabel(task.status)),
                      ),
                    ),
                  ),
                if (task.providerId != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskChatScreen(task: task),
                            ),
                          );
                        },
                        icon: Icon(Icons.chat),
                        label: Text("Chat"),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String title,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 24),
              SizedBox(width: 8),
            ],
            Text(value),
          ],
        ),
      ],
    );
  }

  void _updateTask(
    BuildContext context,
    String taskId,
    String currentStatus,
  ) async {
    // Import TaskService and GamificationService
    final taskService = TaskService();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      switch (currentStatus) {
        case 'open':
          // Accept the task using TaskService
          await taskService.acceptTask(taskId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          break;

        case 'assigned':
          // Mark task as in transit using TaskService
          await taskService.markTaskInTransit(taskId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task marked as in transit'),
              backgroundColor: Colors.blue,
            ),
          );
          break;

        case 'in_transit':
          // Complete the task using TaskService
          await taskService.completeTask(taskId);

          // The completeTask method includes achievement checking logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          break;

        default:
          // No action needed for other statuses
          Navigator.pop(context); // Close the loading dialog
          return;
      }

      // Close the loading dialog and the task details page
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Return to previous screen
    } catch (error) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error message
      print("Error updating task: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _getCurrentRunnerName() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          return (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Runner';
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return 'Runner';
  }
}
