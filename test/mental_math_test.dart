import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusjoy/controllers/mental_math_controller.dart';
import 'package:focusjoy/models/mental_math.dart';
import 'package:focusjoy/screens/mental_math_screen.dart';
import 'package:focusjoy/services/mindful_game_storage.dart';

class _Clock implements Stopwatch {
  int _ms = 0;
  @override
  bool isRunning = false;
  void advance(int seconds) {
    if (isRunning) _ms += seconds * 1000;
  }

  @override
  Duration get elapsed => Duration(milliseconds: _ms);
  @override
  int get elapsedMilliseconds => _ms;
  @override
  int get elapsedMicroseconds => _ms * 1000;
  @override
  int get elapsedTicks => elapsedMicroseconds;
  @override
  int get frequency => 1000000;
  @override
  void start() => isRunning = true;
  @override
  void stop() => isRunning = false;
  @override
  void reset() => _ms = 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all levels produce nonnegative subtraction and exact division', () {
    final generator = MathQuestionGenerator(Random(21));
    for (final operation in MathOperation.values) {
      for (var level = 1; level <= 9; level++) {
        final settings = MathGameSettings(levels: {operation: level});
        for (var n = 0; n < 100; n++) {
          final q = generator.next(settings);
          expect(q.operation, operation);
          expect(q.answer, greaterThanOrEqualTo(0));
          if (operation == MathOperation.division) {
            expect(q.right, greaterThan(0));
            expect(q.left % q.right, 0);
            expect(q.answer * q.right, q.left);
          }
          expect(MathQuestion.fromMap(q.toMap()).answer, q.answer);
        }
      }
    }
  });

  test(
    'higher levels increase operand sizes and invalid settings are rejected',
    () {
      int largest(int level) {
        final generator = MathQuestionGenerator(Random(1));
        final settings = MathGameSettings(
          levels: {MathOperation.addition: level},
        );
        return List.generate(
          100,
          (_) => generator.next(settings).left,
        ).reduce(max);
      }

      expect(largest(9), greaterThan(largest(1) * 100));
      expect(() => MathGameSettings(levels: {}), throwsArgumentError);
      expect(
        () => MathGameSettings(levels: {MathOperation.addition: 10}),
        throwsArgumentError,
      );
    },
  );

  test('daily allowance survives reopening and date changes', () async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime(2026, 10, 31, 12);
    final store = MindfulGameStorage(prefs);
    expect(await store.consumeSeconds(today, 599), isTrue);
    final reopened = MindfulGameStorage(prefs);
    expect(reopened.remainingSeconds(today), 1);
    expect(await reopened.consumeSeconds(today, 2), isFalse);
    expect(reopened.remainingSeconds(today), 1);
    expect(await reopened.consumeSeconds(today, 1), isTrue);
    expect(await reopened.consumeSeconds(today, 1), isFalse);
    expect(reopened.remainingSeconds(today.add(const Duration(days: 1))), 600);
    expect(reopened.remainingSeconds(today), 0);
  });

  test('concurrent requests cannot exceed the daily cap', () async {
    final store = MindfulGameStorage(await SharedPreferences.getInstance());
    final now = DateTime(2026, 10, 31);
    final granted = await Future.wait([
      store.consumeSeconds(now, 400),
      MindfulGameStorage(
        await SharedPreferences.getInstance(),
      ).consumeSeconds(now, 400),
    ]);
    expect(granted.where((g) => g).length, 1);
    expect(store.remainingSeconds(now), 200);
  });

  test(
    'a round cannot start after the app backgrounds during startup',
    () async {
      final controller = MentalMathController();
      await controller.initialize();
      final starting = controller.start(MathGameSettings());
      await controller.stop(MathFinishReason.backgrounded);
      await starting;
      expect(controller.playing, isFalse);
      expect(controller.history, isEmpty);
      expect(controller.dailyRemaining, 600);
      controller.dispose();
    },
  );

  test(
    'practice results preserve answers, settings, elapsed time and history',
    () async {
      final clock = _Clock();
      final now = DateTime(2026, 10, 31, 12);
      final controller = MentalMathController(clock: clock, now: () => now);
      await controller.initialize();
      await controller.start(
        MathGameSettings(
          levels: {MathOperation.multiplication: 3},
          mode: MathRoundMode.practice,
        ),
      );
      for (var n = 0; n < 10; n++) {
        clock.advance(2);
        await controller.submit(
          n == 0
              ? null
              : n == 1
              ? -1
              : controller.question!.answer,
        );
      }
      expect(controller.playing, isFalse);
      final result = controller.result!;
      expect(result.reason, MathFinishReason.questionTarget);
      expect(result.correct, 8);
      expect(result.wrong, 1);
      expect(result.skipped, 1);
      expect(result.accuracy, 0.8);
      expect(result.elapsedMilliseconds, 20000);
      expect(result.correctPerMinute, 24);
      expect(controller.resultSaveError, isNull);
      controller.dispose();
      final reopened = MentalMathController(now: () => now);
      await reopened.initialize();
      expect(reopened.history.single.id, result.id);
      expect(reopened.history.single.attempts.length, 10);
      expect(reopened.settings.levels, {MathOperation.multiplication: 3});
      expect(reopened.dailyRemaining, 580);
      reopened.dispose();
    },
  );

  test('timed rounds reject answers submitted after the deadline', () async {
    final clock = _Clock();
    final controller = MentalMathController(clock: clock);
    await controller.initialize();
    await controller.start(MathGameSettings(minutes: 1));
    final answer = controller.question!.answer;
    clock.advance(61);
    await controller.submit(answer);
    expect(controller.result!.reason, MathFinishReason.timer);
    expect(controller.result!.attempts, isEmpty);
    expect(controller.result!.elapsedMilliseconds, 60000);
    expect(controller.dailyRemaining, 540);
    controller.dispose();
  });

  test(
    'daily allowance cuts off practice and blocks another round after reopening',
    () async {
      final now = DateTime(2026, 10, 31, 12);
      await MindfulGameStorage(
        await SharedPreferences.getInstance(),
      ).consumeSeconds(now, 598);
      final clock = _Clock();
      final controller = MentalMathController(clock: clock, now: () => now);
      await controller.initialize();
      await controller.start(MathGameSettings(mode: MathRoundMode.practice));
      clock.advance(3);
      await controller.submit(controller.question!.answer);
      expect(controller.result!.reason, MathFinishReason.dailyLimit);
      expect(controller.result!.attempts, isEmpty);
      expect(controller.dailyRemaining, 0);
      controller.dispose();
      final reopened = MentalMathController(now: () => now);
      await reopened.initialize();
      await reopened.start(MathGameSettings());
      expect(reopened.playing, isFalse);
      expect(reopened.dailyRemaining, 0);
      reopened.dispose();
    },
  );

  test(
    'backgrounding saves a partial round without counting it as complete',
    () async {
      final clock = _Clock();
      final controller = MentalMathController(clock: clock);
      await controller.initialize();
      await controller.start(MathGameSettings());
      clock.advance(5);
      await controller.submit(controller.question!.answer);
      await controller.stop(MathFinishReason.backgrounded);
      expect(clock.isRunning, isFalse);
      expect(controller.result!.reason, MathFinishReason.backgrounded);
      expect(controller.result!.correct, 1);
      expect(controller.result!.completed, isFalse);
      expect(controller.history.single.id, controller.result!.id);
      controller.dispose();
    },
  );

  test(
    'midnight ends the old round without spending the new day allowance',
    () async {
      var now = DateTime(2026, 10, 31, 23, 59, 59);
      final clock = _Clock();
      final controller = MentalMathController(clock: clock, now: () => now);
      await controller.initialize();
      await controller.start(MathGameSettings());
      now = now.add(const Duration(seconds: 2));
      clock.advance(2);
      await controller.submit(controller.question!.answer);
      expect(controller.result!.reason, MathFinishReason.newDay);
      await controller.refreshAllowance();
      expect(controller.dailyRemaining, 600);
      controller.dispose();
    },
  );

  test(
    'malformed saved history blocks play and is never overwritten',
    () async {
      SharedPreferences.setMockInitialValues({
        'focusjoy_mental_math_history_v1': 'broken',
      });
      final controller = MentalMathController();
      await controller.initialize();
      expect(controller.error, isNotNull);
      await controller.start(MathGameSettings());
      expect(controller.playing, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'focusjoy_mental_math_history_v1',
        ),
        'broken',
      );
      controller.dispose();
    },
  );

  test('retrying a result save does not duplicate history', () async {
    final result = MathRoundResult(
      id: 'round-1',
      startedAt: DateTime(2026, 10, 31),
      settings: MathGameSettings(),
      elapsedMilliseconds: 60000,
      reason: MathFinishReason.timer,
      attempts: const [],
    );
    final store = MindfulGameStorage(await SharedPreferences.getInstance());
    await store.saveResult(result);
    await store.saveResult(result);
    expect(store.loadHistory(), hasLength(1));
  });

  testWidgets('setup offers difficulty controls and saved history', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MentalMathScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Mental Maths'), findsOneWidget);
    expect(find.text('10:00 left today'), findsOneWidget);
    expect(find.text('Choose your operations'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your rounds will appear here.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
