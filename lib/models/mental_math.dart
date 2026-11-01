import 'dart:math';

enum MathOperation {
  addition('+', 'Addition'),
  subtraction('−', 'Subtraction'),
  multiplication('×', 'Multiplication'),
  division('÷', 'Division');

  const MathOperation(this.symbol, this.label);
  final String symbol;
  final String label;
}

enum MathRoundMode { timed, practice }

enum MathFinishReason {
  timer,
  questionTarget,
  dailyLimit,
  stopped,
  backgrounded,
  newDay,
  storageError,
}

class MathGameSettings {
  MathGameSettings({
    Map<MathOperation, int>? levels,
    this.mode = MathRoundMode.timed,
    this.minutes = 2,
    this.questionCount = 10,
  }) : levels = Map.unmodifiable(
         levels ?? {MathOperation.addition: 1, MathOperation.subtraction: 1},
       ) {
    if (this.levels.isEmpty ||
        this.levels.values.any((l) => l < 1 || l > 9) ||
        minutes < 1 ||
        minutes > 5 ||
        ![10, 20, 30, 40, 50].contains(questionCount)) {
      throw ArgumentError('Invalid maths settings');
    }
  }

  final Map<MathOperation, int> levels;
  final MathRoundMode mode;
  final int minutes;
  final int questionCount;

  String get summary =>
      levels.entries.map((e) => '${e.key.symbol} L${e.value}').join(' · ');
  String get modeLabel =>
      mode == MathRoundMode.timed
          ? '$minutes min timed'
          : '$questionCount questions';
  String get comparisonKey =>
      '${mode.name}:${mode == MathRoundMode.timed ? minutes : questionCount}:'
      '${MathOperation.values.where(levels.containsKey).map((op) => '${op.name}:${levels[op]}').join(',')}';

  Map<String, dynamic> toMap() => {
    'levels': {for (final e in levels.entries) e.key.name: e.value},
    'mode': mode.name,
    'minutes': minutes,
    'questionCount': questionCount,
  };

  factory MathGameSettings.fromMap(Map<String, dynamic> map) =>
      MathGameSettings(
        levels: (map['levels'] as Map).map(
          (key, value) => MapEntry(
            MathOperation.values.byName(key as String),
            value as int,
          ),
        ),
        mode: MathRoundMode.values.byName(map['mode'] as String),
        minutes: map['minutes'] as int,
        questionCount: map['questionCount'] as int,
      );
}

class MathQuestion {
  const MathQuestion(this.left, this.right, this.operation);
  final int left;
  final int right;
  final MathOperation operation;
  String get expression => '$left ${operation.symbol} $right';
  int get answer => switch (operation) {
    MathOperation.addition => left + right,
    MathOperation.subtraction => left - right,
    MathOperation.multiplication => left * right,
    MathOperation.division => left ~/ right,
  };

  Map<String, dynamic> toMap() => {
    'left': left,
    'right': right,
    'operation': operation.name,
  };
  factory MathQuestion.fromMap(Map<String, dynamic> map) {
    final question = MathQuestion(
      map['left'] as int,
      map['right'] as int,
      MathOperation.values.byName(map['operation'] as String),
    );
    if (question.left < 0 ||
        question.right < 0 ||
        (question.operation == MathOperation.division &&
            (question.right == 0 || question.left % question.right != 0))) {
      throw const FormatException('Invalid maths question');
    }
    return question;
  }
}

class MathQuestionGenerator {
  MathQuestionGenerator([Random? random]) : _random = random ?? Random();
  final Random _random;
  static const _maxima = [10, 20, 50, 100, 250, 500, 1000, 5000, 10000];
  static const _factors = [5, 10, 12, 20, 25, 50, 100, 150, 250];

  MathQuestion next(MathGameSettings settings) {
    final ops = settings.levels.keys.toList();
    final op = ops[_random.nextInt(ops.length)];
    final level = settings.levels[op]! - 1;
    final maxOperand = _maxima[level];
    final factor = _factors[level];
    final a = 1 + _random.nextInt(maxOperand);
    final b = 1 + _random.nextInt(maxOperand);
    return switch (op) {
      MathOperation.addition => MathQuestion(a, b, op),
      MathOperation.subtraction => MathQuestion(max(a, b), min(a, b), op),
      MathOperation.multiplication => MathQuestion(
        2 + _random.nextInt(factor - 1),
        2 + _random.nextInt(factor - 1),
        op,
      ),
      MathOperation.division => _division(factor),
    };
  }

  MathQuestion _division(int maximum) {
    final divisor = 2 + _random.nextInt(maximum - 1);
    final quotient = 1 + _random.nextInt(maximum);
    return MathQuestion(divisor * quotient, divisor, MathOperation.division);
  }
}

class MathAttempt {
  const MathAttempt({
    required this.question,
    required this.givenAnswer,
    required this.milliseconds,
  });
  final MathQuestion question;
  final int? givenAnswer;
  final int milliseconds;
  bool get skipped => givenAnswer == null;
  bool get correct => givenAnswer == question.answer;
  Map<String, dynamic> toMap() => {
    'question': question.toMap(),
    'answer': givenAnswer,
    'ms': milliseconds,
  };
  factory MathAttempt.fromMap(Map<String, dynamic> map) => MathAttempt(
    question: MathQuestion.fromMap(
      Map<String, dynamic>.from(map['question'] as Map),
    ),
    givenAnswer: map['answer'] as int?,
    milliseconds: map['ms'] as int,
  );
}

class MathRoundResult {
  MathRoundResult({
    required this.id,
    required this.startedAt,
    required this.settings,
    required this.elapsedMilliseconds,
    required this.reason,
    required List<MathAttempt> attempts,
  }) : attempts = List.unmodifiable(attempts);
  final String id;
  final DateTime startedAt;
  final MathGameSettings settings;
  final int elapsedMilliseconds;
  final MathFinishReason reason;
  final List<MathAttempt> attempts;
  int get correct => attempts.where((a) => a.correct).length;
  int get skipped => attempts.where((a) => a.skipped).length;
  int get wrong => attempts.length - correct - skipped;
  double get accuracy => attempts.isEmpty ? 0 : correct / attempts.length;
  double get correctPerMinute =>
      elapsedMilliseconds <= 0 ? 0 : correct * 60000 / elapsedMilliseconds;
  bool get completed =>
      reason == MathFinishReason.timer ||
      reason == MathFinishReason.questionTarget;
  String get finishLabel => switch (reason) {
    MathFinishReason.timer => 'Time is up',
    MathFinishReason.questionTarget => 'Practice complete',
    MathFinishReason.dailyLimit => 'Daily allowance reached',
    MathFinishReason.stopped => 'Ended early',
    MathFinishReason.backgrounded => 'Round interrupted',
    MathFinishReason.newDay => 'A new day has started',
    MathFinishReason.storageError => 'Paused after a saving issue',
  };
  Map<String, dynamic> toMap() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'settings': settings.toMap(),
    'elapsedMs': elapsedMilliseconds,
    'reason': reason.name,
    'attempts': attempts.map((a) => a.toMap()).toList(),
  };
  factory MathRoundResult.fromMap(Map<String, dynamic> map) => MathRoundResult(
    id: map['id'] as String,
    startedAt: DateTime.parse(map['startedAt'] as String),
    settings: MathGameSettings.fromMap(
      Map<String, dynamic>.from(map['settings'] as Map),
    ),
    elapsedMilliseconds: map['elapsedMs'] as int,
    reason: MathFinishReason.values.byName(map['reason'] as String),
    attempts:
        (map['attempts'] as List)
            .map(
              (a) => MathAttempt.fromMap(Map<String, dynamic>.from(a as Map)),
            )
            .toList(),
  );
}
