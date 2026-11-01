import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/ui/controllers/home_tab_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:focusjoy/mind/ui/common/scaffold_shell.dart';
import 'package:focusjoy/mind/ui/screens/home/dashboard/tab_dashboard.dart';
import 'package:focusjoy/mind/ui/screens/home/tools/tab_tools.dart';
import 'package:focusjoy/screens/challenge_screen.dart';
import 'package:focusjoy/mind/config/navigation/app_routes.dart';
import 'package:focusjoy/screens/home_screen.dart' as crystal_home;
import 'package:focusjoy/screens/todo_screen.dart';

class UniversalHomeScreen extends ConsumerWidget {
  const UniversalHomeScreen({super.key, this.initialTab});

  static const dashboardTab = 0;
  static const tasksTab = 1;
  static const focusTab = 2;

  final int? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(homeTabProvider);
    return ScaffoldShell(
      initialTab: initialTab ?? selectedTab,
      onTabChanged: (index) {
        if (ref.read(homeTabProvider) != index) {
          ref.read(homeTabProvider.notifier).state = index;
        }
      },
      canGoBack: false,
      usePillNavigation: true,
      appBarExpandedHeight:
          120, // Reduced height as some screens have their own headers
      items: [
        NavbarItem(
          titleText: "Dashboard",
          icon: FluentIcons.home_20_regular,
          filledIcon: FluentIcons.home_20_filled,
          sliverBody: const TabDashboard(),
        ),
        NavbarItem(
          titleText: "Planner",
          icon: LucideIcons.listTodo,
          filledIcon: LucideIcons.listTodo,
          sliverBody: const TodoScreen(),
        ),
        // Use the same focus profiles, blocking service, and session as Focus Mode.
        NavbarItem(
          titleText: "Focus",
          icon: LucideIcons.target,
          filledIcon: LucideIcons.target,
          sliverBody: const crystal_home.HomeScreen(),
          actions: [
            IconButton(
              tooltip: 'Focus timeline',
              icon: const Icon(Icons.history),
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.focusModePath, arguments: {'tab': '1'}),
            ),
          ],
        ),

        // 4. Activity (Manodhyan Insights)
        NavbarItem(
          titleText: "Activity",
          icon: LucideIcons.diamond,
          filledIcon: LucideIcons.diamond,
          sliverBody: const ChallengeScreen(),
        ),

        // 5. All device controls and restriction settings.
        NavbarItem(
          titleText: "Tools",
          icon: Icons.tune_outlined,
          filledIcon: Icons.tune_rounded,
          sliverBody: const TabTools(),
        ),
      ],
    );
  }
}
