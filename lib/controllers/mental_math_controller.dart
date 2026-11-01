import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/mental_math.dart';
import '../services/mindful_game_storage.dart';

class MentalMathController extends ChangeNotifier {
  MentalMathController({Stopwatch? clock, DateTime Function()? now})
    : _clock = clock ?? Stopwatch(),
      _now = now ?? DateTime.now;

  final _generator = MathQuestionGenerator();
  final Stopwatch _clock;
  final DateTime Function() _now;
  late MindfulGameStorage _storage;
  Timer? _timer;
  bool _disposed = false;
  bool _busy = false;
  bool _cancelStarting = false;
  bool loading = true;
  bool playing = false;
  bool savingResult = false;
  String? error;
  String? resultSaveError;
  MathGameSettings settings = MathGameSettings();
  List<MathRoundResult> history = [];
  MathRoundResult? result;
  MathQuestion? question;
  final List<MathAttempt> _attempts = [];
  DateTime? _startedAt;
  int _questionStartMs = 0;
  int _allocatedSeconds = 0;
  int _roundSeconds = 0;
  bool _budgetLimited = false;
  int dailyRemaining = MindfulGameStorage.dailyLimitSeconds;
  int get attempted => _attempts.length;
  int get correct => _attempts.where((a) => a.correct).length;
  int get secondsLeft => max(0, _roundSeconds - _clock.elapsed.inSeconds);
  bool get busy => _busy || savingResult;

  Future<void> initialize() async {
    loading = true;
    error = null;
    _notify();
    try {
      _storage = MindfulGameStorage(await SharedPreferences.getInstance());
      settings = _storage.loadSettings();
      history = _storage.loadHistory();
      dailyRemaining = _storage.remainingSeconds(_now());
    } catch (_) {
      error = 'Saved game data could not be loaded. Please retry.';
    }
    loading = false;
    _notify();
  }

  Future<void> refreshAllowance() async {
    if (loading || playing || error != null) return;
    try {
      dailyRemaining = _storage.remainingSeconds(_now());
    } catch (_) {
      error = 'The daily allowance could not be loaded. Please retry.';
    }
    _notify();
  }

  Future<void> start(MathGameSettings chosen) async {
    if (busy || playing || loading || error != null) return;
    _cancelStarting = false;
    _busy = true;
    error = null;
    _notify();
    try {
      final now = _now();
      dailyRemaining = _storage.remainingSeconds(now);
      if (dailyRemaining < 1) return;
      await _storage.saveSettings(chosen);
      if (_cancelStarting || _disposed) return;
      // Reserve the first second before play so reopening cannot erase usage.
      if (!await _storage.consumeSeconds(now, 1)) return;
      if (_cancelStarting || _disposed) return;
      settings = chosen;
      _roundSeconds = min(
        dailyRemaining,
        chosen.mode == MathRoundMode.timed
            ? chosen.minutes * 60
            : dailyRemaining,
      );
      _budgetLimited =
          chosen.mode == MathRoundMode.practice ||
          dailyRemaining <= chosen.minutes * 60;
      dailyRemaining--;
      _allocatedSeconds = 1;
      _startedAt = now;
      _questionStartMs = 0;
      _attempts.clear();
      result = null;
      resultSaveError = null;
      question = _generator.next(settings);
      playing = true;
      _clock
        ..reset()
        ..start();
      _timer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tick(),
      );
    } catch (_) {
      error =
          'The round could not start because its settings or allowance could not be saved. Please retry.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<MathFinishReason?> _checkpoint() async {
    if (MindfulGameStorage.dayKey(_now()) !=
        MindfulGameStorage.dayKey(_startedAt!)) {
      return MathFinishReason.newDay;
    }
    final elapsedMs = min(_clock.elapsedMilliseconds, _roundSeconds * 1000);
    final requiredSeconds = max(1, (elapsedMs / 1000).ceil());
    if (requiredSeconds > _allocatedSeconds) {
      if (!await _storage.consumeSeconds(
        _startedAt!,
        requiredSeconds - _allocatedSeconds,
      )) {
        return MathFinishReason.dailyLimit;
      }
      _allocatedSeconds = requiredSeconds;
      dailyRemaining = _storage.remainingSeconds(_now());
    }
    if (_clock.elapsedMilliseconds >= _roundSeconds * 1000) {
      return _budgetLimited
          ? MathFinishReason.dailyLimit
          : MathFinishReason.timer;
    }
    return null;
  }

  Future<void> _tick() async {
    if (_busy || !playing || _disposed) return;
    _busy = true;
    try {
      final reason = await _checkpoint();
      if (reason != null) await _finish(reason);
    } catch (_) {
      await _finish(MathFinishReason.storageError);
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> submit(int? answer) async {
    if (_busy || !playing) return;
    _busy = true;
    try {
      final end = await _checkpoint();
      if (end != null) {
        await _finish(end);
        return;
      }
      final elapsed = _clock.elapsedMilliseconds;
      _attempts.add(
        MathAttempt(
          question: question!,
          givenAnswer: answer,
          milliseconds: elapsed - _questionStartMs,
        ),
      );
      _questionStartMs = elapsed;
      if (settings.mode == MathRoundMode.practice &&
          attempted >= settings.questionCount) {
        await _finish(MathFinishReason.questionTarget);
      } else {
        question = _generator.next(settings);
      }
    } catch (_) {
      await _finish(MathFinishReason.storageError);
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> stop([
    MathFinishReason reason = MathFinishReason.stopped,
  ]) async {
    _cancelStarting = true;
    if (!playing) return;
    // Stop wall time immediately when the app leaves the foreground.
    _clock.stop();
    while (_busy && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (!playing || _disposed) return;
    _busy = true;
    try {
      final end = await _checkpoint();
      await _finish(end ?? reason);
    } catch (_) {
      await _finish(MathFinishReason.storageError);
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> _finish(MathFinishReason reason) async {
    if (!playing) return;
    playing = false;
    _timer?.cancel();
    _clock.stop();
    result = MathRoundResult(
      id: const Uuid().v4(),
      startedAt: _startedAt!,
      settings: settings,
      elapsedMilliseconds: min(
        _clock.elapsedMilliseconds,
        _roundSeconds * 1000,
      ),
      reason: reason,
      attempts: _attempts,
    );
    await saveResult();
  }

  Future<void> saveResult() async {
    if (result == null || savingResult) return;
    savingResult = true;
    resultSaveError = null;
    _notify();
    try {
      await _storage.saveResult(result!);
      history = _storage.loadHistory();
    } catch (_) {
      resultSaveError = 'This result has not been saved. Retry before leaving.';
    } finally {
      savingResult = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
