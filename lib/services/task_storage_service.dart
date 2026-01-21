import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';

class TaskStorageService {
  static const _tasksKey = 'manodhyan_tasks';

  static Future<Map<String, List<TaskModel>>> loadTasksByDay() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    final result = <String, List<TaskModel>>{};
    decoded.forEach((key, value) {
      if (value is List) {
        result[key] = value
            .whereType<Map<String, dynamic>>()
            .map(TaskModel.fromMap)
            .toList();
      }
    });
    return result;
  }

  static Future<void> saveTasksByDay(
      Map<String, List<TaskModel>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = tasks.map(
      (key, value) => MapEntry(
        key,
        value.map((task) => task.toMap()).toList(),
      ),
    );
    await prefs.setString(_tasksKey, jsonEncode(payload));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
  }
}
