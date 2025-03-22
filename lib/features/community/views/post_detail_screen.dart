// lib/features/community/views/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:mobiletesting/features/community/models/community_post.dart';
import 'package:mobiletesting/features/community/services/community_service.dart';
import 'package:mobiletesting/features/community/utils/post_utilities.dart';
import 'package:mobiletesting/features/community/views/components/post_card.dart';
import 'package:mobiletesting/features/community/views/components/comment_section.dart';
import 'package:mobiletesting/features/community/views/create_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  late Stream<CommunityPost?> _postStream;

  @override
  void initState() {
    super.initState();
    _postStream = _communityService.getPost(widget.post.id!);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _communityService.deletePost(widget.post.id!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _sharePost() {
    final String postContent =
        '${widget.post.title}\n\n${widget.post.content}\n\nShared from CampusLink';

    Share.share(postContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(PostUtilities.getPostTypeLabel(widget.post.type)),
        actions: [
          if (widget.post.userId == FirebaseAuth.instance.currentUser?.uid)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(post: widget.post),
                    ),
                  );
                } else if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: StreamBuilder<CommunityPost?>(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final post = snapshot.data;
          if (post == null) {
            return const Center(
              child: Text('Post not found or has been deleted'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                PostCard(post: post, isDetailed: true),
                if (post.type != PostType.general && post.metadata != null)
                  _buildMetadataSection(post),
                CommentSection(postId: post.id!),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: _sharePost,
              ),
              _buildActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bookmark feature coming soon!'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.report_outlined,
                label: 'Report',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report feature coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.deepPurple.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(CommunityPost post) {
    final metadata = PostUtilities.getFormattedMetadata(post);

    if (metadata.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '${PostUtilities.getPostTypeLabel(post.type)} Details',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${entry.key}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(child: entry.value),
                ],
              ),
            );
          }).toList(),
          const Divider(),
        ],
      ),
    );
  }
}
