import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/admin/details/user_details.dart';
import 'package:mobiletesting/admin/admin_management.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';
  String? _selectedRole;
  String _sortField = 'points'; // Default sort by points
  bool _isDescending = true;

  @override
  Widget build(BuildContext context) {
    // Rating option only enable for runner
    bool isRatingEnabled = _selectedRole == 'Runner';
    if (_sortField == 'averageRating' && !isRatingEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _sortField = 'points';
        });
      });
    }

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
                // Filter role
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _selectedRole ?? 'All',
                    isExpanded: true,
                    items:
                        ['All', 'Student', 'Runner']
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
                // Sort field
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _sortField,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: 'points',
                        child: Text('Points'),
                      ),
                      DropdownMenuItem(
                        value: 'averageRating',
                        enabled: isRatingEnabled,
                        child: Text(
                          'Rating',
                          style: TextStyle(
                            color: isRatingEnabled ? Colors.black : Colors.grey,
                          ),
                        ), // Disable if not Runner
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortField = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Sort order toggle
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

                // Search by name
                var filteredUsers =
                    users.where((doc) {
                      var user = doc.data() as Map<String, dynamic>;
                      String name =
                          (user['name'] ?? '').toString().toLowerCase();
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
                    var user =
                        filteredUsers[index].data() as Map<String, dynamic>;

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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: Icon(leadingIcon),
                        title: Text(
                          user['name'] ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle:
                            user['role'] == 'Runner'
                                ? ClipRect(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "${(user['averageRating'] ?? 0.0).toStringAsFixed(1)} "
                                          "(${user['ratingCount'] ?? 0} reviews)",
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : null,
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Only show points for both roles
                              Text(
                                "${user['points'] ?? 0} pts",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UserDetailPage(
                                    userId: filteredUsers[index].id,
                                  ),
                            ),
                          );
                        },
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

  Stream<QuerySnapshot> _buildUserStream() {
    Query query = FirebaseFirestore.instance.collection('users');

    if (_selectedRole != null) {
      query = query.where('role', isEqualTo: _selectedRole);
    } else {

      query = query.where('role', whereIn: ['Student', 'Runner']);
    }

    query = query.orderBy(_sortField, descending: _isDescending);

    if (_sortField != 'role') {
      query = query.orderBy('role');
    }
    query = query.orderBy('name');

    return query.snapshots();
  }
}
