import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsPage extends StatelessWidget {
  final String postId;

  const CommentsPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CollectionReference comments = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(postId)
        .collection('comments');

    return Scaffold(
      appBar: AppBar(
        title: Text("Comments"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: comments.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No comments found",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['content'] ?? 'No Content'),
                subtitle: Text(
                  'By ${data['userName'] ?? 'Unknown'} at ${data['createdAt']?.toDate().toString() ?? 'Unknown time'}',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}