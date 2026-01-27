import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyDuration = 'focus_duration';
  static const String _keySelectedApps = 'allowed_apps';
  static const String _keyStreakCount = 'focus_streak';
  static const String _keyActiveAlarmData = 'active_alarm_data';

  /// Save focus duration in minutes
  static Future<void> saveDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDuration, minutes);
  }

  /// Load saved focus duration
  static Future<int> getDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDuration) ?? 15;
  }

  /// Save selected app package names
  static Future<void> saveAllowedApps(List<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySelectedApps, apps);
  }

  /// Get selected app package names
  static Future<List<String>> getAllowedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySelectedApps) ?? [];
  }

  /// Save current streak count
  static Future<void> saveStreak(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStreakCount, count);
  }

  /// Get saved streak count
  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakCount) ?? 0;
  }

  static const String _keyCrystalCount = 'crystal_count';

  /// Save crystal count
  static Future<void> saveCrystals(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCrystalCount, count);
  }

  /// Get saved crystal count
  static Future<int> getCrystals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCrystalCount) ?? 0;
  }

  /// Clear all saved session data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDuration);
    await prefs.remove(_keySelectedApps);
    await prefs.remove(_keyStreakCount);
  }

  static Future<void> saveScheduledAlarms(
      Map<String, Map<String, dynamic>> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveAlarmData, jsonEncode(alarms));
  }

  static Future<Map<String, Map<String, dynamic>>> getScheduledAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActiveAlarmData);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        // Legacy single-alarm payload support
        if (decoded.containsKey('androidId') &&
            decoded.containsKey('payload')) {
          final payloadMap = (decoded['payload'] as Map<dynamic, dynamic>?)
                  ?.map((key, value) => MapEntry(key.toString(), value)) ??
              <String, dynamic>{};
          final alarmId =
              payloadMap['alarmId']?.toString() ?? 'legacy_alarm_id';
          return {
            alarmId: {
              'androidId': decoded['androidId'],
              'payload': payloadMap,
            },
          };
        }
        final result = <String, Map<String, dynamic>>{};
        decoded.forEach((key, value) {
          if (value is Map) {
            result[key] = value.map(
              (k, v) => MapEntry(k.toString(), v),
            );
          }
        });
        return result;
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  static Future<void> clearScheduledAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveAlarmData);
  }
}
