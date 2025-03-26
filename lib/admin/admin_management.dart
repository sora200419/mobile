import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Management"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Admin') 
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var admins = snapshot.data!.docs;

          if (admins.isEmpty) {
            return const Center(
              child: Text(
                "No admins found",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              var admin = admins[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(admin['name'] ?? 'Unknown'),
                  subtitle: Text(
                      "${admin['role']} - ${admin['levelName']}\nPoints: ${admin['points']}\nRating: ${admin['averageRating']} (${admin['ratingCount']} reviews)"),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.blue),
                    onPressed: () {
                      // TODO: 跳转到管理员详情页（可以复用 UserDetailPage 或创建新的页面）
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) =>
                      //         AdminDetailPage(adminId: admins[index].id),
                      //   ),
                      // );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}