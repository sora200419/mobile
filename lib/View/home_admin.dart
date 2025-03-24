import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/data_analysis.dart';
import 'admin/settings.dart';
import 'admin/user_management.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeAdmin extends StatefulWidget {
  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeTabPage(),
    UserManagementPage(),
    DataAnalysisPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "User Management",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Data Analysis",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class HomeTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin"),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
            ),
            tabs: [Tab(text: "Posts"), Tab(text: "Products")],
          ),
        ),
        body: TabBarView(children: [PostsTab(), ProductsTab()]),
      ),
    );
  }
}

class PostsTab extends StatefulWidget {
  @override
  _PostsTabState createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  final CollectionReference posts = FirebaseFirestore.instance.collection(
    'community_posts',
  );
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _postList = [];
  int _limit = 20; // initial loading amount
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = posts.orderBy('createdAt', descending: true).limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }

      setState(() {
        _postList.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPosts();
    }
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
              onPressed: () async {
                try {
                  await posts.doc(docId).delete();
                  setState(() {
                    _postList.removeWhere((doc) => doc.id == docId);
                  });
                  Navigator.of(context).pop();
                  // TODO: 添加操作日志
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _postList.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _postList.length) {
            var data = _postList[index].data() as Map<String, dynamic>;
            String createdAt = timeago.format(data['createdAt'].toDate());
            List<dynamic>? imageUrls = data['imageUrls'] as List<dynamic>?;

            return Card(
              elevation: 4,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  child: Text(data['userName']?[0] ?? 'U'),
                ),
                title: Text(
                  data['title'] ?? 'No Title',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['content'] ?? 'No Content',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${data['userName'] ?? 'Unknown'} - $createdAt',
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (imageUrls != null && imageUrls.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PostDetailsPage(
                                    postId: _postList[index].id,
                                  ),
                            ),
                          );
                        },
                        child: Text('View Image'),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        // TODO: 跳转评论列表
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _confirmDelete(context, _postList[index].id),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PostDetailsPage(postId: _postList[index].id),
                    ),
                  );
                },
              ),
            );
          } else if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class PostDetailsPage extends StatelessWidget {
  final String postId;

  PostDetailsPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('community_posts')
                .doc(postId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Post not found'));
          }

          var postData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic>? imageUrls = postData['imageUrls'] as List<dynamic>?;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrls != null && imageUrls.isNotEmpty)
                  Column(
                    children:
                        imageUrls
                            .map(
                              (imageUrl) => Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                            .toList(),
                  ),
                SizedBox(height: 16),
                Text(
                  postData['title'] ?? 'No Title',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'By: ${postData['userName'] ?? 'Unknown'}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Posted: ${timeago.format(postData['createdAt'].toDate())}',
                ),
                SizedBox(height: 16),
                Text(postData['content'] ?? 'No Content'),
                SizedBox(height: 16),
                Text(
                  'Comments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildCommentsList(context, postData['comments'] ?? []),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _confirmDeletePost(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Delete Post'),
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
      return Text('No comments yet.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        var comment = comments[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(comment['userName'] ?? 'Unknown'),
          subtitle: Text(comment['content'] ?? 'No comment'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
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
          title: Text("Confirm Delete Post"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
            child: Text(
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
          title: Text("Confirm Delete Comment"),
          content: Text("Are you sure you want to delete this comment?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[200]),
              child: Text("Confirm Delete"),
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

class ProductsTab extends StatelessWidget {
  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this product?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                products.doc(docId).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: StreamBuilder<QuerySnapshot>(
        stream: products.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                color: Colors.white,
                child: ListTile(
                  leading:
                      data['imageUrl'] != null
                          ? Image.network(
                            data['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : Icon(Icons.image),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text("Price: \$${data['price'] ?? 'N/A'}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, docs[index].id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
