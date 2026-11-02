import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_payload.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/alarm_storage_service.dart';

class AlarmController extends ChangeNotifier with WidgetsBindingObserver {
  AlarmController({AlarmService? alarmService})
    : alarmService = alarmService ?? AlarmService.instance;
  final AlarmService alarmService;
  final List<AlarmModel> _alarms = [];
  final _managedIds = <String>{};
  final _uuid = const Uuid();
  Future<void> _pending = Future.value();
  bool _initialized = false;
  bool _disposed = false;
  String? schedulingError;
  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    alarmService.registerAlarmListener(_handleAlarmTrigger);
    // A denied permission must not prevent loading the Planner or opening Settings.
    try {
      await refreshScheduling();
    } catch (error) {
      schedulingError = _message(error);
      _notify();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_disposed) {
      refreshScheduling().catchError((Object error) {
        schedulingError = _message(error);
        _notify();
      });
    }
  }

  Future<void> refreshScheduling({bool requestPermissions = false}) =>
      _enqueue(() async {
        final stored = await AlarmStorageService.loadAlarms();
        _alarms
          ..clear()
          ..addAll(stored);
        _managedIds.addAll(stored.map((a) => a.id));
        await _synchronize(stored, requestPermissions: requestPermissions);
        _notify();
      });

  Future<void> addAlarm({
    required TimeOfDay time,
    required String label,
    bool repeatDaily = true,
  }) => _enqueue(() async {
    final alarm = AlarmModel(
      id: _uuid.v4(),
      hour: time.hour,
      minute: time.minute,
      label: label,
      repeatDaily: repeatDaily,
      isEnabled: true,
    );
    await _apply([..._alarms, alarm], requestPermissions: true);
  });

  Future<void> updateAlarm(AlarmModel alarm) => _enqueue(() async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index == -1) return;
    final updated = [..._alarms];
    updated[index] = alarm;
    await _apply(updated, requestPermissions: alarm.isEnabled);
  });

  Future<void> deleteAlarm(String id) =>
      _enqueue(() => _apply(_alarms.where((a) => a.id != id).toList()));

  Future<void> toggleAlarm(String id, bool enabled) => _enqueue(() async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = [..._alarms];
    updated[index] = updated[index].copyWith(
      isEnabled: enabled,
      clearOverride: true,
    );
    await _apply(updated, requestPermissions: enabled);
  });

  Future<void> _apply(
    List<AlarmModel> updated, {
    bool requestPermissions = false,
  }) async {
    final previous = [..._alarms];
    try {
      await _synchronize(updated, requestPermissions: requestPermissions);
      // Publish and persist the enabled state only after Android accepts scheduling.
      await AlarmStorageService.saveAlarms(updated);
      _alarms
        ..clear()
        ..addAll(updated);
      _notify();
    } catch (error) {
      // Restore registrations if a later native or storage operation failed.
      try {
        await _synchronize(previous);
      } catch (_) {
        /* Keep the original error. */
      }
      schedulingError = _message(error);
      _notify();
      rethrow;
    }
  }

  Future<void> _synchronize(
    List<AlarmModel> alarms, {
    bool requestPermissions = false,
  }) async {
    final enabled = alarms.where((a) => a.isEnabled).toList();
    var canSchedule = enabled.isEmpty;
    schedulingError = null;
    if (enabled.isNotEmpty) {
      try {
        await alarmService.ensureAlarmPermissions(request: requestPermissions);
        canSchedule = true;
      } on AlarmSchedulingException catch (error) {
        schedulingError = error.message;
        if (requestPermissions) rethrow;
      }
    }
    if (canSchedule) {
      final now = DateTime.now();
      // Register every alarm. Later alarms must not depend on a foreground callback.
      for (final alarm in enabled) {
        final next = alarm.nextTrigger(now)!;
        final earliest = now.add(const Duration(seconds: 1));
        final fireAt = next.isBefore(earliest) ? earliest : next;
        await alarmService.scheduleAlarm(
          fireAt,
          AlarmPayload(
            alarmId: alarm.id,
            durationSeconds: fireAt.difference(now).inSeconds,
            fireAt: fireAt,
            taskId: alarm.label,
            isAlarmClock: true,
          ),
          alarmClock: true,
        );
        _managedIds.add(alarm.id);
      }
    }
    final keep = enabled.map((a) => a.id).toSet();
    for (final id in _managedIds.difference(keep).toList()) {
      await alarmService.cancelAlarmById(id);
      _managedIds.remove(id);
    }
  }

  Future<void> _handleAlarmTrigger(AlarmPayload payload) async {
    // Background delivery has already disabled one-time alarms or rearmed repeats.
    await refreshScheduling();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _pending.then((_) async {
      if (!_disposed) await action();
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static String _message(Object error) =>
      error is AlarmSchedulingException
          ? error.message
          : 'Android could not update your alarms. Please retry.';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    alarmService.unregisterAlarmListener(_handleAlarmTrigger);
    super.dispose();
  }
}
