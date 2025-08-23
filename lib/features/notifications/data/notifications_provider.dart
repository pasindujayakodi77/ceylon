import 'package:ceylon/features/notifications/data/notifications_service.dart';
import 'package:flutter/material.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationsService _notificationsService = NotificationsService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get notifications stream
  Stream<List<NotificationItem>> getNotifications() {
    return _notificationsService.getNotifications();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationsService.markAsRead(notificationId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationsService.markAllAsRead();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationsService.deleteNotification(notificationId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationsService.deleteAllNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      return await _notificationsService.getUnreadCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }
}
