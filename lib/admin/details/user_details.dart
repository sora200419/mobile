import 'package:flutter/material.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;

  UserDetailPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Management")),
      body: Center(
        child: Text("Manage user: $userId"),
      ),
    );
  }
}
