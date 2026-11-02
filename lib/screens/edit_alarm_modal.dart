import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/alarm_controller.dart';
import '../models/alarm_model.dart';
import '../mind/config/app_palette.dart';
import '../services/alarm_service.dart';

Future<void> showAlarmEditor(BuildContext context, {AlarmModel? alarm}) async {
  final controller = context.read<AlarmController>();
  final draft = await showDialog<_AlarmDraft>(
    context: context,
    builder: (_) => _AlarmEditor(alarm: alarm),
  );
  if (draft == null || !context.mounted) return;
  try {
    if (alarm == null) {
      await controller.addAlarm(
        time: draft.time,
        label: draft.label,
        repeatDaily: draft.daily,
      );
    } else {
      await controller.updateAlarm(
        alarm.copyWith(
          hour: draft.time.hour,
          minute: draft.time.minute,
          label: draft.label,
          repeatDaily: draft.daily,
          clearOverride: true,
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AlarmSchedulingException
                ? error.message
                : 'Unable to schedule this alarm. Please try again.',
          ),
        ),
      );
    }
  }
}

class _AlarmDraft {
  const _AlarmDraft(this.time, this.label, this.daily);
  final TimeOfDay time;
  final String label;
  final bool daily;
}

class _AlarmEditor extends StatefulWidget {
  const _AlarmEditor({this.alarm});
  final AlarmModel? alarm;
  @override
  State<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<_AlarmEditor> {
  late final _label = TextEditingController(
    text: widget.alarm?.label ?? 'Alarm',
  );
  late var _time = widget.alarm?.timeOfDay ?? TimeOfDay.now();
  late var _daily = widget.alarm?.repeatDaily ?? true;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppPalette.card,
    title: Text(widget.alarm == null ? 'New alarm' : 'Edit alarm'),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _time,
            );
            if (picked != null && mounted) {
              setState(() => _time = picked);
            }
          },
          icon: const Icon(Icons.schedule_rounded, color: AppPalette.secondary),
          label: Text(
            _time.format(context),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _label,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Alarm name',
            hintText: 'What is this reminder for?',
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Repeat daily'),
          subtitle: const Text('Turn off for a one-time alarm'),
          value: _daily,
          onChanged: (value) => setState(() => _daily = value),
        ),
        const SizedBox(height: 12),
        const Text(
          'Android must allow alarms and notifications. If prompted, allow FocusJoy to set alarms and reminders.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed:
            () => Navigator.of(context).pop(
              _AlarmDraft(
                _time,
                _label.text.trim().isEmpty ? 'Alarm' : _label.text.trim(),
                _daily,
              ),
            ),
        child: const Text('Save alarm'),
      ),
    ],
  );
}
