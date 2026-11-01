import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/services/alarm_service.dart';
import 'home_tab_provider.dart';

enum PlannerSection { tasks, alarms, notes }

final plannerSectionProvider = StateProvider<PlannerSection>(
  (ref) => PlannerSection.tasks,
);

void openPlanner(
  WidgetRef ref, {
  PlannerSection section = PlannerSection.tasks,
}) {
  ref.read(plannerSectionProvider.notifier).state = section;
  ref.read(homeTabProvider.notifier).state = 1;
  AlarmService.instance.navigatorKey.currentState?.popUntil(
    (route) => route.isFirst,
  );
}
