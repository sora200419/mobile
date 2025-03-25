import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../post_details.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostsTab extends StatefulWidget {
  @override
  _PostsTabState createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  final CollectionReference posts = FirebaseFirestore.instance.collection('community_posts');
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _postList = [];
  int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  String _sortField = 'createdAt';
  bool _sortAscending = false;
  String? _selectedFilter;

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
      Query query = posts.orderBy(_sortField, descending: !_sortAscending).limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      List<DocumentSnapshot> filteredDocs = snapshot.docs.where((doc) {
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
    String? tempFilter = _selectedFilter;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter Posts"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text("Filter by Time"),
                    value: 'createdAt',
                    groupValue: tempFilter,
                    onChanged: (value) {
                      setState(() {
                        tempFilter = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text("Filter by Report Count"),
                    value: 'metadata.reportCount',
                    groupValue: tempFilter,
                    onChanged: (value) {
                      setState(() {
                        tempFilter = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Clear Filter"),
              onPressed: () {
                setState(() {
                  _selectedFilter = null;
                  _sortField = 'createdAt';
                  _sortAscending = false;
                  _searchQuery = '';
                  _postList.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _fetchPosts();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Apply"),
              onPressed: () {
                setState(() {
                  _selectedFilter = tempFilter;
                  _sortField = tempFilter ?? 'createdAt';
                  _sortAscending = false;
                  _postList.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _fetchPosts();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _postList.clear();
      _lastDocument = null;
      _hasMore = true;
      _fetchPosts();
    });
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
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Posts',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.grey,
                      ),
                      onPressed: _toggleSortOrder,
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.grey),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
            child: _postList.isEmpty && !_isLoading
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
                        var data = _postList[index].data() as Map<String, dynamic>;
                        String createdAt = timeago.format(data['createdAt'].toDate());
                        List<dynamic>? imageUrls = data['imageUrls'] as List<dynamic>?;
                        String? firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] as String : null;

                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: firstImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      firstImageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                        child: Text(data['userName']?[0] ?? 'U'),
                                      ),
                                    ),
                                  )
                                : CircleAvatar(
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
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, _postList[index].id),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailsPage(
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