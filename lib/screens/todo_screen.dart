import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show WatchContext;
import '../controllers/task_controller.dart';
import '../controllers/alarm_controller.dart';
import '../controllers/notes_controller.dart';
import '../models/task_model.dart';
import '../models/alarm_model.dart';
import '../models/note_model.dart';
import '../mind/config/app_palette.dart';
import '../services/alarm_service.dart';
import '../mind/ui/controllers/planner_navigation_provider.dart';
import 'create_task_modal.dart';
import 'edit_alarm_modal.dart';
import 'note_editor.dart';

/// One planning page inside the main shell; it owns no second bottom bar or FAB.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AlarmSchedulingException
                  ? error.message
                  : 'Unable to save this change. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(String title, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete $title?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppPalette.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) await _run(action);
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final alarmController = context.watch<AlarmController>();
    final noteController = context.watch<NotesController>();
    final section = ref.watch(plannerSectionProvider);
    final tasks = taskController.todaysTasks;
    final completed = tasks.where((task) => task.isCompleted).length;
    final alarms = [...alarmController.alarms]..sort((a, b) {
      if (a.isEnabled != b.isEnabled) return a.isEnabled ? -1 : 1;
      return (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
    });
    final notes =
        noteController.notes
            .where(
              (note) => '${note.title} ${note.body}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
            )
            .toList();
    final now = DateTime.now();
    final upcoming =
        alarms
            .map((alarm) => alarm.nextTrigger(now))
            .whereType<DateTime>()
            .toList()
          ..sort();

    void add() {
      switch (section) {
        case PlannerSection.tasks:
          showCreateTaskModal(context);
        case PlannerSection.alarms:
          showAlarmEditor(context);
        case PlannerSection.notes:
          showNoteEditor(context);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await taskController.refresh();
        await noteController.reload();
      },
      child: ListView(
        key: PageStorageKey('planner-${section.name}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.primaryContainer, AppPalette.card],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppPalette.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        MaterialLocalizations.of(context).formatMediumDate(now),
                        style: const TextStyle(color: AppPalette.primaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'A little structure. A clearer mind.',
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your tasks, reminders, and ideas ? together.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _Summary(
                      value: '${tasks.length - completed}',
                      label: 'Tasks left',
                    ),
                    _Summary(
                      value:
                          '${alarms.where((alarm) => alarm.isEnabled).length}',
                      label: 'Enabled alarms',
                    ),
                    _Summary(
                      value:
                          noteController.isLoading
                              ? '?'
                              : noteController.loadError != null
                              ? '?'
                              : '${noteController.notes.length}',
                      label: 'Saved notes',
                    ),
                  ],
                ),
                if (upcoming.isNotEmpty &&
                    alarmController.schedulingError == null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Next alarm: ${_alarmDate(context, upcoming.first)}',
                    style: const TextStyle(
                      color: AppPalette.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PlannerSection>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(
                  value: PlannerSection.tasks,
                  icon: Icon(Icons.checklist_rounded, size: 18),
                  label: Text('Tasks'),
                ),
                ButtonSegment(
                  value: PlannerSection.alarms,
                  icon: Icon(Icons.alarm_rounded, size: 18),
                  label: Text('Alarms'),
                ),
                ButtonSegment(
                  value: PlannerSection.notes,
                  icon: Icon(Icons.edit_note_rounded, size: 18),
                  label: Text('Notes'),
                ),
              ],
              selected: {section},
              onSelectionChanged:
                  (selection) =>
                      ref.read(plannerSectionProvider.notifier).state =
                          selection.single,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  switch (section) {
                    PlannerSection.tasks => 'Today?s tasks',
                    PlannerSection.alarms => 'Your alarms',
                    PlannerSection.notes => 'Your notes',
                  },
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed:
                    section == PlannerSection.notes &&
                            (noteController.isLoading ||
                                noteController.loadError != null)
                        ? null
                        : add,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(switch (section) {
                  PlannerSection.tasks => 'Task',
                  PlannerSection.alarms => 'Alarm',
                  PlannerSection.notes => 'Note',
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (section == PlannerSection.tasks) ...[
            _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$completed of ${tasks.length} completed',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${taskController.streak} day streak',
                        style: const TextStyle(
                          color: AppPalette.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : completed / tasks.length,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: AppPalette.background,
                    color: AppPalette.primary,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Today: ${taskController.todaysPoints.toStringAsFixed(1)} task points',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Total: ${taskController.totalPoints.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              _Empty(
                icon: Icons.checklist_rounded,
                title: 'Make space for what matters',
                description: 'Add your first task for today.',
                action: 'Add task',
                onTap: add,
              ),
            for (final task in tasks)
              _TaskCard(
                task: task,
                onToggle:
                    (value) =>
                        _run(() => taskController.toggleTask(task.id, value)),
                onDelete:
                    () => _delete(
                      'task',
                      () => taskController.deleteTask(task.id),
                    ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Your last 7 days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _Surface(
              child: Row(
                children: List.generate(7, (index) {
                  final day = DateTime(
                    now.year,
                    now.month,
                    now.day - (6 - index),
                  );
                  final daily = taskController.tasksForDate(day);
                  final done = daily.where((task) => task.isCompleted).length;
                  final color =
                      daily.isEmpty
                          ? Colors.white24
                          : done == daily.length
                          ? AppPalette.primaryLight
                          : AppPalette.secondary;
                  return Expanded(
                    child: Semantics(
                      label:
                          '${day.day}/${day.month}: $done of ${daily.length} tasks completed',
                      child: Column(
                        children: [
                          Text(
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday -
                                1],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color:
                                  index == 6
                                      ? AppPalette.primary
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            daily.isNotEmpty && done == daily.length
                                ? Icons.check_circle_rounded
                                : Icons.circle,
                            color: color,
                            size: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
          if (section == PlannerSection.alarms) ...[
            if (alarmController.schedulingError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppPalette.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alarms need your attention',
                        style: TextStyle(
                          color: AppPalette.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alarmController.schedulingError!,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed:
                            () => _run(
                              () => alarmController.refreshScheduling(
                                requestPermissions: true,
                              ),
                            ),
                        icon: const Icon(Icons.alarm_on_rounded),
                        label: const Text('Allow & retry alarms'),
                      ),
                    ],
                  ),
                ),
              ),
            if (alarms.isEmpty)
              _Empty(
                icon: Icons.alarm_add_rounded,
                title: 'Never miss your next step',
                description: 'Set a one-time reminder or a daily alarm.',
                action: 'Set alarm',
                onTap: add,
              ),
            for (final alarm in alarms)
              _AlarmCard(
                alarm: alarm,
                onEdit: () => showAlarmEditor(context, alarm: alarm),
                onToggle:
                    (value) => _run(
                      () => alarmController.toggleAlarm(alarm.id, value),
                    ),
                onDelete:
                    () => _delete(
                      'alarm',
                      () => alarmController.deleteAlarm(alarm.id),
                    ),
              ),
          ],
          if (section == PlannerSection.notes) ...[
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search your notes',
                prefixIcon: Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppPalette.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (noteController.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (noteController.loadError != null)
              _Empty(
                icon: Icons.error_outline_rounded,
                title: 'Your notes could not be loaded',
                description:
                    'Your saved notes have not been changed. Try loading them again.',
                action: 'Retry',
                onTap: noteController.reload,
              )
            else if (notes.isEmpty)
              _Empty(
                icon: Icons.edit_note_rounded,
                title:
                    _query.isEmpty
                        ? 'An idea worth keeping?'
                        : 'No matching notes',
                description:
                    _query.isEmpty
                        ? 'Capture thoughts, plans, and reflections here.'
                        : 'Try another title or word.',
                action: 'New note',
                onTap: add,
              ),
            for (final note in notes)
              _NoteCard(
                note: note,
                onEdit: () => showNoteEditor(context, note: note),
                onDelete:
                    () => _delete(
                      'note',
                      () => noteController.deleteNote(note.id),
                    ),
              ),
          ],
        ],
      ),
    );
  }
}

String _alarmDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final day = DateTime(date.year, date.month, date.day);
  final label =
      day == today
          ? 'Today'
          : day == tomorrow
          ? 'Tomorrow'
          : MaterialLocalizations.of(context).formatShortDate(date);
  return '$label, ${TimeOfDay.fromDateTime(date).format(context)}';
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });
  final TaskModel task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _Surface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) => onToggle(value ?? false),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted ? Colors.white54 : Colors.white,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete task',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final AlarmModel alarm;
  final VoidCallback onEdit, onDelete;
  final ValueChanged<bool> onToggle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _Surface(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.timeOfDay.format(context),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color:
                              alarm.isEnabled ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alarm.label,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(value: alarm.isEnabled, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  alarm.repeatDaily ? 'Repeats daily' : 'One-time alarm',
                  style: const TextStyle(
                    color: AppPalette.secondary,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit alarm',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: Colors.white54,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete alarm',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });
  final NoteModel note;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 20,
                    color: AppPalette.primaryLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete note',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Edited ${MaterialLocalizations.of(context).formatShortDate(note.updatedAt)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title, description, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: AppPalette.primaryLight, size: 38),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    ),
  );
}
