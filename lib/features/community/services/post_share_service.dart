// lib/features/community/services/post_share_service.dart

import 'dart:io';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:campuslink/features/community/models/community_post_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PostShareService {
  static final PostShareService _instance = PostShareService._internal();

  factory PostShareService() {
    return _instance;
  }

  PostShareService._internal();

  // Create a dynamic link for a post
  Future<Uri> createPostDynamicLink(
    String postId, {
    String? title,
    String? description,
    String? imageUrl,
  }) async {
    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: 'https://campuslink.page.link', // Replace with your domain
      link: Uri.parse('https://campuslink.app/posts/$postId'),
      androidParameters: const AndroidParameters(
        packageName:
            'com.example.mobiletesting', // Replace with your package name
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId:
            'com.example.mobiletesting', // Replace with your iOS bundle ID
        minimumVersion: '0',
      ),
      navigationInfoParameters: const NavigationInfoParameters(
        forcedRedirectEnabled: true,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title ?? 'Check out this post',
        description: description ?? 'Shared from CampusLink',
        imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
      ),
    );

    final dynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(
      dynamicLinkParams,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );

    return dynamicLink.shortUrl;
  }

  // Create an HTML file with post content for sharing
  Future<String> _createPostPreviewHtml(
    CommunityPost post,
    Uri? dynamicLink,
  ) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/post_preview.html';

    String imagesHtml = '';
    if (post.imageUrls.isNotEmpty) {
      imagesHtml = '<div style="margin-top: 10px;">';
      for (var imageUrl in post.imageUrls.take(3)) {
        imagesHtml +=
            '<img src="$imageUrl" style="max-width: 100%; margin-bottom: 5px; border-radius: 8px;">';
      }
      imagesHtml += '</div>';
    }

    String linkHtml = '';
    if (dynamicLink != null) {
      linkHtml =
          '<div style="margin-top: 15px;"><a href="$dynamicLink" style="color: #673AB7; text-decoration: none;">View post in CampusLink</a></div>';
    }

    final html = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${post.title}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          padding: 15px;
          margin: 0;
          color: #333;
          background-color: #f9f9f9;
        }
        .post-container {
          background-color: white;
          border-radius: 12px;
          padding: 15px;
          box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .post-header {
          display: flex;
          align-items: center;
          margin-bottom: 10px;
        }
        .avatar {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background-color: #e1bee7;
          color: #673AB7;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          margin-right: 10px;
        }
        .post-metadata {
          display: flex;
          flex-direction: column;
        }
        .post-title {
          font-size: 18px;
          font-weight: bold;
          margin-bottom: 8px;
        }
        .post-content {
          font-size: 16px;
          line-height: 1.5;
          margin-bottom: 15px;
        }
        .post-footer {
          color: #888;
          font-size: 12px;
          margin-top: 10px;
          border-top: 1px solid #eee;
          padding-top: 10px;
        }
      </style>
    </head>
    <body>
      <div class="post-container">
        <div class="post-header">
          <div class="avatar">${post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?'}</div>
          <div class="post-metadata">
            <div>${post.userName}</div>
            <div style="font-size: 12px; color: #666;">${post.createdAt.toString().substring(0, 16)}</div>
          </div>
        </div>
        <div class="post-title">${post.title}</div>
        <div class="post-content">${post.content}</div>
        $imagesHtml
        $linkHtml
        <div class="post-footer">Shared from CampusLink</div>
      </div>
    </body>
    </html>
    ''';

    final File file = File(filePath);
    await file.writeAsString(html);
    return filePath;
  }

  // Share a post with dynamic link
  Future<void> sharePost(BuildContext context, CommunityPost post) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  const Text("Preparing post to share..."),
                ],
              ),
            ),
          );
        },
      );

      // Create dynamic link
      Uri? dynamicLinkUri;

      try {
        // Create dynamic link with post details
        dynamicLinkUri = await createPostDynamicLink(
          post.id!,
          title: post.title,
          description:
              post.content.length > 100
                  ? '${post.content.substring(0, 97)}...'
                  : post.content,
          imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
        );
      } catch (e) {
        debugPrint('Error creating dynamic link: $e');
      }

      // Create share text
      final String shareText =
          '${post.title}\n\n${post.content}\n\n${dynamicLinkUri != null ? 'View post: $dynamicLinkUri' : 'Shared from CampusLink'}';

      // Download image if available
      String? imagePath;

      if (post.imageUrls.isNotEmpty) {
        try {
          final http.Response response = await http.get(
            Uri.parse(post.imageUrls.first),
          );
          final Directory tempDir = await getTemporaryDirectory();
          imagePath = '${tempDir.path}/shared_post_image.jpg';
          final File file = File(imagePath);
          await file.writeAsBytes(response.bodyBytes);
        } catch (e) {
          debugPrint('Error downloading image: $e');
        }
      }

      // Try different share approaches depending on platform
      String? htmlPath;
      try {
        // Create an HTML preview for the post
        htmlPath = await _createPostPreviewHtml(post, dynamicLinkUri);
      } catch (e) {
        debugPrint('Error creating HTML preview: $e');
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Share with the best available method
      if (imagePath != null && htmlPath != null) {
        // Share with both image and text
        await Share.shareXFiles(
          [XFile(imagePath), XFile(htmlPath)],
          text: shareText,
          subject: post.title,
        );
      } else if (imagePath != null) {
        // Share with image and text
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: shareText,
          subject: post.title,
        );
      } else if (htmlPath != null) {
        // Share HTML preview
        await Share.shareXFiles(
          [XFile(htmlPath)],
          text: shareText,
          subject: post.title,
        );
      } else {
        // Fallback to text-only
        await Share.share(shareText, subject: post.title);
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Error sharing post: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing post: $e')));
      }
    }
  }
}
