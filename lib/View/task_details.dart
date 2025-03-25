import 'package:flutter/material.dart';
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Color(0xFFECF0ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _updateTaskStatus(context, task.id!, task.status);
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

  void _updateTaskStatus(BuildContext context, String taskId, String currentStatus){
    String newStatus;
    switch(currentStatus){
      case 'open':
        newStatus = 'assigned';
        break;
      case 'assigned':
        newStatus = 'in_transit';
        break;
      case 'in_transit':
        newStatus = 'completed';
        break;
      default:
        return;
    }

    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': newStatus}).then((_){
      Navigator.pop(context);
    }).catchError((error){
      print("Error updating task status: $error");
    });
  }
}

// Todo: change color open assigned completed (getButtonColor fucntion)
