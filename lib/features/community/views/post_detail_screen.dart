// lib/features/community/views/post_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/community/models/community_post.dart';
import 'package:mobiletesting/features/community/services/community_service.dart';
import 'package:mobiletesting/features/community/utils/post_utilities.dart';
import 'package:mobiletesting/features/community/views/components/post_card.dart';
import 'package:mobiletesting/features/community/views/components/comment_section.dart';
import 'package:mobiletesting/features/community/views/create_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobiletesting/features/marketplace/services/cloudinary_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late Stream<CommunityPost?> _postStream;
  bool _isBookmarked = false;
  bool _isShareLoading = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _postStream = _communityService.getPost(widget.post.id!);
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final isBookmarked = await _communityService.isPostBookmarked(
        widget.post.id!,
      );
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      debugPrint('Error checking bookmark status: $e');
    }
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

  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      final isBookmarked = await _communityService.toggleBookmark(
        widget.post.id!,
      );
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarked
                  ? 'Post saved to bookmarks'
                  : 'Post removed from bookmarks',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving post: $e')));
      }
    }
  }

  Future<void> _sharePost() async {
    if (_isShareLoading) return;

    setState(() {
      _isShareLoading = true;
    });

    try {
      // Get post content
      final String postText =
          '${widget.post.title}\n\n${widget.post.content}\n\nShared from CampusLink';

      // Check if post has images
      if (widget.post.imageUrls.isNotEmpty) {
        try {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preparing content to share...')),
          );

          // Download the first image to a temporary file
          final http.Response response = await http.get(
            Uri.parse(widget.post.imageUrls.first),
          );
          final Directory tempDir = await getTemporaryDirectory();
          final String filePath = '${tempDir.path}/shared_image.jpg';
          final File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Share text and image
          await Share.shareXFiles(
            [XFile(filePath)],
            text: postText,
            subject: widget.post.title,
          );
        } catch (e) {
          debugPrint('Error sharing with image, falling back to text: $e');
          // If image sharing fails, fall back to text-only sharing
          await Share.share(postText, subject: widget.post.title);
        }
      } else {
        // Share only text
        await Share.share(postText, subject: widget.post.title);
      }
    } catch (e) {
      debugPrint('Error sharing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShareLoading = false;
        });
      }
    }
  }

  Future<void> _reportPost() async {
    final reportReasons = [
      'Inappropriate content',
      'Spam or misleading',
      'Hate speech',
      'Harassment or bullying',
      'Violence or threatening content',
      'False information',
      'Other',
    ];

    String? selectedReason;
    String additionalInfo = '';
    bool isSubmitting = false;

    final reported = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text('Report Post'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why are you reporting this post?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      for (final reason in reportReasons)
                        RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          activeColor: Colors.deepPurple,
                          onChanged:
                              isSubmitting
                                  ? null
                                  : (value) {
                                    setState(() {
                                      selectedReason = value;
                                    });
                                  },
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Additional information (optional)',
                          border: OutlineInputBorder(),
                          hintText:
                              'Please provide any details that might help us understand the issue',
                          enabled: !isSubmitting,
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          additionalInfo = value;
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Our moderation team will review this report within 24 hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        (selectedReason == null || isSubmitting)
                            ? null
                            : () async {
                              setState(() {
                                isSubmitting = true;
                              });

                              try {
                                await _communityService.reportPost(
                                  postId: widget.post.id!,
                                  reason: selectedReason!,
                                  additionalInfo: additionalInfo,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
                                setState(() {
                                  isSubmitting = false;
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        isSubmitting
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Submitting...'),
                              ],
                            )
                            : const Text('Submit Report'),
                  ),
                ],
              );
            },
          ),
    );

    if (reported == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted. Thank you for keeping our community safe.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    }
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

          // Log image URLs for debugging
          debugPrint(
            'Rendering post with ${post.imageUrls.length} images: ${post.imageUrls}',
          );

          // Use CustomScrollView for better control of the scrolling behavior
          return CustomScrollView(
            slivers: [
              SliverSafeArea(
                bottom: false, // Don't add padding at bottom
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      PostCard(post: post, isDetailed: true),
                      if (post.type != PostType.general &&
                          post.metadata != null)
                        _buildMetadataSection(post),
                      _buildImagesSection(post),
                      CommentSection(postId: post.id!),
                      // Add extra padding to avoid bottom bar overlap
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 80,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  isLoading: _isShareLoading,
                  onPressed: _sharePost,
                ),
                _buildActionButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save',
                  isLoading: _isBookmarkLoading,
                  onPressed: _toggleBookmark,
                ),
                _buildActionButton(
                  icon: Icons.report_outlined,
                  label: 'Report',
                  onPressed: _reportPost,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                )
                : Icon(icon, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.deepPurple.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(CommunityPost post) {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Images',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: post.imageUrls.length,
            itemBuilder: (context, index) {
              final optimizedUrl = _cloudinaryService.getOptimizedImageUrl(
                post.imageUrls[index],
                width: 800,
                height: 600,
                quality: 85,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: optimizedUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error,
                                size: 32,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
        ],
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
