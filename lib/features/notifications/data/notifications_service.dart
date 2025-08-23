import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType { info, alert, social, recommendation, reminder }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? relatedId; // ID of related content (attraction, event, etc.)
  final String? relatedType; // Type of related content
  final String? imageUrl;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.relatedId,
    this.relatedType,
    this.imageUrl,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _getNotificationType(data['type'] ?? 'info'),
      isRead: data['isRead'] ?? false,
      relatedId: data['relatedId'],
      relatedType: data['relatedType'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': _getTypeString(type),
      'isRead': isRead,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'imageUrl': imageUrl,
    };
  }

  static NotificationType _getNotificationType(String type) {
    switch (type) {
      case 'alert':
        return NotificationType.alert;
      case 'social':
        return NotificationType.social;
      case 'recommendation':
        return NotificationType.recommendation;
      case 'reminder':
        return NotificationType.reminder;
      case 'info':
      default:
        return NotificationType.info;
    }
  }

  static String _getTypeString(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return 'alert';
      case NotificationType.social:
        return 'social';
      case NotificationType.recommendation:
        return 'recommendation';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.info:
        return 'info';
    }
  }
}

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Collection reference for user's notifications
  CollectionReference<Map<String, dynamic>>? get _notificationsCollection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  // Stream to get real-time notifications for the current user
  Stream<List<NotificationItem>> getNotifications() {
    final collection = _notificationsCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationItem.fromFirestore(doc))
              .toList(),
        );
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final collection = _notificationsCollection;
    if (collection == null) return;

    await collection.doc(notificationId).update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final collection = _notificationsCollection;
    if (collection == null) return;

    final batch = _firestore.batch();
    final snapshots = await collection.where('isRead', isEqualTo: false).get();

    for (final doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final collection = _notificationsCollection;
    if (collection == null) return;

    await collection.doc(notificationId).delete();
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    final collection = _notificationsCollection;
    if (collection == null) return;

    final batch = _firestore.batch();
    final snapshots = await collection.get();

    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final collection = _notificationsCollection;
    if (collection == null) return 0;

    final snapshot = await collection
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
