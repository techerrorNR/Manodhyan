import 'package:focusjoy/mind/config/app_palette.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/timer_controller.dart';
import '../models/alarm_payload.dart';
import '../services/alarm_service.dart';

class MathChallengeScreen extends StatefulWidget {
  const MathChallengeScreen({super.key, required this.payload});

  static Route<dynamic> routeFromSettings(RouteSettings settings) {
    final payload = settings.arguments as AlarmPayload?;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => MathChallengeScreen(payload: payload),
    );
  }

  final AlarmPayload? payload;

  @override
  State<MathChallengeScreen> createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends State<MathChallengeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _player = AudioPlayer();
  late final _Challenge _challenge;
  bool _isWrong = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _challenge = _Challenge.generate();
    _lockScreenState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAlarmAudio();
      _focusNode.requestFocus();
    });
  }

  Future<void> _startAlarmAudio() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    try {
      final tone = _generateAlarmTone();
      await _player.play(BytesSource(tone));
    } catch (_) {
      // If the asset is missing, fall back to a short tone.
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Uint8List _generateAlarmTone() {
    const sampleRate = 22050;
    const durationSeconds = 2;
    const frequency = 660.0;
    final sampleCount = sampleRate * durationSeconds;
    final dataSize = sampleCount * 2;
    final builder = BytesBuilder();
    builder.add(utf8.encode('RIFF'));
    builder.add(_int32LE(36 + dataSize));
    builder.add(utf8.encode('WAVE'));
    builder.add(utf8.encode('fmt '));
    builder.add(_int32LE(16));
    builder.add(_int16LE(1)); // PCM
    builder.add(_int16LE(1)); // Mono
    builder.add(_int32LE(sampleRate));
    builder.add(_int32LE(sampleRate * 2));
    builder.add(_int16LE(2)); // Block align
    builder.add(_int16LE(16)); // Bits per sample
    builder.add(utf8.encode('data'));
    builder.add(_int32LE(dataSize));
    for (int i = 0; i < sampleCount; i++) {
      final sample =
          (sin(2 * pi * frequency * i / sampleRate) * 0x7FFF).round();
      builder.add(_int16LE(sample));
    }
    return builder.toBytes();
  }

  List<int> _int16LE(int value) {
    final data = ByteData(2);
    data.setInt16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  List<int> _int32LE(int value) {
    final data = ByteData(4);
    data.setInt32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Future<void> _stopAudio() async {
    await _player.stop();
  }

  void _lockScreenState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreScreenState() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _stopAudio();
    _player.dispose();
    _restoreScreenState();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.isEmpty) return;
    final answer = int.tryParse(_controller.text);
    final isCorrect = answer == _challenge.answer;
    if (!isCorrect) {
      setState(() {
        _isWrong = true;
      });
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _isWrong = false;
        _controller.clear();
      });
      return;
    }

    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    await _stopAudio();
    final payload =
        widget.payload ??
        AlarmService.instance.activePayload ??
        AlarmPayload(
          alarmId: 'unknown',
          durationSeconds: 0,
          fireAt: DateTime.now(),
        );
    await AlarmService.instance.markCompleted(payload.alarmId);
    if (mounted) {
      final timer = context.read<TimerController>();
      if (timer.pendingPayload?.alarmId == payload.alarmId) {
        await timer.completeSession(success: true);
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload =
        widget.payload ??
        AlarmService.instance.activePayload ??
        AlarmPayload(
          alarmId: 'unknown',
          durationSeconds: 0,
          fireAt: DateTime(1970),
        );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppPalette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Solve to stop the alarm',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Session: ${payload.taskId ?? 'Focus mode'}',
                  style: const TextStyle(color: Colors.white60),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isWrong ? AppPalette.error : AppPalette.primary,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _challenge.expression,
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Enter answer',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _submit,
                        child: const Text(
                          'Verify',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      if (_isWrong) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Wrong answer. Try again!',
                          style: TextStyle(color: AppPalette.error),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'No snooze available. Stay awake until you solve it.',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Challenge {
  final String expression;
  final int answer;

  const _Challenge(this.expression, this.answer);

  factory _Challenge.generate() {
    final random = Random();
    final values = List<int>.generate(3, (_) => random.nextInt(20) + 5);
    final operations = ['+', '*'];
    final op = operations[random.nextInt(operations.length)];
    late int total;
    if (op == '+') {
      total = values.reduce((value, element) => value + element);
    } else {
      total = values[0] * values[1] + values[2];
    }
    final expression = '${values[0]} $op ${values[1]} + ${values[2]}';
    return _Challenge(expression, total);
  }
}
