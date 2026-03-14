import 'package:flutter/foundation.dart';
import 'mock_data.dart';
import 'notification_service.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

/// Centralized notification helper — dual-path:
/// 1. Always writes to MockData (for in-memory / offline)
/// 2. Also INSERTs into Supabase `campus_notifications` when enabled
/// 3. Fires a local system notification banner via NotificationService
class NotificationHelper {
  static int _notifIdCounter = 100;

  /// Push a notification to a user.
  ///
  /// [userId] — the student_id / staff id of the recipient
  /// [type]   — e.g. 'retest_update', 'clearance_update', 'opportunity', 'due_reminder', 'system'
  /// [title]  — short headline
  /// [message] — detailed body text
  static Future<void> push({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    // 1. In-memory (MockData)
    MockData.pushNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
    );

    // 2. Supabase persistence (works even for mock users since RLS is now public)
    if (SupabaseConfig.useSupabase) {
      try {
        await SupabaseService.instance.createNotification(
          studentId: userId,
          type: type,
          title: title,
          message: message,
        );
        debugPrint('[NotificationHelper] ✓ Pushed to Supabase: $title → $userId');
      } catch (e) {
        // Don't block the UI — log and continue
        debugPrint('[NotificationHelper] ✗ Supabase push failed: $e');
      }
    }

    // 3. Show local system notification banner ONLY if we are in mock mode.
    // In Supabase mode, the ChatProvider's Realtime listener handles showing
    // the banner to the actual recipient rather than the sender.
    if (!SupabaseConfig.useSupabase) {
      try {
        await NotificationService.showInstantNotification(
          title: title,
          body: message,
          id: _notifIdCounter++,
        );
      } catch (e) {
        debugPrint('[NotificationHelper] ✗ Local notification failed: $e');
      }
    }
  }
}

