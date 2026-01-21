import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/alarm_controller.dart';
import '../models/alarm_model.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Future<void> _showCreateAlarmDialog() async {
    final labelController = TextEditingController(text: 'Alarm');
    TimeOfDay selectedTime = TimeOfDay.now();
    bool repeatDaily = true;

    final result = await showDialog<_AlarmFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1B192F),
              scrollable: true,
              title: const Text(
                'Set Alarm',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (ctx, child) {
                            return Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.deepPurple,
                                  surface: Color(0xFF1B192F),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => selectedTime = picked);
                        }
                      },
                      icon: const Icon(Icons.alarm, color: Colors.deepPurpleAccent),
                      label: Text(
                        'Time: ${selectedTime.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurpleAccent),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Repeat daily',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: repeatDaily,
                      onChanged: (value) => setState(() => repeatDaily = value),
                      activeColor: Colors.deepPurpleAccent,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _AlarmFormResult(
                        time: selectedTime,
                        label: labelController.text.trim().isEmpty
                            ? 'Alarm'
                            : labelController.text.trim(),
                        repeatDaily: repeatDaily,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();

    if (result == null || !mounted) return;

    await context.read<AlarmController>().addAlarm(
          time: result.time,
          label: result.label,
          repeatDaily: result.repeatDaily,
        );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AlarmController>();
    final alarms = controller.alarms;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D21),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Alarm Schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create alarms just like on your phone. These reminders accompany the meditation flow.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _showCreateAlarmDialog,
                      icon: const Icon(Icons.add_alarm, color: Colors.white),
                      label: const Text(
                        'Set Alarm',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (alarms.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No alarms yet.\nTap "Set Alarm" to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alarm = alarms[index];
                      return _AlarmTile(
                        alarm: alarm,
                        onToggle: (enabled) => context
                            .read<AlarmController>()
                            .toggleAlarm(alarm.id, enabled),
                        onDelete: () => context
                            .read<AlarmController>()
                            .deleteAlarm(alarm.id),
                      );
                    },
                    childCount: alarms.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final Future<void> Function() onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete alarm?'),
        content: Text(
          'Remove "${alarm.label}" set for ${alarm.formattedTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm "${alarm.label}" deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1B192F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.label,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.repeatDaily ? 'Repeats daily' : 'One-time alarm',
                    style: TextStyle(
                      color:
                          alarm.repeatDaily ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: alarm.isEnabled,
                  onChanged: onToggle,
                  activeColor: Colors.deepPurpleAccent,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Delete alarm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmFormResult {
  const _AlarmFormResult({
    required this.time,
    required this.label,
    required this.repeatDaily,
  });

  final TimeOfDay time;
  final String label;
  final bool repeatDaily;
}
