import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuslink/admin/details/post_details.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isDescending = true;

  // format date
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // report details dialog
  void _showReportDetails(
    BuildContext context,
    Map<String, dynamic> reportData,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Report Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason: ${reportData['reason'] ?? 'No reason provided'}'),
                SizedBox(height: 10),
                Text(
                  'Additional Info: ${reportData['additionalInfo'] ?? 'None'}',
                ),
                SizedBox(height: 10),
                Text(
                  'Reported at: ${_formatTimestamp(reportData['createdAt'])}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PostDetailsPage(postId: reportData['postId']),
                    ),
                  );
                },
                child: Text('View Post', style: TextStyle(color: Colors.teal)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isDescending = !_isDescending; // Toggle sort direction
              });
            },
            tooltip: 'Toggle sort order',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('reports')
                .where('status', isEqualTo: 'pending')
                .orderBy(
                  'createdAt',
                  descending: _isDescending,
                ) // Use dynamic sort
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending reports'));
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var report = reports[index];
              var reportData = report.data() as Map<String, dynamic>;
              String userId = reportData['userId'] ?? 'Unknown User';
              String postId = reportData['postId'] ?? 'Unknown Post';

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      leading: Icon(Icons.report, color: Colors.teal),
                      title: Text('Reported by: Unknown User'),
                      subtitle: Text('Post: Unknown Post'),
                      trailing: Text(
                        _formatTimestamp(reportData['createdAt']),
                        style: TextStyle(color: Colors.grey),
                      ),
                      onTap: () => _showReportDetails(context, reportData),
                    );
                  }

                  String reporterName =
                      userSnapshot.data!.get('name') ?? 'Anonymous';

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('posts').doc(postId).get(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(title: Text('Loading...'));
                      }
                      if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                        return ListTile(
                          leading: Icon(Icons.report, color: Colors.teal),
                          title: Text('Reported by: $reporterName'),
                          subtitle: Text('Post: [Post Not Found]'),
                          trailing: Text(
                            _formatTimestamp(reportData['createdAt']),
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () => _showReportDetails(context, reportData),
                        );
                      }

                      String postTitle =
                          postSnapshot.data!.get('title') ?? 'Untitled Post';

                      return ListTile(
                        leading: Icon(Icons.report, color: Colors.teal),
                        title: Text('Reported by: $reporterName'),
                        subtitle: Text('Post: $postTitle'),
                        trailing: Text(
                          _formatTimestamp(reportData['createdAt']),
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () => _showReportDetails(context, reportData),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
