import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ChatStorage {
  static const String _keyPrefix = 'chat_session_';

  static Future<void> saveChatSession(String studentId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages
        .where((m) => !m.isStreaming) // Don't save mid-stream messages
        .map((m) => m.toJson())
        .toList();
    await prefs.setString('$_keyPrefix$studentId', jsonEncode(jsonList));
    
    // Track session timestamp
    final timestamps = prefs.getStringList('${_keyPrefix}timestamps_$studentId') ?? [];
    final now = DateTime.now().toIso8601String();
    if (timestamps.isEmpty || timestamps.last != now.substring(0, 10)) {
      timestamps.add(now);
      await prefs.setStringList('${_keyPrefix}timestamps_$studentId', timestamps);
    }
  }

  static Future<List<ChatMessage>> loadChatSession(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_keyPrefix$studentId');
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> listSessionIds(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_keyPrefix}timestamps_$studentId') ?? [];
  }

  static Future<void> deleteSession(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$studentId');
    await prefs.remove('${_keyPrefix}timestamps_$studentId');
  }
}
