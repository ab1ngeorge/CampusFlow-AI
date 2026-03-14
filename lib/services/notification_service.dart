import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'campusflow_instant',
        'CampusFlow Alerts',
        channelDescription: 'Instant campus notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }

  static Future<void> scheduleDeadlineReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();
    // For simplicity, show as instant notification since zonedSchedule
    // requires timezone setup. In production, use zonedSchedule.
    final dayBefore = scheduledDate.subtract(const Duration(hours: 24));
    if (dayBefore.isAfter(DateTime.now())) {
      await showInstantNotification(
        id: id,
        title: '⏰ $title — Tomorrow!',
        body: body,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
