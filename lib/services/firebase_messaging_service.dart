import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final _fcm = FirebaseMessaging.instance;
  static bool _isEnabled = true;

  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Load notification preference
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (_isEnabled) {
      await _initNotifications();
    }
  }

  static Future<void> _initNotifications() async {
    await _fcm.requestPermission();

    // Subscribe to role-based or default topics
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final tags = List<String>.from(data?['tags'] ?? []);
      for (final tag in tags) {
        await _fcm.subscribeToTopic(tag);
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_isEnabled) return;

      final notification = message.notification;
      if (notification != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'CEYLON Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  /// Show an immediate local notification (if notifications are enabled).
  static Future<void> showLocalNotification(
    int id,
    String? title,
    String? body,
  ) async {
    if (!_isEnabled) return;

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'CEYLON Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Set notification enabled/disabled state
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled && !_isEnabled) {
      await _initNotifications();
    }
  }

  /// Get current notification enabled state
  static bool get isEnabled => _isEnabled;
}
