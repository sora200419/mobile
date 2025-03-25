import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/data_analysis.dart';
import 'admin/settings.dart';
import 'admin/user_management.dart';
import 'admin/post_details.dart';
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
  int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  String _sortField = 'createdAt';
  bool _sortAscending = false;

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
      Query query = posts
          .orderBy(_sortField, descending: !_sortAscending)
          .limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      List<DocumentSnapshot> filteredDocs =
          snapshot.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String title = (data['title'] ?? '').toString().toLowerCase();
            String content = (data['content'] ?? '').toString().toLowerCase();
            String query = _searchQuery.toLowerCase();
            return title.contains(query) || content.contains(query);
          }).toList();

      if (filteredDocs.length < _limit) {
        _hasMore = false;
      }

      setState(() {
        _postList.addAll(filteredDocs);
        _lastDocument = filteredDocs.isNotEmpty ? filteredDocs.last : null;
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
              child: Text("Delete", style: TextStyle(color: Colors.red)),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sort Posts"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Sort by Time (Newest First)"),
                onTap: () {
                  setState(() {
                    _sortField = 'createdAt';
                    _sortAscending = false;
                    _postList.clear();
                    _lastDocument = null;
                    _hasMore = true;
                    _fetchPosts();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("Sort by Time (Oldest First)"),
                onTap: () {
                  setState(() {
                    _sortField = 'createdAt';
                    _sortAscending = true;
                    _postList.clear();
                    _lastDocument = null;
                    _hasMore = true;
                    _fetchPosts();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("Sort by Report Count (High to Low)"),
                onTap: () {
                  setState(() {
                    _sortField = 'metadata.reportCount';
                    _sortAscending = false;
                    _postList.clear();
                    _lastDocument = null;
                    _hasMore = true;
                    _fetchPosts();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("Sort by Report Count (Low to High)"),
                onTap: () {
                  setState(() {
                    _sortField = 'metadata.reportCount';
                    _sortAscending = true;
                    _postList.clear();
                    _lastDocument = null;
                    _hasMore = true;
                    _fetchPosts();
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Posts',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.grey),
                  onPressed: _showFilterDialog,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _postList.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _fetchPosts();
                });
              },
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child:
                _postList.isEmpty && !_isLoading
                    ? Center(
                      child: Text(
                        "No posts found",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _postList.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _postList.length) {
                          var data =
                              _postList[index].data() as Map<String, dynamic>;
                          String createdAt = timeago.format(
                            data['createdAt'].toDate(),
                          );
                          List<dynamic>? imageUrls =
                              data['imageUrls'] as List<dynamic>?;
                          String? firstImageUrl =
                              (imageUrls != null && imageUrls.isNotEmpty)
                                  ? imageUrls[0] as String
                                  : null;

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading:
                                  firstImageUrl != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          firstImageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  CircleAvatar(
                                                    child: Text(
                                                      data['userName']?[0] ??
                                                          'U',
                                                    ),
                                                  ),
                                        ),
                                      )
                                      : CircleAvatar(
                                        child: Text(
                                          data['userName']?[0] ?? 'U',
                                        ),
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
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => _confirmDelete(
                                          context,
                                          _postList[index].id,
                                        ),
                                  ),
                                ],
                              ),
                              onTap: () {
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
                            ),
                          );
                        } else if (_isLoading) {
                          return Center(child: CircularProgressIndicator());
                        } else {
                          return Container();
                        }
                      },
                    ),
          ),
        ),
      ],
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
                "No products found",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }
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
