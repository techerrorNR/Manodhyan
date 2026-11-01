import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mind/ui/controllers/planner_navigation_provider.dart';
import 'todo_screen.dart';

/// Compatibility entry for older alarm links; uses the same merged planner UI.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});
  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(plannerSectionProvider.notifier).state = PlannerSection.alarms;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Planner')),
    body: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: TodoScreen(),
    ),
  );
}
