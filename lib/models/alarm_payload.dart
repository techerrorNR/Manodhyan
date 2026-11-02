import 'dart:convert';

class AlarmPayload {
  final String alarmId;
  final String? taskId;
  final int durationSeconds;
  final int crystalTarget;
  final String? crystalType;
  final List<String> allowedApps;
  final DateTime fireAt;
  final bool isAlarmClock;
  final int? notificationId;

  const AlarmPayload({
    required this.alarmId,
    required this.durationSeconds,
    required this.fireAt,
    this.taskId,
    this.crystalTarget = 0,
    this.crystalType,
    this.allowedApps = const [],
    this.isAlarmClock = false,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'alarmId': alarmId,
      'taskId': taskId,
      'durationSeconds': durationSeconds,
      'crystalTarget': crystalTarget,
      'crystalType': crystalType,
      'allowedApps': allowedApps,
      'fireAt': fireAt.toIso8601String(),
      'isAlarmClock': isAlarmClock,
      'notificationId': notificationId,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory AlarmPayload.fromMap(Map<String, dynamic> map) {
    return AlarmPayload(
      alarmId: map['alarmId'] as String,
      taskId: map['taskId'] as String?,
      isAlarmClock: map['isAlarmClock'] as bool? ?? false,
      notificationId: map['notificationId'] as int?,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      crystalTarget: map['crystalTarget'] as int? ?? 0,
      crystalType: map['crystalType'] as String?,
      allowedApps:
          (map['allowedApps'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
      fireAt:
          map['fireAt'] != null
              ? DateTime.tryParse(map['fireAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  factory AlarmPayload.fromJson(String source) =>
      AlarmPayload.fromMap(jsonDecode(source) as Map<String, dynamic>);

  AlarmPayload copyWith({
    DateTime? fireAt,
    int? durationSeconds,
    bool? isAlarmClock,
    int? notificationId,
  }) => AlarmPayload(
    alarmId: alarmId,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    fireAt: fireAt ?? this.fireAt,
    taskId: taskId,
    crystalTarget: crystalTarget,
    crystalType: crystalType,
    allowedApps: allowedApps,
    isAlarmClock: isAlarmClock ?? this.isAlarmClock,
    notificationId: notificationId ?? this.notificationId,
  );
}
