import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm_payload.dart';
import '../services/alarm_service.dart';

class TimerController extends ChangeNotifier {
  TimerController({required this.alarmService});

  final AlarmService alarmService;

  final _uuid = const Uuid();
  int _remainingTime = 0;
  Timer? _timer;
  AlarmPayload? _pendingPayload;
  DateTime? _sessionStart;

  int get remainingTime => _remainingTime;
  bool get isRunning => _timer != null;
  AlarmPayload? get pendingPayload => _pendingPayload;

  Future<void> startSession(int minutes,
      {String? taskId,
      String? crystalType,
      List<String> allowedApps = const [],
      int crystalTarget = 0}) async {
    if (minutes <= 0) return;
    await cancelSession();
    _remainingTime = minutes * 60;
    _sessionStart = DateTime.now();
    final fireAt = _sessionStart!.add(Duration(minutes: minutes));
    final payload = AlarmPayload(
      alarmId: _uuid.v4(),
      durationSeconds: _remainingTime,
      fireAt: fireAt,
      taskId: taskId,
      crystalType: crystalType,
      crystalTarget: crystalTarget,
      allowedApps: allowedApps,
    );
    _pendingPayload = payload;
    await alarmService.scheduleAlarm(fireAt, payload);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        timer.cancel();
        _timer = null;
      } else {
        _remainingTime--;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> cancelSession() async {
    _timer?.cancel();
    _timer = null;
    _remainingTime = 0;
    final payload = _pendingPayload;
    _pendingPayload = null;
    _sessionStart = null;
    if (payload != null) {
      await alarmService.cancelAlarmById(payload.alarmId);
    }
    notifyListeners();
  }

  Future<void> completeSession({bool success = true}) async {
    _timer?.cancel();
    _timer = null;
    _remainingTime = 0;
    final payload = _pendingPayload;
    _pendingPayload = null;
    _sessionStart = null;
    if (success) {
      if (payload != null) {
        await alarmService.markCompleted(payload.alarmId);
      }
    } else {
      if (payload != null) {
        await alarmService.cancelAlarmById(payload.alarmId);
      }
    }
    notifyListeners();
  }
}
