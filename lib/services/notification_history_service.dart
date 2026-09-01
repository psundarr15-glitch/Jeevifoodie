import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationHistoryService {
  static const _lastSeenKey = 'notifications_last_seen_id';

  static Future<List<AppNotification>> recent() async {
    final res = await ApiClient.get(ApiConfig.notifications);
    return (res['notifications'] as List? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// True if there's a broadcast notification newer than the last one the
  /// person opened the notification list to see. Used to decide whether
  /// the bell icon should animate to draw attention.
  static Future<bool> hasUnread() async {
    try {
      final items = await recent();
      if (items.isEmpty) return false;
      final latestId = items.first.id; // API returns newest first
      final lastSeen = await getLastSeenId();
      return lastSeen == null || latestId > lastSeen;
    } catch (_) {
      return false; // don't animate on a failed network check
    }
  }

  static Future<int?> getLastSeenId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSeenKey);
  }

  static Future<void> setLastSeenId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSeenKey, id);
  }
}
