import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/task_model.dart';
import '../services/task_storage_service.dart';

class TaskController extends ChangeNotifier {
  final _uuid = const Uuid();
  final Map<String, List<TaskModel>> _tasksByDay = {};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadTasks();
    _initialized = true;
  }

  Future<void> refresh() async {
    await _loadTasks();
  }

  List<TaskModel> get todaysTasks =>
      List.unmodifiable(_tasksByDay[_todayKey] ?? []);

  List<TaskModel> tasksForDate(DateTime date) {
    final key = _dateKey(date);
    return List.unmodifiable(_tasksByDay[key] ?? const []);
  }

  double get todaysPoints => _calculatePoints(todaysTasks);

  double get totalPoints {
    double sum = 0;
    for (final tasks in _tasksByDay.values) {
      sum += _calculatePoints(tasks);
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  int get streak => _calculateStreak();

  Future<void> addTask({
    required String title,
    String description = '',
  }) async {
    final task = TaskModel(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    final key = task.dateKey;
    final list = List<TaskModel>.from(_tasksByDay[key] ?? []);
    list.add(task);
    _tasksByDay[key] = list;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    final key = _todayKey;
    final list = List<TaskModel>.from(_tasksByDay[key] ?? []);
    final index = list.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    list[index] = list[index].copyWith(isCompleted: isCompleted);
    _tasksByDay[key] = list;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    final todayList = List<TaskModel>.from(_tasksByDay[_todayKey] ?? []);
    final initialLength = todayList.length;
    todayList.removeWhere((task) => task.id == taskId);
    if (todayList.length == initialLength) return;
    if (todayList.isEmpty) {
      _tasksByDay.remove(_todayKey);
    } else {
      _tasksByDay[_todayKey] = todayList;
    }
    await _persist();
    notifyListeners();
  }

  double _calculatePoints(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((task) => task.isCompleted).length;
    final incomplete = tasks.length - completed;
    final total = completed - (incomplete * 0.5);
    return max(0, double.parse(total.toStringAsFixed(2)));
  }

  int _calculateStreak() {
    int count = 0;
    final now = DateTime.now();
    for (int offset = 0; ; offset++) {
      final date = now.subtract(Duration(days: offset));
      final key = _dateKey(date);
      final tasks = _tasksByDay[key];
      if (tasks == null || tasks.isEmpty) {
        break;
      }
      count++;
    }
    return count;
  }

  Future<void> _persist() async {
    await TaskStorageService.saveTasksByDay(_tasksByDay);
  }

  Future<void> _loadTasks() async {
    final stored = await TaskStorageService.loadTasksByDay();
    _tasksByDay
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  String get _todayKey => _dateKey(DateTime.now());

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
