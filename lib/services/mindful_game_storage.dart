import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mental_math.dart';

/// A shared allowance key lets future mindful games use the same daily budget.
class MindfulGameStorage {
  MindfulGameStorage(this._prefs);
  final SharedPreferences _prefs;
  static const dailyLimitSeconds = 10 * 60;
  static const _budgetKey = 'focusjoy_mindful_game_budget_v1';
  static const _historyKey = 'focusjoy_mental_math_history_v1';
  static const _settingsKey = 'focusjoy_mental_math_settings_v1';
  static Future<void> _pending = Future.value();

  static String dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _budget() {
    final raw = _prefs.getString(_budgetKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (map.values.any((v) => v is! int || v < 0 || v > dailyLimitSeconds)) {
      throw const FormatException('Invalid saved play allowance');
    }
    return map;
  }

  int remainingSeconds(DateTime now) =>
      dailyLimitSeconds - (_budget()[dayKey(now)] as int? ?? 0);

  Future<bool> consumeSeconds(DateTime now, int seconds) => _enqueue(() async {
    if (seconds < 1) throw ArgumentError.value(seconds);
    final budget = _budget();
    final key = dayKey(now);
    final used = budget[key] as int? ?? 0;
    if (used + seconds > dailyLimitSeconds) return false;
    budget[key] = used + seconds;
    // Retain dates to avoid granting a new allowance when the date moves back.
    await _save(_budgetKey, budget);
    return true;
  });

  MathGameSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    return raw == null
        ? MathGameSettings()
        : MathGameSettings.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
  }

  Future<void> saveSettings(MathGameSettings settings) =>
      _enqueue(() => _save(_settingsKey, settings.toMap()));

  List<MathRoundResult> loadHistory() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    final results =
        (jsonDecode(raw) as List)
            .map(
              (r) =>
                  MathRoundResult.fromMap(Map<String, dynamic>.from(r as Map)),
            )
            .toList();
    results.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return results;
  }

  Future<void> saveResult(MathRoundResult result) => _enqueue(() async {
    final history = loadHistory()..removeWhere((r) => r.id == result.id);
    history.insert(0, result);
    await _save(_historyKey, history.map((r) => r.toMap()).toList());
  });

  Future<void> _save(String key, Object value) async {
    if (!await _prefs.setString(key, jsonEncode(value))) {
      throw StateError('Unable to save game data');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final result = _pending.then((_) => task());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
