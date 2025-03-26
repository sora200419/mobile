import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/admin/details/user_details.dart';
import 'package:mobiletesting/admin/admin_management.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = ''; 
  String? _selectedRole; 
  String _sortField = 'points'; 
  bool _isDescending = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManagementPage(),
                ),
              );
            },
            tooltip: 'Admin Management',
          ),
        ],
      ),
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // filter role
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _selectedRole ?? 'All',
                    isExpanded: true,
                    items: ['All', 'Student', 'Runner']
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value == 'All' ? null : value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // sequence
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _sortField,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                          value: 'points', child: Text('Points')),
                      const DropdownMenuItem(
                          value: 'averageRating', child: Text('Rating')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortField = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // change sequence
                IconButton(
                  icon: Icon(
                    _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDescending = !_isDescending;
                    });
                  },
                ),
              ],
            ),
          ),

          // user list
          Expanded(
            child: StreamBuilder(
              stream: _buildUserStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;

                // search by name
                var filteredUsers = users.where((doc) {
                  var user = doc.data() as Map<String, dynamic>;
                  String name = (user['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var user = filteredUsers[index].data() as Map<String, dynamic>;

                    IconData leadingIcon;
                    switch (user['role']) {
                      case 'Student':
                        leadingIcon = Icons.school;
                        break;
                      case 'Runner':
                        leadingIcon = Icons.directions_run;
                        break;
                      default:
                        leadingIcon = Icons.person;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(leadingIcon),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text(
                            "${user['role']} - ${user['levelName'] ?? 'N/A'}\nPoints: ${user['points'] ?? 0}\nRating: ${user['averageRating'] ?? 0} (${user['ratingCount'] ?? 0} reviews)"),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserDetailPage(userId: filteredUsers[index].id),
                              ),
                            );
                          },
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

  // search users
  Stream<QuerySnapshot> _buildUserStream() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isNotEqualTo: 'Admin');

    // filter role
    if (_selectedRole != null) {
      query = query.where('role', isEqualTo: _selectedRole);
    }

    // handle null
    query = query.orderBy(_sortField, descending: _isDescending);

    return query.snapshots();
  }
}