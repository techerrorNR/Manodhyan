import 'package:flutter/material.dart';

/// Plain data object that represents a scheduled alarm.
class AlarmModel {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool repeatDaily;
  final bool isEnabled;
  final DateTime? overrideTime;

  const AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeatDaily,
    required this.isEnabled,
    this.overrideTime,
  });

  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? repeatDaily,
    bool? isEnabled,
    DateTime? overrideTime,
    bool clearOverride = false,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      isEnabled: isEnabled ?? this.isEnabled,
      overrideTime:
          clearOverride ? null : overrideTime ?? this.overrideTime,
    );
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  /// Calculates the next DateTime this alarm should ring.
  DateTime? nextTrigger(DateTime reference) {
    if (!isEnabled) return null;
    if (overrideTime != null) {
      if (!overrideTime!.isAfter(reference)) {
        return reference.add(const Duration(seconds: 1));
      }
      return overrideTime;
    }
    DateTime scheduled = DateTime(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(reference)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'repeatDaily': repeatDaily,
      'isEnabled': isEnabled,
      'overrideTime': overrideTime?.toIso8601String(),
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      label: map['label'] as String? ?? 'Alarm',
      repeatDaily: map['repeatDaily'] as bool? ?? true,
      isEnabled: map['isEnabled'] as bool? ?? true,
      overrideTime: map['overrideTime'] != null
          ? DateTime.tryParse(map['overrideTime'] as String)
          : null,
    );
  }

  static String formatTwoDigits(int value) => value.toString().padLeft(2, '0');

  String get formattedTime {
    final hourLabel = formatTwoDigits(hour);
    final minuteLabel = formatTwoDigits(minute);
    return '$hourLabel:$minuteLabel';
  }
}
