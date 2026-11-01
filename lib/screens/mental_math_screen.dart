import 'package:flutter/material.dart';
import '../controllers/mental_math_controller.dart';
import '../mind/config/app_palette.dart';
import '../mind/config/navigation/app_routes_observer.dart';
import '../models/mental_math.dart';

String _duration(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class MentalMathScreen extends StatefulWidget {
  const MentalMathScreen({super.key});

  @override
  State<MentalMathScreen> createState() => _MentalMathScreenState();
}

class _MentalMathScreenState extends State<MentalMathScreen>
    with WidgetsBindingObserver, RouteAware {
  final _game = MentalMathController();
  final _answer = TextEditingController();
  Map<MathOperation, int> _levels = {};
  MathRoundMode _mode = MathRoundMode.timed;
  int _minutes = 2;
  int _count = 10;
  bool _confirmingExit = false;
  MathRoundResult? _review;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      AppRoutesObserver.instance.unsubscribe(this);
      _subscribedRoute = route;
      AppRoutesObserver.instance.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _game.stop(MathFinishReason.backgrounded);
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _game.refreshAllowance();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    await _game.initialize();
    if (!mounted) return;
    setState(() {
      _levels = Map.of(_game.settings.levels);
      _mode = _game.settings.mode;
      _minutes = _game.settings.minutes;
      _count = _game.settings.questionCount;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _game.stop(MathFinishReason.backgrounded);
    } else if (state == AppLifecycleState.resumed) {
      _game.refreshAllowance();
    }
  }

  @override
  void dispose() {
    AppRoutesObserver.instance.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _game.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_game.busy || _confirmingExit) return;
    if (_game.playing) {
      _confirmingExit = true;
      final finish = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('End this round?'),
              content: const Text(
                'Your answers and play time will be saved. You can review the result before leaving.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep playing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('End round'),
                ),
              ],
            ),
      );
      _confirmingExit = false;
      if (finish == true && mounted) await _game.stop();
    } else if (_game.resultSaveError != null) {
      _confirmingExit = true;
      final leave = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Result has not been saved'),
              content: const Text(
                'You can stay and retry saving, or leave without adding this round to your history.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Leave without saving'),
                ),
              ],
            ),
      );
      _confirmingExit = false;
      if (leave == true && mounted) Navigator.of(context).pop();
    } else if (_review != null || _game.result != null) {
      setState(() {
        _review = null;
        _game.result = null;
      });
      _game.refreshAllowance();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit({bool skip = false}) async {
    final input = int.tryParse(_answer.text);
    if (!skip && input == null) return;
    await _game.submit(skip ? null : input);
    if (mounted) _answer.clear();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _game,
    builder: (context, _) {
      final result = _review ?? _game.result;
      return PopScope(
        canPop: !_game.playing && result == null && !_game.busy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            backgroundColor: AppPalette.background,
            leading: BackButton(onPressed: _back),
            title: Text(
              _game.playing
                  ? 'Mental Maths'
                  : result != null
                  ? 'Round result'
                  : 'Mental Maths',
            ),
          ),
          body:
              _game.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _game.error != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_game.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                  : _game.playing
                  ? _play()
                  : result != null
                  ? _results(result)
                  : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [Tab(text: 'Play'), Tab(text: 'History')],
                        ),
                        Expanded(
                          child: TabBarView(children: [_setup(), _history()]),
                        ),
                      ],
                    ),
                  ),
        ),
      );
    },
  );

  Widget _setup() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    children: [
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.calculate_rounded,
              color: AppPalette.secondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'A little practice. A clearer head.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${_duration(_game.dailyRemaining)} left today',
              style: const TextStyle(
                color: AppPalette.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '10 minutes a day across mindful games. Play time is rounded up to seconds. Leaving the app ends the round.',
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Choose your operations',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      const Text(
        'Set a level from 1–9 for each operation. Higher levels use larger numbers; division always has whole-number answers.',
        style: TextStyle(color: Colors.white60, height: 1.5),
      ),
      const SizedBox(height: 12),
      for (final op in MathOperation.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Panel(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${op.symbol}  ${op.label}'),
                  value: _levels.containsKey(op),
                  onChanged:
                      (enabled) => setState(() {
                        if (enabled) {
                          _levels[op] = 1;
                        } else {
                          _levels.remove(op);
                        }
                      }),
                ),
                if (_levels.containsKey(op))
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: 9,
                          divisions: 8,
                          value: _levels[op]!.toDouble(),
                          label: 'Level ${_levels[op]}',
                          onChanged:
                              (value) =>
                                  setState(() => _levels[op] = value.round()),
                        ),
                      ),
                      Text(
                        'L${_levels[op]}',
                        style: const TextStyle(
                          color: AppPalette.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 14),
      const Text(
        'Your round',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      SegmentedButton<MathRoundMode>(
        segments: const [
          ButtonSegment(
            value: MathRoundMode.timed,
            label: Text('Timed'),
            icon: Icon(Icons.timer_outlined),
          ),
          ButtonSegment(
            value: MathRoundMode.practice,
            label: Text('Practice'),
            icon: Icon(Icons.edit_note_rounded),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (value) => setState(() => _mode = value.first),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        children: [
          for (final n
              in _mode == MathRoundMode.timed
                  ? [1, 2, 3, 4, 5]
                  : [10, 20, 30, 40, 50])
            ChoiceChip(
              label: Text(
                _mode == MathRoundMode.timed ? '$n min' : '$n questions',
              ),
              selected: n == (_mode == MathRoundMode.timed ? _minutes : _count),
              onSelected:
                  (_) => setState(() {
                    if (_mode == MathRoundMode.timed) {
                      _minutes = n;
                    } else {
                      _count = n;
                    }
                  }),
            ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Rounds also end when your daily allowance runs out. Scores measure your practice; they do not earn focus gems.',
        style: TextStyle(color: Colors.white60, height: 1.5),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed:
            _levels.isEmpty || _game.dailyRemaining == 0 || _game.busy
                ? null
                : () {
                  _answer.clear();
                  _game.start(
                    MathGameSettings(
                      levels: _levels,
                      mode: _mode,
                      minutes: _minutes,
                      questionCount: _count,
                    ),
                  );
                },
        icon: const Icon(Icons.play_arrow_rounded),
        label: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _game.busy
                ? 'Starting…'
                : _game.dailyRemaining == 0
                ? 'Come back tomorrow'
                : 'Start round',
          ),
        ),
      ),
      if (_levels.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Choose at least one operation.',
            style: TextStyle(color: AppPalette.secondary),
          ),
        ),
    ],
  );

  Widget _play() => SafeArea(
    child: LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(
                          label: 'Time left',
                          value: _duration(_game.secondsLeft),
                        ),
                        _Metric(label: 'Correct', value: '${_game.correct}'),
                        _Metric(
                          label:
                              _game.settings.mode == MathRoundMode.practice
                                  ? 'Progress'
                                  : 'Attempted',
                          value:
                              _game.settings.mode == MathRoundMode.practice
                                  ? '${_game.attempted}/${_game.settings.questionCount}'
                                  : '${_game.attempted}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value:
                          _game.secondsLeft /
                          (_game.settings.mode == MathRoundMode.timed
                              ? _game.settings.minutes * 60
                              : 600),
                      color: AppPalette.secondary,
                      backgroundColor: AppPalette.card,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _game.settings.summary,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      child: Text(
                        '${_game.question!.expression} = ?',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _answer,
                      builder:
                          (context, value, _) => _Panel(
                            child: SizedBox(
                              width: double.infinity,
                              child: Semantics(
                                liveRegion: true,
                                label:
                                    'Your answer: ${value.text.isEmpty ? 'empty' : value.text}',
                                child: Text(
                                  value.text.isEmpty
                                      ? 'Your answer'
                                      : value.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        value.text.isEmpty
                                            ? Colors.white38
                                            : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    for (final row in [
                      ['7', '8', '9'],
                      ['4', '5', '6'],
                      ['1', '2', '3'],
                      ['C', '0', '⌫'],
                    ])
                      Row(
                        children: [
                          for (final key in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Semantics(
                                  label:
                                      key == 'C'
                                          ? 'Clear answer'
                                          : key == '⌫'
                                          ? 'Delete digit'
                                          : key,
                                  button: true,
                                  child: FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 54),
                                      backgroundColor: AppPalette.card,
                                    ),
                                    onPressed:
                                        _game.busy
                                            ? null
                                            : () {
                                              if (key == 'C') {
                                                _answer.clear();
                                              } else if (key == '⌫') {
                                                if (_answer.text.isNotEmpty) {
                                                  _answer.text = _answer.text
                                                      .substring(
                                                        0,
                                                        _answer.text.length - 1,
                                                      );
                                                }
                                              } else if (_answer.text.length <
                                                  8) {
                                                _answer.text += key;
                                              }
                                            },
                                    child: Text(
                                      key,
                                      style: const TextStyle(fontSize: 23),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _game.busy ? null : _submit,
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('Submit answer'),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _game.busy ? null : () => _submit(skip: true),
                      child: const Text('Skip question'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ),
  );

  Widget _history() {
    if (_game.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Your rounds will appear here.\nPlay a short round to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, height: 1.7),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _game.history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final round = _game.history[index];
        final date = MaterialLocalizations.of(
          context,
        ).formatShortDate(round.startedAt);
        final time = MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay.fromDateTime(round.startedAt));
        return Material(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: AppPalette.primaryContainer,
              child: Text(
                '${round.correct}',
                style: const TextStyle(color: AppPalette.primaryLight),
              ),
            ),
            title: Text('$date · $time'),
            subtitle: Text(
              '${round.settings.modeLabel} · ${(round.accuracy * 100).round()}%\n${round.settings.summary}\n${round.finishLabel}',
              style: const TextStyle(color: Colors.white60, height: 1.6),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => setState(() => _review = round),
          ),
        );
      },
    );
  }

  Widget _results(MathRoundResult round) {
    final comparisons = _game.history.where(
      (r) =>
          r.completed &&
          r.settings.comparisonKey == round.settings.comparisonKey,
    );
    final best = comparisons.fold<int>(
      0,
      (best, r) => r.correct > best ? r.correct : best,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _Panel(
          child: Column(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 40,
                color: AppPalette.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                round.finishLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${round.settings.modeLabel}\n${round.settings.summary}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.6),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 28,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: [
                  _Metric(
                    label: 'Correct',
                    value: '${round.correct}/${round.attempts.length}',
                  ),
                  _Metric(
                    label: 'Accuracy',
                    value: '${(round.accuracy * 100).round()}%',
                  ),
                  _Metric(
                    label: 'Correct / min',
                    value: round.correctPerMinute.toStringAsFixed(1),
                  ),
                  _Metric(
                    label: 'Time played',
                    value: _duration((round.elapsedMilliseconds / 1000).ceil()),
                  ),
                  _Metric(label: 'Wrong', value: '${round.wrong}'),
                  _Metric(label: 'Skipped', value: '${round.skipped}'),
                ],
              ),
              if (best > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Best completed round with these settings: $best correct',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppPalette.primaryLight),
                  ),
                ),
            ],
          ),
        ),
        if (_game.savingResult)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (_game.resultSaveError != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _Panel(
              child: Column(
                children: [
                  Text(
                    _game.resultSaveError!,
                    style: const TextStyle(color: AppPalette.secondary),
                  ),
                  TextButton(
                    onPressed: _game.savingResult ? null : _game.saveResult,
                    child: const Text('Retry saving'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _game.busy ? null : _back,
          child: const Text('Back to Mental Maths'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Review your answers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (round.attempts.isEmpty)
          const Text(
            'No answers submitted in this round.',
            style: TextStyle(color: Colors.white60),
          ),
        for (final (index, attempt) in round.attempts.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Panel(
              child: Row(
                children: [
                  Icon(
                    attempt.correct
                        ? Icons.check_circle_outline
                        : attempt.skipped
                        ? Icons.skip_next_rounded
                        : Icons.cancel_outlined,
                    color:
                        attempt.correct
                            ? AppPalette.primaryLight
                            : AppPalette.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${attempt.question.expression} = ${attempt.question.answer}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${attempt.skipped ? 'Skipped' : 'Your answer: ${attempt.givenAnswer}'} · ${(attempt.milliseconds / 1000).toStringAsFixed(1)}s',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ],
  );
}
