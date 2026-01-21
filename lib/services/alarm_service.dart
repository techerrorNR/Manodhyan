import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alarm_payload.dart';
import '../routes.dart';
import 'local_storage_service.dart';

typedef AlarmTriggerListener = Future<void> Function(AlarmPayload payload);

@pragma('vm:entry-point')
void alarmFiredCallback(int id) {
  AlarmService.handleBackgroundAlarm(id);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  AlarmService.handleBackgroundNotification(details.payload);
}

class AlarmService {
  AlarmService._internal();

  static final AlarmService instance = AlarmService._internal();

  static const _portName = 'manodhyan_alarm_port';
  static const _notificationChannelId = 'manodhyan_alarm_channel';
  static const int _alarmIdMask = 0x7FFFFFFF;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Map<String, _ScheduledAlarm> _scheduledAlarms = {};
  ReceivePort? _receivePort;
  AlarmPayload? _activePayload;
  AlarmTriggerListener? _alarmTriggerListener;

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await _initNotifications();
    _registerPort();
    await _restoreScheduledAlarms();
  }

  void registerAlarmListener(AlarmTriggerListener listener) {
    _alarmTriggerListener = listener;
  }

  void unregisterAlarmListener(AlarmTriggerListener listener) {
    if (_alarmTriggerListener == listener) {
      _alarmTriggerListener = null;
    }
  }

  Future<void> _initNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleForegroundNotification(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    final details =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payload = details?.notificationResponse?.payload;
      _handleForegroundNotification(payload);
    }
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
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
    _receivePort ??= ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(
        _receivePort!.sendPort, _portName);
    _receivePort!.listen((message) {
      if (message is String) {
        final payload = AlarmPayload.fromJson(message);
        _handleIncomingPayload(payload);
      }
    });
  }

  Future<void> _restoreScheduledAlarms() async {
    final stored = await LocalStorageService.getScheduledAlarms();
    if (stored.isEmpty) return;
    final now = DateTime.now();
    final refreshed = <String, Map<String, dynamic>>{};
    for (final entry in stored.entries) {
      final alarmId = entry.key;
      final data = entry.value;
      final payloadMap =
          (data['payload'] as Map<dynamic, dynamic>?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              <String, dynamic>{};
      if (payloadMap.isEmpty) continue;
      final payload = AlarmPayload.fromMap(payloadMap);
      final storedAndroidId = data['androidId'] as int?;
      final androidId = storedAndroidId ??
          _boundedAlarmId(payload.fireAt.millisecondsSinceEpoch);
      if (payload.fireAt.isAfter(now)) {
        await AndroidAlarmManager.oneShotAt(
          payload.fireAt,
          androidId,
          alarmFiredCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        _scheduledAlarms[alarmId] =
            _ScheduledAlarm(androidId: androidId, payload: payload);
        refreshed[alarmId] = {
          'androidId': androidId,
          'payload': payload.toMap(),
        };
      } else {
        await _showAlarmNotification(payload, androidId);
        await _handleIncomingPayload(payload);
      }
    }
    await LocalStorageService.saveScheduledAlarms(refreshed);
  }

  Future<int> scheduleAlarm(DateTime fireAt, AlarmPayload payload) async {
    final existing = _scheduledAlarms[payload.alarmId];
    if (existing != null) {
      await AndroidAlarmManager.cancel(existing.androidId);
      await _notificationsPlugin.cancel(existing.androidId);
    }
    final androidId =
        _boundedAlarmId(fireAt.millisecondsSinceEpoch ^ payload.alarmId.hashCode);
    await AndroidAlarmManager.oneShotAt(
      fireAt,
      androidId,
      alarmFiredCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    _scheduledAlarms[payload.alarmId] =
        _ScheduledAlarm(androidId: androidId, payload: payload);
    await _persistScheduledAlarms();
    return androidId;
  }

  Future<void> cancelAlarmById(String alarmId) async {
    final scheduled = _scheduledAlarms.remove(alarmId);
    if (scheduled == null) return;
    await AndroidAlarmManager.cancel(scheduled.androidId);
    await _notificationsPlugin.cancel(scheduled.androidId);
    await _persistScheduledAlarms();
  }

  Future<void> cancelAllAlarms() async {
    for (final entry in _scheduledAlarms.values) {
      await AndroidAlarmManager.cancel(entry.androidId);
      await _notificationsPlugin.cancel(entry.androidId);
    }
    _scheduledAlarms.clear();
    await LocalStorageService.clearScheduledAlarms();
  }

  Future<void> markCompleted(String alarmId) async {
    final scheduled = _scheduledAlarms.remove(alarmId);
    if (scheduled != null) {
      await _notificationsPlugin.cancel(scheduled.androidId);
      await _persistScheduledAlarms();
    }
  }

  static Future<void> handleBackgroundAlarm(int id) async {
    WidgetsFlutterBinding.ensureInitialized();
    final stored = await LocalStorageService.getScheduledAlarms();
    if (stored.isEmpty) return;
    String? alarmId;
    Map<String, dynamic>? data;
    stored.forEach((key, value) {
      if (alarmId != null) return;
      final androidId = value['androidId'] as int?;
      if (androidId == id) {
        alarmId = key;
        data = value;
      }
    });
    if (alarmId == null || data == null) return;
    final payloadMap =
        (data!['payload'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            <String, dynamic>{};
    final payload = AlarmPayload.fromMap(payloadMap);
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(
      android: androidInit,
    ));
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
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
    await _showNotification(plugin, payload, id);
    stored.remove(alarmId);
    await LocalStorageService.saveScheduledAlarms(stored);
    final sendPort = IsolateNameServer.lookupPortByName(_portName);
    sendPort?.send(payload.toJson());
  }

  static Future<void> handleBackgroundNotification(String? payload) async {
    final sendPort = IsolateNameServer.lookupPortByName(_portName);
    if (payload != null) {
      sendPort?.send(payload);
    }
  }

  void _handleForegroundNotification(String? payload) {
    if (payload == null) return;
    final parsed = AlarmPayload.fromJson(payload);
    _handleIncomingPayload(parsed);
  }

  Future<void> _handleIncomingPayload(AlarmPayload payload) async {
    _activePayload = payload;
    await _removeScheduledAlarm(payload.alarmId);
    final listener = _alarmTriggerListener;
    if (listener != null) {
      unawaited(listener(payload));
    }
    _openMathChallenge(payload);
  }

  Future<void> _removeScheduledAlarm(String alarmId) async {
    final removed = _scheduledAlarms.remove(alarmId);
    if (removed != null) {
      await _persistScheduledAlarms();
    }
  }

  Future<void> _persistScheduledAlarms() async {
    await LocalStorageService.saveScheduledAlarms(
      _scheduledAlarms.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    );
  }

  Future<void> _showAlarmNotification(
      AlarmPayload payload, int notificationId) async {
    await _showNotification(_notificationsPlugin, payload, notificationId);
  }

  static Future<void> _showNotification(
    FlutterLocalNotificationsPlugin plugin,
    AlarmPayload payload,
    int notificationId,
  ) async {
    const androidDetails = AndroidNotificationDetails(
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
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await plugin.show(
      notificationId,
      'Alarm ringing',
      'Solve the math challenge to stop the alarm',
      notificationDetails,
      payload: payload.toJson(),
    );
  }

  void _openMathChallenge(AlarmPayload payload) {
    navigatorKey.currentState
        ?.popUntil((route) => route.settings.name != AppRoutes.mathChallenge);
    navigatorKey.currentState?.pushNamed(
      AppRoutes.mathChallenge,
      arguments: payload,
    );
  }

  static int _boundedAlarmId(int rawValue) {
    final masked = rawValue & _alarmIdMask;
    return masked == 0 ? 1 : masked;
  }

  AlarmPayload? get activePayload => _activePayload;
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
