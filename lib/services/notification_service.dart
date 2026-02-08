import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Stream<List<NotificationModel>>> _noteStreams = {};
  final Map<String, Stream<int>> _countStreams = {};

  void initialize() {
    // This can be used for any startup logic if needed
  }

  // Stream of notifications for a user
  Stream<List<NotificationModel>> getNotifications(String userId) {
    if (_noteStreams.containsKey(userId)) return _noteStreams[userId]!;

    final stream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
            .toList())
        .asBroadcastStream();

    _noteStreams[userId] = stream;
    return stream;
  }

  // Stream of unread count
  Stream<int> getUnreadCount(String userId) {
    if (_countStreams.containsKey(userId)) return _countStreams[userId]!;

    final stream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .asBroadcastStream();

    _countStreams[userId] = stream;
    return stream;
  }

  // Send notification to a single user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      if (kDebugMode) print("Error sending notification: $e");
    }
  }

  // Broadcast to group members
  Future<void> broadcastToGroup({
    required String groupId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      Query query = _firestore.collection('user');
      if (groupId != 'All') {
        query = query.where('group', isEqualTo: groupId);
      }

      final membersSnapshot = await query.get();

      final batch = _firestore.batch();
      for (var doc in membersSnapshot.docs) {
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'userId': doc.id,
          'title': title,
          'body': body,
          'type': type,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) print("Error broadcasting notification: $e");
    }
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      if (kDebugMode) print("Error marking notification as read: $e");
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) print("Error marking all notifications as read: $e");
    }
  }

  // Fetch recent announcements for assistant
  Future<List<NotificationModel>> fetchRecentAnnouncements(
      String groupId, DateTime? lastRead) async {
    try {
      Query query = _firestore
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(5);

      if (lastRead != null) {
        // We don't filter strictly by timestamp to allow read-back of recent stuff
        // but it's good context
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
          .where((n) {
        // Further filter by group if needed, or by userId
        // For announcements, we usually look at notifications sent to 'All' or user's group
        return true; // Simple version: last 5 notifications
      }).toList();
    } catch (e) {
      if (kDebugMode) print("Error fetching recent announcements: $e");
      return [];
    }
  }
}
