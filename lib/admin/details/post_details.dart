import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'comments_page.dart';
import 'package:campuslink/admin/details/user_details.dart';

class PostDetailsPage extends StatelessWidget {
  final String postId;

  const PostDetailsPage({Key? key, required this.postId}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchPostData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('community_posts')
              .doc(postId)
              .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Post"),
          content: Text("This action cannot be undone. Delete this post?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('community_posts')
                      .doc(postId)
                      .delete();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error deleting post: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Post Details",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchPostData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Fail loading post"));
          }

          var data = snapshot.data!;
          String userName = data['userName'] ?? 'Unknown';
          String userId = data['userId'] ?? '';
          Timestamp createdAt = data['createdAt'] ?? Timestamp.now();
          String title = data['title'] ?? 'No Title';
          String content = data['content'] ?? 'No Content';
          List<dynamic>? imageUrls = data['imageUrls'] as List<dynamic>?;
          int reportCount = data['reportCount'] ?? 0;

          // date format "HH:mm · MM-dd-yyyy"
          DateTime dateTime = createdAt.toDate();
          String formattedTime = DateFormat('HH:mm').format(dateTime);
          String formattedDate = DateFormat('MM-dd-yyyy').format(dateTime);
          String formattedDateTime = '$formattedTime · $formattedDate';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User information and delete function
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // user profile with clickable avatar
                          GestureDetector(
                            onTap: () {
                              if (userId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            UserDetailPage(userId: userId),
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.teal[200],
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // username and time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  formattedDateTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // delete function and report count
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(context),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Reported\n$reportCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      // post content
                      if (imageUrls != null && imageUrls.isNotEmpty) ...[
                        // image
                        GestureDetector(
                          onTap: () => _showImageDialog(context, imageUrls[0]),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrls[0],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image,
                                        size: 100,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                      // title and content
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  content,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.comment, color: Colors.teal),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            CommentsPage(postId: postId),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
