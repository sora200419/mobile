import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/admin/details/post_details.dart';
import 'package:mobiletesting/admin/details/product_details.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({required this.userId, Key? key}) : super(key: key);

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _postsExpanded = false;
  bool _commentsExpanded = false;
  bool _productsExpanded = false;

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date = timestamp.toDate();
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading user data",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "User not found",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          var user = snapshot.data!.data() as Map<String, dynamic>;
          String name = user['name'] ?? 'Unknown';
          String email = user['email'] ?? 'N/A';
          String role = user['role'] ?? 'N/A';
          int points = user['points'] ?? 0;
          int level = user['level'] ?? 0;
          String levelName = user['levelName'] ?? 'N/A';
          bool isBanned = user['isBanned'] ?? false;
          double? averageRating = user['averageRating'] as double?;
          int? ratingCount = user['ratingCount'] as int?;

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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow("Role", role),
                      const SizedBox(height: 8),
                      _buildInfoRow("Email", email),
                      const SizedBox(height: 8),
                      _buildInfoRow("Points", points.toString()),
                      const SizedBox(height: 8),
                      _buildInfoRow("Level", "$level ($levelName)"),
                      const SizedBox(height: 8),
                      if (role == 'Runner' &&
                          averageRating != null &&
                          ratingCount != null) ...[
                        _buildInfoRow(
                          "Average Rating",
                          "${averageRating.toStringAsFixed(1)} ($ratingCount reviews)",
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow("Status", isBanned ? "Banned" : "Active"),
                      const SizedBox(height: 8),
                      const Divider(),
                      if (role.toLowerCase() == 'student') ...[
                        _buildExpandableSection(
                          context,
                          "Posts",
                          _postsExpanded,
                          () =>
                              setState(() => _postsExpanded = !_postsExpanded),
                          _buildPostsList(widget.userId),
                        ),
                        const SizedBox(height: 8),
                        _buildExpandableSection(
                          context,
                          "Comments",
                          _commentsExpanded,
                          () => setState(
                            () => _commentsExpanded = !_commentsExpanded,
                          ),
                          _buildCommentsList(widget.userId),
                        ),
                        const SizedBox(height: 8),
                        _buildExpandableSection(
                          context,
                          "Products",
                          _productsExpanded,
                          () => setState(
                            () => _productsExpanded = !_productsExpanded,
                          ),
                          _buildProductsList(widget.userId),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                      ],
                      Center(
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed:
                                  isBanned
                                      ? null
                                      : () async {
                                        await _temporaryBanUser(
                                          context,
                                          widget.userId,
                                        );
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Temporary Ban"),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed:
                                  isBanned
                                      ? null
                                      : () async {
                                        await _permanentBanUser(
                                          context,
                                          widget.userId,
                                        );
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Permanent Ban"),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed:
                                  !isBanned
                                      ? null
                                      : () async {
                                        await _unbanUser(
                                          context,
                                          widget.userId,
                                        );
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Unban User"),
                            ),
                          ],
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    String title,
    bool isExpanded,
    VoidCallback onTap,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.teal,
              ),
            ],
          ),
        ),
        if (isExpanded) content,
      ],
    );
  }

  Widget _buildPostsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('community_posts')
              .where('userId', isEqualTo: userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading posts: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No posts found');
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                var post = doc.data() as Map<String, dynamic>;
                String createdAt = _formatDate(post['createdAt'] as Timestamp?);
                String postContent = post['content'] ?? '';
                // cut the content too long
                String displayContent =
                    postContent.length > 50
                        ? '${postContent.substring(0, 50)}...'
                        : postContent;
                return ListTile(
                  title: Text(post['title'] ?? 'Untitled'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(displayContent), Text('Date: $createdAt')],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsPage(postId: doc.id),
                      ),
                    );
                  },
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildCommentsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collectionGroup('comments')
              .where('userId', isEqualTo: userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading comments: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No comments found');
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                var comment = doc.data() as Map<String, dynamic>;
                String createdAt = _formatDate(
                  comment['createdAt'] as Timestamp?,
                );
                String commentContent = comment['content'] ?? 'No content';
                // cut the content too long
                String displayContent =
                    commentContent.length > 50
                        ? '${commentContent.substring(0, 50)}...'
                        : commentContent;

                // get community_posts for title
                return FutureBuilder<DocumentSnapshot>(
                  future: doc.reference.parent.parent!.get(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    if (postSnapshot.hasError) {
                      return const ListTile(
                        title: Text('Error loading post title'),
                      );
                    }
                    if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                      return const ListTile(title: Text('Post not found'));
                    }

                    var post =
                        postSnapshot.data!.data() as Map<String, dynamic>;
                    String postTitle = post['title'] ?? 'Untitled';

                    return ListTile(
                      title: Text(postTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayContent),
                          Text('Date: $createdAt'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PostDetailsPage(postId: comment['postId']),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildProductsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading products: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No products found');
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                var product = doc.data() as Map<String, dynamic>;
                String createdAt = _formatDate(
                  product['createdAt'] as Timestamp?,
                );
                return ListTile(
                  title: Text(product['title'] ?? 'Untitled'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: ${product['price'] ?? 0}'),
                      Text('Date: $createdAt'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductDetailsPage(
                              productId: doc.id,
                              productData: product,
                            ),
                      ),
                    );
                  },
                );
              }).toList(),
        );
      },
    );
  }

  Future<void> _temporaryBanUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': true,
        'banType': 'temporary',
        'banStart': Timestamp.now(),
        'banEnd': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User temporarily integral banned for 7 days"),
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error banning user: $e")));
    }
  }

  Future<void> _permanentBanUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': true,
        'banType': 'permanent',
        'banStart': Timestamp.now(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User permanently banned")));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error banning user: $e")));
    }
  }

  Future<void> _unbanUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': false,
        'banType': null,
        'banStart': null,
        'banEnd': null,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User unbanned successfully")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error unbanning user: $e")));
    }
  }
}
