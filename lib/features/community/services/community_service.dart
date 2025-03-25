// lib/features/community/services/community_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/community/models/community_post.dart';
import 'package:mobiletesting/features/community/models/comment.dart';
import 'package:mobiletesting/features/gamification/services/gamification_service.dart';
import 'package:mobiletesting/features/marketplace/services/cloudinary_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Collection references
  CollectionReference get _postsCollection =>
      _firestore.collection('community_posts');
  CollectionReference _commentsCollection(String postId) =>
      _firestore.collection('community_posts/$postId/comments');
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');

  // Get all posts with optional filtering
  Stream<List<CommunityPost>> getPosts({PostType? filterType}) {
    Query query = _postsCollection.orderBy('createdAt', descending: true);

    // Apply filter if provided
    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.index);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => CommunityPost.fromDocument(doc)).toList(),
    );
  }

  // Get posts by user ID
  Stream<List<CommunityPost>> getUserPosts(String userId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => CommunityPost.fromDocument(doc))
                  .toList(),
        );
  }

  // Get a single post by ID
  Stream<CommunityPost?> getPost(String postId) {
    return _postsCollection
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists ? CommunityPost.fromDocument(doc) : null);
  }

  // Create a new post
  Future<String> createPost({
    required String title,
    required String content,
    required PostType type,
    List<File> images = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user name from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc['name'] ?? 'Anonymous';

      // Upload images if any, with error handling
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        try {
          debugPrint('Uploading ${images.length} images to Cloudinary');
          imageUrls = await _uploadImages(images);
          debugPrint(
            'Successfully uploaded ${imageUrls.length} images: $imageUrls',
          );
        } catch (e) {
          debugPrint('Warning: Failed to upload images: $e');
          // Continue without images rather than failing the entire post creation
        }
      }

      // Create post
      final post = CommunityPost(
        userId: user.uid,
        userName: userName,
        type: type,
        title: title,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        metadata: metadata,
        reportCount: 0,
      );

      // Save post to Firestore
      final docRef = await _postsCollection.add(post.toMap());

      // Verify the post was saved with images
      final savedDoc = await _postsCollection.doc(docRef.id).get();
      final savedPost = CommunityPost.fromDocument(savedDoc);
      debugPrint(
        'Saved post with ${savedPost.imageUrls.length} images: ${savedPost.imageUrls}',
      );

      // Award points for creating a post
      await _gamificationService.awardPoints(
        user.uid,
        10,
        'Created a community post',
      );

      // Check for 'community_contributor' achievement
      final userPosts =
          await _postsCollection.where('userId', isEqualTo: user.uid).get();

      if (userPosts.docs.length >= 5) {
        await _gamificationService.unlockAchievement(
          user.uid,
          'community_contributor',
          'Community Contributor',
        );
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error in createPost: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // Upload multiple images using Cloudinary
  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> urls = [];

    for (var image in images) {
      try {
        debugPrint('Uploading image to Cloudinary: ${image.path}');

        // Use CloudinaryService instead of Firebase Storage
        final imageUrl = await _cloudinaryService.uploadImage(
          image,
          folder: 'community_posts', // Use a dedicated folder for community
        );

        urls.add(imageUrl);
        debugPrint('Successfully uploaded image to Cloudinary: $imageUrl');
      } catch (e) {
        debugPrint('Error uploading image to Cloudinary: $e');
        // Continue with other images rather than failing completely
      }
    }

    return urls;
  }

  // Update an existing post
  Future<void> updatePost({
    required String postId,
    String? title,
    String? content,
    List<File>? newImages,
    List<String>? imagesToKeep,
  }) async {
    try {
      // Get the post to update
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');

      final post = CommunityPost.fromDocument(postDoc);

      // Check if user is the owner
      if (post.userId != _auth.currentUser?.uid) {
        throw Exception('You do not have permission to update this post');
      }

      // Process images if needed
      List<String> updatedImageUrls = imagesToKeep ?? [];

      if (newImages != null && newImages.isNotEmpty) {
        try {
          final newUrls = await _uploadImages(newImages);
          updatedImageUrls.addAll(newUrls);
        } catch (e) {
          debugPrint('Warning: Failed to upload new images: $e');
          // Continue with the update using existing images
        }
      }

      // Update the post
      Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (newImages != null || imagesToKeep != null) {
        updates['imageUrls'] = updatedImageUrls;
      }

      await _postsCollection.doc(postId).update(updates);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Get the post to delete
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');

      final post = CommunityPost.fromDocument(postDoc);

      // Check if user is the owner
      if (post.userId != _auth.currentUser?.uid) {
        throw Exception('You do not have permission to delete this post');
      }

      // We don't need to delete Cloudinary images as they can be managed through the Cloudinary dashboard
      // or can be cleaned up using a serverless function if needed

      // Delete comments subcollection
      final commentsSnapshot = await _commentsCollection(postId).get();
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the post
      await _postsCollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Like a post
  Future<void> likePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final likeRef = _firestore
        .collection('community_posts/$postId/likes')
        .doc(userId);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      // Already liked, remove the like
      await likeRef.delete();
      await _postsCollection.doc(postId).update({
        'likes': FieldValue.increment(-1),
      });
    } else {
      // Add new like
      await likeRef.set({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _postsCollection.doc(postId).update({
        'likes': FieldValue.increment(1),
      });
    }
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final likeDoc =
        await _firestore
            .collection('community_posts/$postId/likes')
            .doc(userId)
            .get();

    return likeDoc.exists;
  }

  // Get comments for a post
  Stream<List<Comment>> getComments(String postId) {
    return _commentsCollection(postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList(),
        );
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc['name'] ?? 'Anonymous';

      // Create comment
      final comment = Comment(
        postId: postId,
        userId: user.uid,
        userName: userName,
        content: content,
        createdAt: DateTime.now(),
      );

      // Save comment to Firestore
      await _commentsCollection(postId).add(comment.toMap());

      // Update comment count on post
      await _postsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Award points for commenting
      await _gamificationService.awardPoints(
        user.uid,
        2,
        'Commented on a post',
      );
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete a comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the comment
      final commentDoc = await _commentsCollection(postId).doc(commentId).get();
      if (!commentDoc.exists) throw Exception('Comment not found');

      final comment = Comment.fromDocument(commentDoc);

      // Check if user is the owner
      if (comment.userId != user.uid) {
        throw Exception('You do not have permission to delete this comment');
      }

      // Delete the comment
      await _commentsCollection(postId).doc(commentId).delete();

      // Update comment count on post
      await _postsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Search posts
  Future<List<CommunityPost>> searchPosts(String query) async {
    // Firebase doesn't support full-text search directly
    // This is a basic implementation that searches in title and content
    final snapshot = await _postsCollection.get();

    final allPosts =
        snapshot.docs.map((doc) => CommunityPost.fromDocument(doc)).toList();

    // Filter posts containing the query in title or content (case insensitive)
    return allPosts.where((post) {
      final title = post.title.toLowerCase();
      final content = post.content.toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) || content.contains(searchQuery);
    }).toList();
  }

  // Report a post
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if this user already reported this post
      final existingReports =
          await _reportsCollection
              .where('postId', isEqualTo: postId)
              .where('userId', isEqualTo: user.uid)
              .get();

      if (existingReports.docs.isNotEmpty) {
        throw Exception('You have already reported this post');
      }

      // Create report document
      final report = {
        'postId': postId,
        'userId': user.uid,
        'reason': reason,
        'additionalInfo': additionalInfo ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // For admin review
      };

      // Add report to Firestore
      await _reportsCollection.add(report);

      // Increment report count on the post
      await _postsCollection.doc(postId).update({
        'reportCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }
}
