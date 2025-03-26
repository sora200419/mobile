import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/services/auth_service.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({Key? key}) : super(key: key);

  String get currentAdminEmail {
    final AuthService authService = AuthService();
    return authService.getCurrentUser()?.email ?? "admin@example.com";
  }

  Future<void> _showCreateAdminDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final AuthService _authService = AuthService();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Create New Admin"),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter an email' : null,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: "Password"),
                      validator:
                          (value) =>
                              value!.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      // 1. Check admin count
                      final adminSnapshot =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'Admin')
                              .get();

                      if (adminSnapshot.docs.length >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Cannot create more than 5 admins"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // 2. Create user using AuthService
                      String? error = await _authService.signup(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        role: 'Admin',
                      );

                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error creating admin: $error"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // 3. Show success and close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Admin created successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Create"),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAdmin(
    BuildContext context,
    String adminId,
    String adminEmail,
  ) async {
    // cannot delete self
    if (adminEmail == currentAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot delete yourself"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // check the number of admin
    final adminSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Admin')
            .get();

    if (adminSnapshot.docs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("At least one admin must remain"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Delete Admin"),
                content: const Text(
                  "This will delete the admin from Firestore only. The Authentication user will remain. Continue?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text("Deleting admin..."),
                ],
              ),
            ),
      );

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin deleted from Firestore successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting admin: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting admin: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Management"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Create New Admin"),
              onPressed: () => _showCreateAdminDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[300],
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'Admin')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No admins found"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final admin = snapshot.data!.docs[index];
                    final data = admin.data() as Map<String, dynamic>;
                    final isCurrentUser = data['email'] == currentAdminEmail;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: Text(data['name'] ?? 'Unknown Admin'),
                        subtitle: Text(data['email'] ?? 'No email'),
                        trailing:
                            isCurrentUser
                                ? const Tooltip(
                                  message: "Current logged-in admin",
                                  child: Icon(Icons.info, color: Colors.blue),
                                )
                                : IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteAdmin(
                                        context,
                                        admin.id,
                                        data['email'],
                                      ),
                                ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
