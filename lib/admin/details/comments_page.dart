import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:mobiletesting/admin/details/user_details.dart';

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final Map<String, bool> _expandedStates = {};

  // format date
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('HH:mm').format(dateTime);
    String formattedDate = DateFormat('MM-dd-yyyy').format(dateTime);
    return '$formattedTime · $formattedDate';
  }

  // delete comment
  Future<void> _deleteComment(String commentId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      // Update comment count
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({'commentCount': FieldValue.increment(-1)});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete comment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);
    final CollectionReference comments = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId)
        .collection('comments');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: StreamBuilder<QuerySnapshot>(
          stream: comments.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.black54),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "No comments found",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                String commentId = docs[index].id;
                String userId = data['userId'] ?? '';

                // initial expanded state
                _expandedStates.putIfAbsent(commentId, () => false);
                bool isExpanded = _expandedStates[commentId]!;

                // Alternate background colors
                final bgColor =
                    index % 2 == 0 ? Colors.grey[200] : Colors.grey[300];

                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar with clickable functionality
                      GestureDetector(
                        onTap: () {
                          if (userId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailPage(
                                  userId: userId,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User ID not found'),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: Text(
                              data['userName']?.isNotEmpty == true
                                  ? data['userName'][0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.teal[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Comment content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data['userName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  data['createdAt'] != null
                                      ? _formatTimestamp(data['createdAt'])
                                      : 'Unknown time',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _expandedStates[commentId] = !isExpanded;
                                });
                              },
                              child: Text(
                                data['content'] ?? 'No Content',
                                style: const TextStyle(fontSize: 15),
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete button
                      IconButton(
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red[600],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Comment"),
                              content: const Text(
                                "This action cannot be undone. Delete this comment?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteComment(commentId, context);
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}