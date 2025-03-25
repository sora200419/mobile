import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/status_tag.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailsPage extends StatelessWidget {
  final Task task;

  String _getButtonLabel(String status){
    switch (status){
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

  Color _getButtonColor(String status){
    switch(status){
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
            if(task.status != 'completed')
            Center(
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

  void _updateTask(BuildContext context, String taskId, String currentStatus) async {
    String newStatus;
    switch (currentStatus) {
      case 'open':
        newStatus = 'assigned';
        // 获取当前 runner 的 uid 和 name
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;
        if (user != null) {
          final String providerId = user.uid;
          final String providerName = await _getCurrentRunnerName();
          try {
            await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
              'status': newStatus,
              'providerId': providerId,
              'providerName': providerName,
            });
            Navigator.pop(context);
          } catch (error) {
            print("Error updating task status: $error");
          }
        } else {
          print("Error: User not logged in.");
        }
        return; // Update providerId and providerName when the status is 'open' only
      case 'assigned':
        newStatus = 'in_transit';
        break;
      case 'in_transit':
        newStatus = 'completed';
        break;
      default:
        return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': newStatus});
      Navigator.pop(context);
    } catch (error) {
      print("Error updating task status: $error");
    }
  }

  Future<String> _getCurrentRunnerName() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
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