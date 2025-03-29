//lib\View\status_tag.dart
import 'package:flutter/material.dart';

class StatusTag extends StatelessWidget {
  final String status;

  StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color backgroundColor;
    Color borderColor;
    IconData icon;

    switch (status) {
      case "open":
        textColor = Colors.green;
        backgroundColor = Color(0xFFECF0ED);
        borderColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case "assigned":
        textColor = Colors.orange;
        backgroundColor = Color(0xFFFFF3E0);
        borderColor = Colors.orange;
        icon = Icons.assignment_turned_in;
        break;
      case "in_transit":
        textColor = Colors.yellow.shade800;
        backgroundColor = Color(0xFFFFFDE0);
        borderColor = Colors.yellow.shade800;
        icon = Icons.directions_walk;
        break;
      case "completed":
        textColor = Colors.blueAccent;
        backgroundColor = Color(0xFFE3F2FD);
        borderColor = Colors.blueAccent;
        icon = Icons.done_all;
        break;
      default:
        textColor = Colors.grey;
        backgroundColor = Colors.grey.shade200;
        borderColor = Colors.grey;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
