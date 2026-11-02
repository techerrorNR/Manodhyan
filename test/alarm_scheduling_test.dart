import 'dart:convert';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusjoy/controllers/alarm_controller.dart';
import 'package:focusjoy/models/alarm_model.dart';
import 'package:focusjoy/models/alarm_payload.dart';
import 'package:focusjoy/services/alarm_service.dart';
import 'package:focusjoy/services/alarm_storage_service.dart';
import 'package:focusjoy/services/local_storage_service.dart';

class _Alarms extends Fake implements AlarmService {
  bool permitted = true;
  bool failNext = false;
  int requests = 0;
  final scheduled = <String, AlarmPayload>{};
  final modes = <String, bool>{};
  final cancelled = <String>[];
  AlarmTriggerListener? listener;
  @override
  Future<void> ensureAlarmPermissions({bool request = false}) async {
    if (request) requests++;
    if (!permitted) throw const AlarmSchedulingException('Alarm access denied');
  }

  @override
  Future<int> scheduleAlarm(
    DateTime fireAt,
    AlarmPayload payload, {
    bool alarmClock = false,
  }) async {
    if (failNext) {
      failNext = false;
      throw const AlarmSchedulingException('Android rejected alarm');
    }
    scheduled[payload.alarmId] = payload;
    modes[payload.alarmId] = alarmClock;
    return 1;
  }

  @override
  Future<void> cancelAlarmById(String id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  void registerAlarmListener(AlarmTriggerListener listener) =>
      this.listener = listener;
  @override
  void unregisterAlarmListener(AlarmTriggerListener listener) =>
      this.listener = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const alarmChannel = MethodChannel(
    'dev.fluttercommunity.plus/android_alarm_manager',
    JSONMethodCodec(),
  );
  var exactAllowed = true;
  var notificationAllowed = true;
  var grantRequested = false;
  var accepted = true;
  String? launchPayload;
  final nativeCalls = <MethodCall>[];
  final notificationCalls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    exactAllowed = true;
    notificationAllowed = true;
    grantRequested = false;
    accepted = true;
    launchPayload = null;
    nativeCalls.clear();
    notificationCalls.clear();
    AndroidAlarmManager.setTestOverrides(
      getCallbackHandle: (_) => CallbackHandle.fromRawHandle(42),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, (call) async {
          notificationCalls.add(call);
          switch (call.method) {
            case 'canScheduleExactNotifications':
              return exactAllowed;
            case 'areNotificationsEnabled':
              return notificationAllowed;
            case 'requestExactAlarmsPermission':
              exactAllowed = grantRequested;
              return exactAllowed;
            case 'requestNotificationsPermission':
              notificationAllowed = grantRequested;
              return notificationAllowed;
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return launchPayload == null
                  ? null
                  : {
                    'notificationLaunchedApp': true,
                    'notificationResponse': {
                      'notificationResponseType': 0,
                      'notificationId': 100,
                      'payload': launchPayload,
                    },
                  };
            default:
              return null;
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, (call) async {
          nativeCalls.add(call);
          return call.method == 'Alarm.oneShotAt' ? accepted : true;
        });
  });
  tearDown(() {
    AndroidAlarmManager.setTestOverrides(
      getCallbackHandle: PluginUtilities.getCallbackHandle,
    );
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, null);
  });

  AlarmPayload payload(String id) => AlarmPayload(
    alarmId: id,
    durationSeconds: 60,
    fireAt: DateTime.now().add(const Duration(minutes: 1)),
  );
  AlarmModel alarm(String id, {bool enabled = true, bool daily = true}) =>
      AlarmModel(
        id: id,
        hour: (DateTime.now().hour + 1) % 24,
        minute: 5,
        label: id,
        repeatDaily: daily,
        isEnabled: enabled,
      );

  test(
    'denied exact access cannot silently register or persist an alarm',
    () async {
      exactAllowed = false;
      final service = AlarmService.testing();
      final p = payload('denied');
      await expectLater(
        service.scheduleAlarm(p.fireAt, p, alarmClock: true),
        throwsA(isA<AlarmSchedulingException>()),
      );
      expect(nativeCalls, isEmpty);
      expect(await LocalStorageService.getScheduledAlarms(), isEmpty);
      expect(
        notificationCalls.any(
          (c) => c.method == 'requestExactAlarmsPermission',
        ),
        isFalse,
      );
    },
  );

  test(
    'explicit permission request rechecks both alarm and notification access',
    () async {
      exactAllowed = false;
      notificationAllowed = false;
      grantRequested = true;
      await AlarmService.testing().ensureAlarmPermissions(request: true);
      expect(exactAllowed, isTrue);
      expect(notificationAllowed, isTrue);
      expect(
        notificationCalls.where(
          (c) => c.method == 'requestExactAlarmsPermission',
        ),
        hasLength(1),
      );
      expect(
        notificationCalls.where(
          (c) => c.method == 'requestNotificationsPermission',
        ),
        hasLength(1),
      );
    },
  );

  test('notification denial is reported before scheduling', () async {
    notificationAllowed = false;
    final p = payload('muted');
    await expectLater(
      AlarmService.testing().scheduleAlarm(p.fireAt, p),
      throwsA(isA<AlarmSchedulingException>()),
    );
    expect(nativeCalls, isEmpty);
  });

  test(
    'Planner uses alarm-clock mode and persists only after Android accepts',
    () async {
      final p = payload('planner');
      final id = await AlarmService.testing().scheduleAlarm(
        p.fireAt,
        p,
        alarmClock: true,
      );
      final args = nativeCalls.single.arguments as List;
      expect(args[0], id);
      expect(args[1], isTrue); // Android AlarmClockInfo / setAlarmClock.
      expect(args[2], isTrue); // Idle delivery.
      expect(args[3], isTrue); // Exact.
      expect(args[4], isTrue); // Wakeup.
      expect(args[6], isTrue); // Restore on reboot.
      final saved = await LocalStorageService.getScheduledAlarms();
      expect(saved['planner']!['androidId'], id);
      expect((saved['planner']!['payload'] as Map)['isAlarmClock'], isTrue);
    },
  );

  test(
    'native false is a failure and does not leave a saved enabled registration',
    () async {
      accepted = false;
      final p = payload('rejected');
      await expectLater(
        AlarmService.testing().scheduleAlarm(p.fireAt, p),
        throwsA(isA<AlarmSchedulingException>()),
      );
      expect(await LocalStorageService.getScheduledAlarms(), isEmpty);
    },
  );

  test(
    'a failed edit leaves the previous alarm intact and never cancels it first',
    () async {
      final p = payload('edit');
      final service = AlarmService.testing();
      final id = await service.scheduleAlarm(p.fireAt, p, alarmClock: true);
      accepted = false;
      await expectLater(
        service.scheduleAlarm(
          p.fireAt.add(const Duration(minutes: 1)),
          p,
          alarmClock: true,
        ),
        throwsA(isA<AlarmSchedulingException>()),
      );
      expect(nativeCalls.where((c) => c.method == 'Alarm.cancel'), isEmpty);
      final saved = await LocalStorageService.getScheduledAlarms();
      expect(saved['edit']!['androidId'], id);
      expect(
        (saved['edit']!['payload'] as Map)['fireAt'],
        p.fireAt.toIso8601String(),
      );
    },
  );

  test(
    'ordinary focus timers stay distinct from system alarm-clock entries',
    () async {
      final p = payload('focus');
      final id = await AlarmService.testing().scheduleAlarm(p.fireAt, p);
      expect((nativeCalls.single.arguments as List)[1], isFalse);
      final secondId = await AlarmService.testing().scheduleAlarm(p.fireAt, p);
      expect(secondId, id);
    },
  );

  test(
    'all configured alarms are registered, not just the earliest one',
    () async {
      await AlarmStorageService.saveAlarms([alarm('first'), alarm('second')]);
      final backend = _Alarms();
      final controller = AlarmController(alarmService: backend);
      await controller.initialize();
      expect(backend.scheduled.keys, unorderedEquals(['first', 'second']));
      expect(backend.modes.values, everyElement(isTrue));
      await controller.toggleAlarm('first', false);
      expect(backend.cancelled, contains('first'));
      expect(backend.scheduled.keys, ['second']);
      controller.dispose();
    },
  );

  test('permission denial does not save a phantom enabled alarm', () async {
    final backend = _Alarms()..permitted = false;
    final controller = AlarmController(alarmService: backend);
    await controller.initialize();
    await expectLater(
      controller.addAlarm(
        time: const TimeOfDay(hour: 9, minute: 10),
        label: 'Denied',
      ),
      throwsA(isA<AlarmSchedulingException>()),
    );
    expect(backend.requests, 1);
    expect(controller.alarms, isEmpty);
    expect(await AlarmStorageService.loadAlarms(), isEmpty);
    expect(controller.schedulingError, isNotNull);
    controller.dispose();
  });

  test(
    'restoration loads saved alarms even without permission and retries after grant',
    () async {
      await AlarmStorageService.saveAlarms([alarm('saved')]);
      final backend = _Alarms()..permitted = false;
      final controller = AlarmController(alarmService: backend);
      await controller.initialize();
      expect(controller.alarms.single.id, 'saved');
      expect(controller.schedulingError, isNotNull);
      expect(backend.scheduled, isEmpty);
      backend.permitted = true;
      await controller.refreshScheduling();
      expect(backend.scheduled.keys, ['saved']);
      expect(controller.schedulingError, isNull);
      controller.dispose();
    },
  );

  test(
    'a rejected edit does not overwrite the original alarm configuration',
    () async {
      await AlarmStorageService.saveAlarms([alarm('saved')]);
      final backend = _Alarms();
      final controller = AlarmController(alarmService: backend);
      await controller.initialize();
      backend.failNext = true;
      await expectLater(
        controller.updateAlarm(
          controller.alarms.single.copyWith(label: 'Edited'),
        ),
        throwsA(isA<AlarmSchedulingException>()),
      );
      expect(controller.alarms.single.label, 'saved');
      expect((await AlarmStorageService.loadAlarms()).single.label, 'saved');
      controller.dispose();
    },
  );

  test(
    'rapid alarm additions are serialized without losing either alarm',
    () async {
      final backend = _Alarms();
      final controller = AlarmController(alarmService: backend);
      await controller.initialize();
      await Future.wait([
        controller.addAlarm(
          time: const TimeOfDay(hour: 9, minute: 10),
          label: 'One',
        ),
        controller.addAlarm(
          time: const TimeOfDay(hour: 10, minute: 10),
          label: 'Two',
        ),
      ]);
      expect(controller.alarms, hasLength(2));
      expect(backend.scheduled, hasLength(2));
      expect(await AlarmStorageService.loadAlarms(), hasLength(2));
      controller.dispose();
    },
  );

  test(
    'background delivery rearms daily alarms without a foreground controller',
    () async {
      final a = alarm('daily');
      await AlarmStorageService.saveAlarms([a]);
      final p = payload(a.id);
      final service = AlarmService.testing();
      final id = await service.scheduleAlarm(p.fireAt, p, alarmClock: true);
      await AlarmService.handleBackgroundAlarm(id);
      final config = (await AlarmStorageService.loadAlarms()).single;
      expect(config.isEnabled, isTrue);
      expect(config.overrideTime!.isAfter(DateTime.now()), isTrue);
      final saved = await LocalStorageService.getScheduledAlarms();
      final next = AlarmPayload.fromMap(
        Map<String, dynamic>.from(saved[a.id]!['payload'] as Map),
      );
      expect(next.fireAt, config.overrideTime);
      expect(next.isAlarmClock, isTrue);
      expect(notificationCalls.where((c) => c.method == 'show'), hasLength(1));
      await service.markCompleted(a.id);
      expect(
        (await LocalStorageService.getScheduledAlarms()).containsKey(a.id),
        isTrue,
      );
    },
  );

  test(
    'background one-time delivery disables its config and preserves other alarms',
    () async {
      await AlarmStorageService.saveAlarms([
        alarm('once', daily: false),
        alarm('other'),
      ]);
      final service = AlarmService.testing();
      final first = payload('once');
      final other = payload('other');
      final id = await service.scheduleAlarm(
        first.fireAt,
        first,
        alarmClock: true,
      );
      await service.scheduleAlarm(other.fireAt, other, alarmClock: true);
      await AlarmService.handleBackgroundAlarm(id);
      final configs = await AlarmStorageService.loadAlarms();
      expect(configs.first.isEnabled, isFalse);
      expect(configs.last.isEnabled, isTrue);
      expect((await LocalStorageService.getScheduledAlarms()).keys, ['other']);
      final notification = notificationCalls.lastWhere(
        (c) => c.method == 'show',
      );
      expect(
        AlarmPayload.fromJson(
          (notification.arguments as Map)['payload'] as String,
        ).alarmId,
        'once',
      );
    },
  );

  test('new payload fields remain backward compatible with saved alarms', () {
    final old =
        payload('legacy').toMap()
          ..remove('isAlarmClock')
          ..remove('notificationId');
    final restored = AlarmPayload.fromJson(jsonEncode(old));
    expect(restored.isAlarmClock, isFalse);
    expect(restored.notificationId, isNull);
  });

  test('stale callbacks do not ring an edited alarm occurrence', () async {
    final service = AlarmService.testing();
    await AlarmStorageService.saveAlarms([alarm('edited')]);
    final p = payload('edited');
    final id = await service.scheduleAlarm(p.fireAt, p, alarmClock: true);
    final changed = p.fireAt.add(const Duration(minutes: 3));
    await service.scheduleAlarm(changed, p, alarmClock: true);
    await AlarmService.handleBackgroundAlarm(id, expectedFireAt: p.fireAt);
    expect(notificationCalls.where((c) => c.method == 'show'), isEmpty);
    final stored = await LocalStorageService.getScheduledAlarms();
    expect(
      (stored[p.alarmId]!['payload'] as Map)['fireAt'],
      changed.toIso8601String(),
    );
    expect(nativeCalls.where((c) => c.method == 'Alarm.cancel'), isEmpty);
  });

  test(
    'deleted Planner alarms cannot ring from a callback already queued',
    () async {
      final p = payload('deleted');
      final id = await AlarmService.testing().scheduleAlarm(
        p.fireAt,
        p,
        alarmClock: true,
      );
      await AlarmService.handleBackgroundAlarm(id, expectedFireAt: p.fireAt);
      expect(notificationCalls.where((c) => c.method == 'show'), isEmpty);
      expect(await LocalStorageService.getScheduledAlarms(), isEmpty);
    },
  );

  test('simultaneous daily callbacks retain both next occurrences', () async {
    await AlarmStorageService.saveAlarms([alarm('a'), alarm('b')]);
    final service = AlarmService.testing();
    final a = payload('a');
    final b = payload('b');
    final aId = await service.scheduleAlarm(a.fireAt, a, alarmClock: true);
    final bId = await service.scheduleAlarm(b.fireAt, b, alarmClock: true);
    await Future.wait([
      AlarmService.handleBackgroundAlarm(aId, expectedFireAt: a.fireAt),
      AlarmService.handleBackgroundAlarm(bId, expectedFireAt: b.fireAt),
    ]);
    final pending = await LocalStorageService.getScheduledAlarms();
    expect(pending.keys, unorderedEquals(['a', 'b']));
    expect(notificationCalls.where((c) => c.method == 'show'), hasLength(2));
    expect(
      (await AlarmStorageService.loadAlarms()).every(
        (a) => a.overrideTime != null,
      ),
      isTrue,
    );
  });

  testWidgets(
    'notification cold start waits for Navigator even if alarm access was revoked',
    (tester) async {
      exactAllowed = false;
      launchPayload = payload('cold-start').toJson();
      final service = AlarmService.testing();
      await service.initialize();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: service.navigatorKey,
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute:
              (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder:
                    (_) => Scaffold(
                      body: Text(
                        'Alarm: ${(settings.arguments as AlarmPayload).alarmId}',
                      ),
                    ),
              ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alarm: cold-start'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
