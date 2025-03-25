import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../details/post_details.dart';
import '../details/comments_page.dart';
import 'package:timeago/timeago.dart' as timeago;

enum PostFilter { newest, oldest, mostReports }

class PostsTab extends StatefulWidget {
  @override
  _PostsTabState createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  final CollectionReference posts =
      FirebaseFirestore.instance.collection('community_posts');
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _postList = [];
  int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  String _sortField = 'createdAt';
  bool _sortAscending = false;
  PostFilter? _activeFilter;

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
    setState(() => _isLoading = true);

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
        return title.contains(_searchQuery.toLowerCase()) ||
            content.contains(_searchQuery.toLowerCase());
      }).toList();

      setState(() {
        _postList.addAll(filteredDocs);
        _lastDocument = filteredDocs.isNotEmpty ? filteredDocs.last : null;
        _hasMore = filteredDocs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() => _isLoading = false);
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
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("This action cannot be undone. Delete this post?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              try {
                await posts.doc(docId).delete();
                setState(() => _postList.removeWhere((doc) => doc.id == docId));
                Navigator.pop(context);
              } catch (e) {
                print('Error deleting post: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _applyFilter(PostFilter filter) {
    setState(() {
      _activeFilter = filter;
      switch (filter) {
        case PostFilter.newest:
          _sortField = 'createdAt';
          _sortAscending = false;
          break;
        case PostFilter.oldest:
          _sortField = 'createdAt';
          _sortAscending = true;
          break;
        case PostFilter.mostReports:
          _sortField = 'reportCount';
          _sortAscending = false;
          break;
      }
      _resetAndFetch();
    });
  }

  void _resetFilters() {
    setState(() {
      _activeFilter = null;
      _sortField = 'createdAt';
      _sortAscending = false;
      _resetAndFetch();
    });
  }

  void _resetAndFetch() {
    _postList.clear();
    _lastDocument = null;
    _hasMore = true;
    _fetchPosts();
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // sort by time
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Newest'),
              selected: _activeFilter == PostFilter.newest,
              onSelected: (_) => _applyFilter(PostFilter.newest),
              selectedColor: Colors.teal,
              labelStyle: TextStyle(
                color: _activeFilter == PostFilter.newest
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Oldest'),
              selected: _activeFilter == PostFilter.oldest,
              onSelected: (_) => _applyFilter(PostFilter.oldest),
              selectedColor: Colors.teal,
              labelStyle: TextStyle(
                color: _activeFilter == PostFilter.oldest
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          // filter by report count
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Most Reported'),
              selected: _activeFilter == PostFilter.mostReports,
              onSelected: (_) => _applyFilter(PostFilter.mostReports),
              selectedColor: Colors.teal,
              labelStyle: TextStyle(
                color: _activeFilter == PostFilter.mostReports
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          // delte icon
          if (_activeFilter != null)
            ActionChip(
              label: const Text('Clear All'),
              onPressed: _resetFilters,
              backgroundColor: Colors.grey[200],
              labelStyle: const TextStyle(color: Colors.black54),
              avatar: const Icon(
                Icons.close,
                size: 18,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // search bas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search posts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _resetAndFetch();
              });
            },
          ),
        ),

        _buildFilterChips(),

        // post list
        Expanded(
          child: _postList.isEmpty && !_isLoading
              ? const Center(
                  child: Text(
                    "No posts found",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      bool hasImages = imageUrls != null && imageUrls.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailsPage(
                                postId: _postList[index].id,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        data['userName']?.isNotEmpty == true
                                            ? data['userName'][0].toUpperCase()
                                            : 'U',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['userName'] ?? 'Unknown',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          createdAt,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    if (data['reportCount'] > 0)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.report,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${data['reportCount']}',
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['content'] ?? 'No Content',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasImages) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 120,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: imageUrls.length,
                                      itemBuilder: (context, imgIndex) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            imageUrls[imgIndex],
                                            width: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(
                                              Icons.broken_image,
                                              size: 120,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.comment),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CommentsPage(
                                            postId: _postList[index].id,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirmDelete(context, _postList[index].id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }
}