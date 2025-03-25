import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailsPage extends StatelessWidget {
  final String postId;

  const PostDetailsPage({required this.postId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Post not found'));
          }

          var postData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic>? imageUrls = postData['imageUrls'] as List<dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrls != null && imageUrls.isNotEmpty)
                  Column(
                    children: imageUrls
                        .map(
                          (imageUrl) => Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),
                Text(
                  postData['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'By: ${postData['userName'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted: ${timeago.format(postData['createdAt'].toDate())}',
                ),
                const SizedBox(height: 16),
                Text(postData['content'] ?? 'No Content'),
                const SizedBox(height: 16),
                const Text(
                  'Comments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildCommentsList(context, postData['comments'] ?? []),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _confirmDeletePost(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete Post'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context, List<dynamic> comments) {
    if (comments.isEmpty) {
      return const Text('No comments yet.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        var comment = comments[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(comment['userName'] ?? 'Unknown'),
          subtitle: Text(comment['content'] ?? 'No comment'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDeleteComment(context, index),
          ),
        );
      },
    );
  }

  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete Post"),
          content: const Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(postId)
                    .delete();
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // back to post list
                // TODO: 添加操作日志
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteComment(BuildContext context, int commentIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete Comment"),
          content: const Text("Are you sure you want to delete this comment?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[200]),
              child: const Text("Confirm Delete"),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(postId)
                    .update({
                  'comments': FieldValue.arrayRemove([commentIndex]),
                });
                Navigator.of(context).pop();
                // TODO: 添加操作日志
              },
            ),
          ],
        );
      },
    );
  }
}