// lib\services\dynamic_links_service.dart
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobiletesting/features/community/models/community_post_model.dart';
import 'package:mobiletesting/features/community/views/post_detail_screen.dart';

class DynamicLinksService {
  static final DynamicLinksService _instance = DynamicLinksService._internal();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  factory DynamicLinksService() {
    return _instance;
  }

  DynamicLinksService._internal();

  void initialize() {
    // Handle links when app is started by a link
    FirebaseDynamicLinks.instance.getInitialLink().then((data) {
      if (data != null) {
        _handleDynamicLink(data);
      }
    });

    // Handle links when app is already running
    FirebaseDynamicLinks.instance.onLink
        .listen((dynamicLinkData) {
          _handleDynamicLink(dynamicLinkData);
        })
        .onError((error) {
          debugPrint('Dynamic link failed: ${error.message}');
        });
  }

  void _handleDynamicLink(PendingDynamicLinkData data) {
    final Uri deepLink = data.link;

    // Check if this is a post link
    if (deepLink.pathSegments.contains('posts') &&
        deepLink.pathSegments.length > 1) {
      final String postId = deepLink.pathSegments[1];
      navigateToPost(postId);
    }
  }

  Future<void> navigateToPost(String postId) async {
    try {
      final post =
          await FirebaseFirestore.instance
              .collection('community_posts')
              .doc(postId)
              .get();

      if (post.exists && navigatorKey.currentState != null) {
        final postData = CommunityPost.fromDocument(post);
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: postData),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to post: $e');
    }
  }
}
