import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_model.dart';

class AlarmStorageService {
  static const _alarmKey = 'manodhyan_alarms';

  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_alarmKey) ?? [];
    return rawList
        .map((encoded) =>
            AlarmModel.fromMap(jsonDecode(encoded) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final payload =
        alarms.map((alarm) => jsonEncode(alarm.toMap())).toList();
    await prefs.setStringList(_alarmKey, payload);
  }
}
