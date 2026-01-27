import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:manodhyan/mind/ui/common/scaffold_shell.dart';
import 'package:manodhyan/mind/ui/screens/home/dashboard/tab_dashboard.dart';
import 'package:manodhyan/mind/ui/screens/home/notifications/tab_notifications.dart';
import 'package:manodhyan/screens/challenge_screen.dart';
import 'package:manodhyan/screens/home_screen.dart' as mano_home;
import 'package:manodhyan/screens/todo_screen.dart';
import 'package:manodhyan/screens/create_task_modal.dart';

class UniversalHomeScreen extends StatelessWidget {
  const UniversalHomeScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  Widget build(BuildContext context) {
    return ScaffoldShell(
      initialTab: initialTab,
      appBarExpandedHeight: 120, // Reduced height as some screens have their own headers
      items: [
        // 1. Focus (Manodhyan Timer)
        NavbarItem(
          titleText: "Focus",
          icon: LucideIcons.target,
          filledIcon: LucideIcons.target,
          sliverBody: const mano_home.HomeScreen(),
        ),

        // 2. Tasks (Manodhyan Todo)
        NavbarItem(
          titleText: "Tasks",
          icon: LucideIcons.listTodo,
          filledIcon: LucideIcons.listTodo,
          sliverBody: const TodoScreen(),
          fab: FloatingActionButton(
            backgroundColor: Colors.deepPurpleAccent,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => showCreateTaskModal(context),
          ),
        ),

        // 3. Dashboard (Mindful Glance)
        NavbarItem(
          titleText: "Dashboard",
          icon: FluentIcons.home_20_regular,
          filledIcon: FluentIcons.home_20_filled,
          sliverBody: const TabDashboard(),
        ),

        // 4. Activity (Manodhyan Insights)
        NavbarItem(
          titleText: "Activity",
          icon: LucideIcons.diamond,
          filledIcon: LucideIcons.diamond,
          sliverBody: const ChallengeScreen(),
        ),

        // 5. Tools / Notifications
        NavbarItem(
          titleText: "Tools",
          icon: FluentIcons.alert_urgent_20_regular,
          filledIcon: FluentIcons.alert_urgent_20_filled,
          sliverBody: const TabNotifications(),
        ),
      ],
    );
  }
}
