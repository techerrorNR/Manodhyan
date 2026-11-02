import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm_payload.dart';
import '../routes.dart';
import 'alarm_storage_service.dart';
import 'local_storage_service.dart';

typedef AlarmTriggerListener = Future<void> Function(AlarmPayload payload);

class AlarmSchedulingException implements Exception {
  const AlarmSchedulingException(this.message);
  final String message;
  @override
  String toString() => message;
}

@pragma('vm:entry-point')
Future<void> alarmFiredCallback(int id, Map<String, dynamic> params) =>
    AlarmService.handleBackgroundAlarm(
      id,
      expectedFireAt: DateTime.tryParse(params['fireAt'] as String? ?? ''),
    );

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  AlarmService.handleBackgroundNotification(details.payload);
}

class AlarmService {
  AlarmService._internal();
  @visibleForTesting
  AlarmService.testing();
  static final AlarmService instance = AlarmService._internal();
  static const _portName = 'manodhyan_alarm_port';
  static const _notificationChannelId = 'manodhyan_alarm_channel';
  static const int _alarmIdMask = 0x7FFFFFFF;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, _ScheduledAlarm> _scheduledAlarms = {};
  final List<AlarmPayload> _pendingChallenges = [];
  ReceivePort? _receivePort;
  AlarmPayload? _activePayload;
  AlarmTriggerListener? _alarmTriggerListener;
  bool _challengeOpen = false;
  bool? _platformReady;
  static Future<void> _backgroundPending = Future.value();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _initNotifications();
    _registerPort();
    _platformReady = await AndroidAlarmManager.initialize();
    if (_platformReady != true) {
      debugPrint('Android could not initialize the alarm service.');
      return;
    }
    try {
      await ensureAlarmPermissions();
      await _restoreScheduledAlarms();
    } on AlarmSchedulingException catch (error) {
      debugPrint('Alarm restoration deferred: ${error.message}');
    }
  }

  /// Request only following an explicit user action, never during startup.
  Future<void> ensureAlarmPermissions({bool request = false}) async {
    if (_platformReady == false) {
      _platformReady = await AndroidAlarmManager.initialize();
      if (_platformReady != true) {
        throw const AlarmSchedulingException(
          'Android could not start the alarm service. Please restart FocusJoy.',
        );
      }
    }
    final android = _android;
    if (android == null) {
      throw const AlarmSchedulingException(
        'System alarms are available on Android.',
      );
    }
    var exact = await android.canScheduleExactNotifications() == true;
    if (!exact && request) {
      await android.requestExactAlarmsPermission();
      exact = await android.canScheduleExactNotifications() == true;
    }
    if (!exact) {
      throw const AlarmSchedulingException(
        'Allow FocusJoy under Android Settings → Special app access → Alarms & reminders, then retry.',
      );
    }
    var notifications = await android.areNotificationsEnabled() == true;
    if (!notifications && request) {
      await android.requestNotificationsPermission();
      notifications = await android.areNotificationsEnabled() == true;
    }
    if (!notifications) {
      throw const AlarmSchedulingException(
        'Allow FocusJoy notifications in Android settings so alarms can alert you, then retry.',
      );
    }
  }

  void registerAlarmListener(AlarmTriggerListener listener) =>
      _alarmTriggerListener = listener;
  void unregisterAlarmListener(AlarmTriggerListener listener) {
    if (_alarmTriggerListener == listener) _alarmTriggerListener = null;
  }

  Future<void> _initNotifications() async {
    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse:
          (details) => _handleForegroundNotification(details.payload),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    await _createChannel(_notificationsPlugin);
    final details =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _handleForegroundNotification(details?.notificationResponse?.payload);
    }
  }

  static Future<void> _createChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notificationChannelId,
            'Focus Alarm',
            description: 'High priority alarms that require a challenge',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: false,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
  }

  void _registerPort() {
    if (_receivePort != null) return;
    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
    _receivePort!.listen((message) {
      if (message is String) {
        _handleIncomingPayload(AlarmPayload.fromJson(message));
      }
    });
  }

  Future<void> _reloadScheduledAlarms() async {
    final stored = await LocalStorageService.getScheduledAlarms();
    _scheduledAlarms.clear();
    for (final entry in stored.entries) {
      final map = entry.value['payload'];
      if (map is! Map) continue;
      final payload = AlarmPayload.fromMap(Map<String, dynamic>.from(map));
      _scheduledAlarms[entry.key] = _ScheduledAlarm(
        androidId:
            entry.value['androidId'] as int? ?? _stableAlarmId(entry.key),
        payload: payload,
      );
    }
  }

  Future<void> _restoreScheduledAlarms() async {
    await _reloadScheduledAlarms();
    final configuredIds =
        (await AlarmStorageService.loadAlarms()).map((a) => a.id).toSet();
    for (final scheduled in _scheduledAlarms.values.toList()) {
      // Planner reconciles its complete configuration, including overdue repeats.
      if (configuredIds.contains(scheduled.payload.alarmId)) continue;
      if (scheduled.payload.fireAt.isAfter(DateTime.now())) {
        await _scheduleNative(scheduled);
      } else {
        await _showNotification(
          _notificationsPlugin,
          scheduled.payload,
          scheduled.androidId,
        );
        await _handleIncomingPayload(scheduled.payload);
      }
    }
  }

  static Future<void> _scheduleNative(_ScheduledAlarm alarm) async {
    final accepted = await AndroidAlarmManager.oneShotAt(
      alarm.payload.fireAt,
      alarm.androidId,
      alarmFiredCallback,
      alarmClock: alarm.payload.isAlarmClock,
      allowWhileIdle: true,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'fireAt': alarm.payload.fireAt.toIso8601String()},
    );
    if (!accepted) {
      throw const AlarmSchedulingException(
        'Android did not accept this alarm. Check Alarms & reminders access and try again.',
      );
    }
  }

  Future<int> scheduleAlarm(
    DateTime fireAt,
    AlarmPayload payload, {
    bool alarmClock = false,
  }) async {
    await ensureAlarmPermissions();
    if (!fireAt.isAfter(DateTime.now())) {
      throw const AlarmSchedulingException(
        'Choose an alarm time in the future.',
      );
    }
    await _reloadScheduledAlarms();
    final existing = _scheduledAlarms[payload.alarmId];
    var androidId = existing?.androidId ?? _stableAlarmId(payload.alarmId);
    while (_scheduledAlarms.entries.any(
      (e) => e.key != payload.alarmId && e.value.androidId == androidId,
    )) {
      androidId = _boundedAlarmId(androidId + 1);
    }
    final scheduled = _ScheduledAlarm(
      androidId: androidId,
      payload: payload.copyWith(
        fireAt: fireAt,
        isAlarmClock: alarmClock,
        notificationId: androidId,
      ),
    );
    // Reusing the ID atomically replaces an alarm; don't cancel the old alarm first.
    await _scheduleNative(scheduled);
    _scheduledAlarms[payload.alarmId] = scheduled;
    try {
      await _persistScheduledAlarms();
    } catch (_) {
      if (existing != null) {
        _scheduledAlarms[payload.alarmId] = existing;
        await _scheduleNative(existing);
      } else {
        _scheduledAlarms.remove(payload.alarmId);
        await AndroidAlarmManager.cancel(androidId);
      }
      rethrow;
    }
    return androidId;
  }

  Future<void> cancelAlarmById(String alarmId) async {
    await _reloadScheduledAlarms();
    final scheduled = _scheduledAlarms[alarmId];
    if (scheduled == null) return;
    if (!await AndroidAlarmManager.cancel(scheduled.androidId)) {
      throw const AlarmSchedulingException(
        'Android could not cancel this alarm. Please retry.',
      );
    }
    await _notificationsPlugin.cancel(scheduled.androidId);
    _scheduledAlarms.remove(alarmId);
    await _persistScheduledAlarms();
  }

  Future<void> cancelAllAlarms() async {
    await _reloadScheduledAlarms();
    for (final id in _scheduledAlarms.keys.toList()) {
      await cancelAlarmById(id);
    }
  }

  Future<void> markCompleted(String alarmId) async {
    await _reloadScheduledAlarms();
    final scheduled = _scheduledAlarms[alarmId];
    final active = _activePayload;
    await _notificationsPlugin.cancel(
      active?.alarmId == alarmId
          ? active!.notificationId ?? _stableAlarmId(alarmId)
          : scheduled?.androidId ?? _stableAlarmId(alarmId),
    );
    // The next daily occurrence may already have been registered in the background.
    if (scheduled != null &&
        !scheduled.payload.fireAt.isAfter(DateTime.now())) {
      _scheduledAlarms.remove(alarmId);
      await _persistScheduledAlarms();
    }
  }

  static Future<void> handleBackgroundAlarm(
    int id, {
    DateTime? expectedFireAt,
  }) {
    final result = _backgroundPending.then(
      (_) => _handleBackgroundAlarm(id, expectedFireAt),
    );
    _backgroundPending = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static Future<void> _handleBackgroundAlarm(
    int id,
    DateTime? expectedFireAt,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (RootIsolateToken.instance == null) {
      DartPluginRegistrant.ensureInitialized();
    }
    final stored = await LocalStorageService.getScheduledAlarms();
    final entries = stored.entries.where((e) => e.value['androidId'] == id);
    if (entries.isEmpty) return;
    final entry = entries.first;
    final payload = AlarmPayload.fromMap(
      Map<String, dynamic>.from(entry.value['payload'] as Map),
    ).copyWith(notificationId: id);
    // A callback queued before an edit must not ring the replacement occurrence.
    if (expectedFireAt != null && expectedFireAt != payload.fireAt) return;
    final alarms = await AlarmStorageService.loadAlarms();
    final index = alarms.indexWhere((a) => a.id == payload.alarmId);
    stored.remove(entry.key);
    if ((index != -1 && !alarms[index].isEnabled) ||
        (payload.isAlarmClock && index == -1)) {
      await AndroidAlarmManager.cancel(id);
      await LocalStorageService.saveScheduledAlarms(stored);
      return;
    }
    if (index != -1 && alarms[index].isEnabled) {
      final alarm = alarms[index];
      if (alarm.repeatDaily) {
        final next =
            alarm.copyWith(clearOverride: true).nextTrigger(DateTime.now())!;
        alarms[index] = alarm.copyWith(overrideTime: next);
        final nextScheduled = _ScheduledAlarm(
          androidId: id,
          payload: payload.copyWith(
            fireAt: next,
            durationSeconds: next.difference(DateTime.now()).inSeconds,
            isAlarmClock: true,
          ),
        );
        stored[entry.key] = nextScheduled.toMap();
        try {
          await instance.ensureAlarmPermissions();
          await _scheduleNative(nextScheduled);
        } catch (error) {
          debugPrint('Could not rearm daily alarm: $error');
        }
      } else {
        alarms[index] = alarm.copyWith(isEnabled: false, clearOverride: true);
      }
      await AlarmStorageService.saveAlarms(alarms);
    }
    if (!stored.containsKey(entry.key)) await AndroidAlarmManager.cancel(id);
    await LocalStorageService.saveScheduledAlarms(stored);
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _createChannel(plugin);
    try {
      await _showNotification(plugin, payload, id);
    } finally {
      IsolateNameServer.lookupPortByName(_portName)?.send(payload.toJson());
    }
  }

  static Future<void> handleBackgroundNotification(String? payload) async {
    if (payload != null) {
      IsolateNameServer.lookupPortByName(_portName)?.send(payload);
    }
  }

  void _handleForegroundNotification(String? payload) {
    if (payload != null) _handleIncomingPayload(AlarmPayload.fromJson(payload));
  }

  Future<void> _handleIncomingPayload(AlarmPayload payload) async {
    await _reloadScheduledAlarms();
    final scheduled = _scheduledAlarms[payload.alarmId];
    if (scheduled?.payload.fireAt == payload.fireAt) {
      _scheduledAlarms.remove(payload.alarmId);
      await _persistScheduledAlarms();
    }
    if (_alarmTriggerListener != null) {
      try {
        await _alarmTriggerListener!(payload);
      } catch (error) {
        debugPrint('Could not refresh Planner after alarm: $error');
      }
    }
    if ((_activePayload?.alarmId == payload.alarmId &&
            _activePayload?.fireAt == payload.fireAt) ||
        _pendingChallenges.any(
          (p) => p.alarmId == payload.alarmId && p.fireAt == payload.fireAt,
        )) {
      return;
    }
    _pendingChallenges.add(payload);
    _openNextChallenge();
  }

  Future<void> _persistScheduledAlarms() =>
      LocalStorageService.saveScheduledAlarms(
        _scheduledAlarms.map((key, value) => MapEntry(key, value.toMap())),
      );

  static Future<void> _showNotification(
    FlutterLocalNotificationsPlugin plugin,
    AlarmPayload payload,
    int notificationId,
  ) => plugin.show(
    notificationId,
    payload.taskId?.isNotEmpty == true ? payload.taskId : 'Alarm ringing',
    'Solve the math challenge to stop the alarm',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _notificationChannelId,
        'Focus Alarm',
        channelDescription:
            'Alerts that require solving a math challenge to stop',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ticker: 'Focus alarm ringing',
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
      ),
    ),
    payload: payload.toJson(),
  );

  void _openNextChallenge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null || _challengeOpen || _pendingChallenges.isEmpty) {
        return;
      }
      final payload = _pendingChallenges.removeAt(0);
      _activePayload = payload;
      _challengeOpen = true;
      navigator
          .pushNamed(AppRoutes.mathChallenge, arguments: payload)
          .whenComplete(() {
            _challengeOpen = false;
            _activePayload = null;
            _openNextChallenge();
          });
    });
    if (navigatorKey.currentState != null) {
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  static int _stableAlarmId(String alarmId) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(alarmId)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return _boundedAlarmId(hash);
  }

  static int _boundedAlarmId(int value) {
    final masked = value & _alarmIdMask;
    return masked == 0 ? 1 : masked;
  }

  AlarmPayload? get activePayload => _activePayload;

  void dispose() {
    if (_receivePort != null) {
      IsolateNameServer.removePortNameMapping(_portName);
      _receivePort!.close();
      _receivePort = null;
    }
    _alarmTriggerListener = null;
    _pendingChallenges.clear();
  }
}

class _ScheduledAlarm {
  const _ScheduledAlarm({required this.androidId, required this.payload});
  final int androidId;
  final AlarmPayload payload;
  Map<String, dynamic> toMap() => {
    'androidId': androidId,
    'payload': payload.toMap(),
  };
}
