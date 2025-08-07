import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyDuration = 'focus_duration';
  static const String _keySelectedApps = 'allowed_apps';
  static const String _keyStreakCount = 'focus_streak';

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

  /// Clear all saved session data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDuration);
    await prefs.remove(_keySelectedApps);
    await prefs.remove(_keyStreakCount);
  }
}
