// lib/features/notifications/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobiletesting/features/notifications/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'marketplace', 'task', 'community'
    String? subtype,
    String? sourceId,
    String? sourceTitle,
    String? imageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'userId': userId,
            'title': title,
            'message': message,
            'type': type,
            'subtype': subtype,
            'sourceId': sourceId,
            'sourceTitle': sourceTitle,
            'imageUrl': imageUrl,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'additionalData': additionalData,
          });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get user notifications
  Stream<List<AppNotification>> getNotifications({String? type}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    // If type is specified, filter by type
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  // Get unread notification count
  Stream<int> getUnreadCount({String? type}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    Query query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false);

    // If type is specified, filter by type
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // Helper methods for specific notification types

  // Marketplace notifications
  Future<void> createMarketplaceNotification({
    required String userId,
    required String title,
    required String message,
    required String subtype, // 'chat', 'status', 'offer', etc.
    String? productId,
    String? productTitle,
    String? imageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'marketplace',
      subtype: subtype,
      sourceId: productId,
      sourceTitle: productTitle,
      imageUrl: imageUrl,
      additionalData: additionalData,
    );
  }

  // Task notifications
  Future<void> createTaskNotification({
    required String userId,
    required String title,
    required String message,
    required String subtype, // 'assigned', 'deadline', 'completed', etc.
    String? taskId,
    String? taskTitle,
    DateTime? deadline,
    Map<String, dynamic>? additionalData,
  }) async {
    Map<String, dynamic> taskData = additionalData ?? {};
    if (deadline != null) {
      taskData['deadline'] = deadline;
    }

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'task',
      subtype: subtype,
      sourceId: taskId,
      sourceTitle: taskTitle,
      additionalData: taskData,
    );
  }

  // Community notifications
  Future<void> createCommunityNotification({
    required String userId,
    required String title,
    required String message,
    required String subtype, // 'post', 'comment', 'mention', etc.
    String? postId,
    String? postTitle,
    String? authorId,
    String? authorName,
    String? imageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    Map<String, dynamic> communityData = additionalData ?? {};
    if (authorId != null) {
      communityData['authorId'] = authorId;
    }
    if (authorName != null) {
      communityData['authorName'] = authorName;
    }

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'community',
      subtype: subtype,
      sourceId: postId,
      sourceTitle: postTitle,
      imageUrl: imageUrl,
      additionalData: communityData,
    );
  }
}
