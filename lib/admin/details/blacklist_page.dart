import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/admin/details/user_details.dart';

class BlacklistPage extends StatefulWidget {
  @override
  _BlacklistPageState createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAscending = true; 
  String? _selectedRole; 


  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Runner':
        return Icons.directions_run;
      case 'Student':
        return Icons.school;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Black List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // filter and sequence button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    hint: Text('Filter by Role'),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Roles'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Runner',
                        child: Text('Runner'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value; 
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                SizedBox(width: 10), 
                IconButton(
                  icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _isAscending = !_isAscending; 
                    });
                  },
                ),
              ],
            ),
          ),
          // user list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('isBanned', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No banned users found'));
                }

                List<QueryDocumentSnapshot> bannedUsers = snapshot.data!.docs;

                // filter by role
                if (_selectedRole != null) {
                  bannedUsers = bannedUsers
                      .where((doc) => doc['role'] == _selectedRole)
                      .toList();
                }

                // sort by banstart
                bannedUsers.sort((a, b) {
                  Timestamp? aBanStart = a['banStart'] as Timestamp?;
                  Timestamp? bBanStart = b['banStart'] as Timestamp?;
                  if (aBanStart == null && bBanStart == null) return 0;
                  if (aBanStart == null) return _isAscending ? 1 : -1;
                  if (bBanStart == null) return _isAscending ? -1 : 1;
                  return _isAscending
                      ? aBanStart.compareTo(bBanStart)
                      : bBanStart.compareTo(aBanStart);
                });

                if (bannedUsers.isEmpty) {
                  return Center(child: Text('No users match the selected role'));
                }

                return ListView.builder(
                  itemCount: bannedUsers.length,
                  itemBuilder: (context, index) {
                    var userDoc = bannedUsers[index];
                    String userId = userDoc.id;
                    String name = userDoc['name'] ?? 'Unnamed';
                    String role = userDoc['role'] ?? 'Unknown';

                    return ListTile(
                      leading: Icon(
                        _getRoleIcon(role),
                        color: Colors.teal,
                      ),
                      title: Text(name),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailPage(userId: userId),
                          ),
                        );
                      },
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