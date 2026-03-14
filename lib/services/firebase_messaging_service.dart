import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Top-level handler for background / terminated-state FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
  // Local notification will be shown automatically by the system tray
  // for data-only messages you can call NotificationService here.
}

/// Centralized Firebase Cloud Messaging service for CampusFlow AI.
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Call once after `Firebase.initializeApp()`.
  static Future<void> initialize() async {
    if (_initialized) return;

    // 1️⃣ Request permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] ✅ Notification permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('[FCM] ⚠️ Provisional permission granted');
    } else {
      debugPrint('[FCM] ❌ Notification permission denied');
    }

    // 2️⃣ Get FCM token (use this to target this device from your backend)
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] 🔑 Device token: $token');
    } catch (e) {
      debugPrint('[FCM] ⚠️ Could not get token: $e');
    }

    // 3️⃣ Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] 🔄 Token refreshed: $newToken');
      // TODO: Send updated token to your backend / Supabase
    });

    // 4️⃣ Foreground messages → show as local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5️⃣ Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 6️⃣ Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] 🔔 Notification tapped (from background): '
          '${message.notification?.title}');
      // TODO: Navigate to the relevant screen based on message data
    });

    // 7️⃣ Check if app was opened from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] 🚀 App opened from notification: '
          '${initialMessage.notification?.title}');
      // TODO: Navigate to the relevant screen
    }

    _initialized = true;
    debugPrint('[FCM] ✅ FirebaseMessagingService initialized');
  }

  /// Show a local notification when a push arrives while the app is open.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] 📩 Foreground message: ${message.notification?.title}');

    final title = message.notification?.title ?? 'CampusFlow AI';
    final body = message.notification?.body ?? '';

    // Use the existing local notification service to display a banner
    await NotificationService.showInstantNotification(
      title: title,
      body: body,
      id: message.hashCode, // unique ID per message
    );
  }

  /// Subscribe this device to a topic (e.g. "student_STU001", "all_students").
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] 📌 Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] 📌 Unsubscribed from topic: $topic');
  }
}
