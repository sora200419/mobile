// lib/features/community/views/components/post_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobiletesting/features/community/models/community_post_model.dart';
import 'package:mobiletesting/features/community/services/community_service.dart';
import 'package:mobiletesting/features/community/utils/post_utilities.dart';
import 'package:mobiletesting/features/community/views/post_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobiletesting/features/marketplace/services/cloudinary_service.dart';
import 'package:mobiletesting/features/community/services/post_share_service.dart';

class PostCard extends StatefulWidget {
  final CommunityPost post;
  final bool isDetailed;

  const PostCard({Key? key, required this.post, this.isDetailed = false})
    : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final CommunityService _communityService = CommunityService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final PostShareService _postShareService = PostShareService();
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isShareLoading = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _checkIfBookmarked();
  }

  Future<void> _checkIfLiked() async {
    if (widget.post.id != null) {
      final liked = await _communityService.hasUserLikedPost(widget.post.id!);
      if (mounted) {
        setState(() {
          _isLiked = liked;
        });
      }
    }
  }

  Future<void> _checkIfBookmarked() async {
    if (widget.post.id != null) {
      final bookmarked = await _communityService.isPostBookmarked(
        widget.post.id!,
      );
      if (mounted) {
        setState(() {
          _isBookmarked = bookmarked;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading || widget.post.id == null) return;

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
              isBookmarked ? 'Post saved' : 'Post removed from saved',
            ),
            duration: const Duration(seconds: 1),
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
    if (_isShareLoading || widget.post.id == null) return;

    setState(() {
      _isShareLoading = true;
    });

    try {
      await _postShareService.sharePost(context, widget.post);
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            widget.isDetailed
                ? null
                : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: widget.post),
                    ),
                  );
                },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            if (widget.post.imageUrls.isNotEmpty) _buildImages(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              widget.post.userName.isNotEmpty
                  ? widget.post.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.deepPurple.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPostTypeBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'MMM d, yyyy • h:mm a',
                  ).format(widget.post.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: PostUtilities.getPostTypeColor(widget.post.type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        PostUtilities.getPostTypeLabel(widget.post.type),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            widget.post.content,
            style: const TextStyle(fontSize: 16),
            maxLines: widget.isDetailed ? null : 3,
            overflow: widget.isDetailed ? null : TextOverflow.ellipsis,
          ),
          if (!widget.isDetailed && widget.post.content.length > 100)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Read more',
                style: TextStyle(
                  color: Colors.deepPurple.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    if (widget.post.imageUrls.isEmpty) {
      debugPrint('No images to display for post ${widget.post.id}');
      return const SizedBox.shrink();
    }

    debugPrint(
      'Building images for post ${widget.post.id}: ${widget.post.imageUrls}',
    );

    if (widget.post.imageUrls.length == 1) {
      final optimizedUrl = _cloudinaryService.getOptimizedImageUrl(
        widget.post.imageUrls.first,
        width: 800,
        height: 400,
        quality: 85,
      );

      debugPrint('Optimized URL for display: $optimizedUrl');

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: optimizedUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 32, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        'Error: $error',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                widget.isDetailed
                    ? widget.post.imageUrls.length
                    : widget.post.imageUrls.length > 3
                    ? 3
                    : widget.post.imageUrls.length,
            itemBuilder: (context, index) {
              if (!widget.isDetailed &&
                  index == 2 &&
                  widget.post.imageUrls.length > 3) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _cloudinaryService.getOptimizedImageUrl(
                          widget.post.imageUrls[index],
                          width: 200,
                          height: 200,
                          quality: 75,
                        ),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${widget.post.imageUrls.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _cloudinaryService.getOptimizedImageUrl(
                      widget.post.imageUrls[index],
                      width: 200,
                      height: 200,
                      quality: 75,
                    ),
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error, size: 20),
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (widget.post.id != null) {
                await _communityService.likePost(widget.post.id!);
                await _checkIfLiked();
              }
            },
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : null,
            ),
          ),
          Text(
            '${widget.post.likes}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              if (!widget.isDetailed && widget.post.id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: widget.post),
                  ),
                );
              }
            },
            icon: const Icon(Icons.comment_outlined),
          ),
          Text(
            '${widget.post.commentCount}',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          // New bookmark button
          IconButton(
            onPressed: _toggleBookmark,
            icon:
                _isBookmarkLoading
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    )
                    : Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? Colors.deepPurple : null,
                    ),
          ),

          const Spacer(),

          // Share button
          IconButton(
            onPressed: _isShareLoading ? null : _sharePost,
            icon:
                _isShareLoading
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                    : const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }
}
