import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm_payload.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/alarm_storage_service.dart';

class AlarmController extends ChangeNotifier {
  AlarmController({AlarmService? alarmService})
      : alarmService = alarmService ?? AlarmService.instance;

  final AlarmService alarmService;
  final List<AlarmModel> _alarms = [];
  final _uuid = const Uuid();
  String? _scheduledAlarmId;

  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  Future<void> initialize() async {
    final stored = await AlarmStorageService.loadAlarms();
    _alarms
      ..clear()
      ..addAll(stored);
    await _scheduleNextAlarm();
    alarmService.registerAlarmListener(_handleAlarmTrigger);
    notifyListeners();
  }

  Future<void> addAlarm({
    required TimeOfDay time,
    required String label,
    bool repeatDaily = true,
  }) async {
    final alarm = AlarmModel(
      id: _uuid.v4(),
      hour: time.hour,
      minute: time.minute,
      label: label,
      repeatDaily: repeatDaily,
      isEnabled: true,
    );
    _alarms.add(alarm);
    await _persist();
    await _scheduleNextAlarm();
    notifyListeners();
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index == -1) return;
    _alarms[index] = alarm;
    await _persist();
    await _scheduleNextAlarm();
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((alarm) => alarm.id == id);
    await _persist();
    await _scheduleNextAlarm();
    notifyListeners();
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index == -1) return;
    final now = DateTime.now();
    final alarm = _alarms[index];
    _alarms[index] = alarm.copyWith(
      isEnabled: enabled,
      overrideTime: enabled ? alarm.nextTrigger(now) : null,
    );
    await _persist();
    await _scheduleNextAlarm();
    notifyListeners();
  }

  Future<void> _persist() async {
    await AlarmStorageService.saveAlarms(_alarms);
  }

  Future<void> _scheduleNextAlarm() async {
    final now = DateTime.now();
    AlarmModel? nextAlarm;
    DateTime? fireAt;

    for (final alarm in _alarms) {
      final next = alarm.nextTrigger(now);
      if (next == null) continue;
      if (fireAt == null || next.isBefore(fireAt)) {
        nextAlarm = alarm;
        fireAt = next;
      }
    }

    if (nextAlarm == null || fireAt == null) {
      if (_scheduledAlarmId != null) {
        await alarmService.cancelAlarmById(_scheduledAlarmId!);
        _scheduledAlarmId = null;
      }
      return;
    }

    final payload = AlarmPayload(
      alarmId: nextAlarm.id,
      durationSeconds: fireAt.difference(now).inSeconds,
      fireAt: fireAt,
      taskId: nextAlarm.label,
    );
    await alarmService.scheduleAlarm(fireAt, payload);
    _scheduledAlarmId = nextAlarm.id;
  }

  Future<void> _handleAlarmTrigger(AlarmPayload payload) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == payload.alarmId);
    if (index == -1) return;
    final alarm = _alarms[index];
    _alarms[index] = alarm.repeatDaily
        ? alarm.copyWith(clearOverride: true)
        : alarm.copyWith(isEnabled: false, clearOverride: true);
    _scheduledAlarmId = null;
    await _persist();
    await _scheduleNextAlarm();
    notifyListeners();
  }

  @override
  void dispose() {
    alarmService.unregisterAlarmListener(_handleAlarmTrigger);
    super.dispose();
  }
}
