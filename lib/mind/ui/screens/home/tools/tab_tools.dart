import 'package:focusjoy/mind/config/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:focusjoy/mind/config/navigation/app_routes.dart';
import 'package:focusjoy/routes.dart' as root_routes;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/ui/controllers/planner_navigation_provider.dart';
import 'package:focusjoy/widgets/floating_focus_settings.dart';

class TabTools extends ConsumerWidget {
  const TabTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 120),
          sliver: SliverList.list(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.primaryContainer, AppPalette.card],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppPalette.primaryLight,
                      size: 32,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your space. Your rules.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage distractions and make your phone work for you.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
              const _SectionTitle('Distraction controls'),
              _ToolTile(
                icon: Icons.apps_rounded,
                color: AppPalette.primaryLight,
                title: 'App blocking',
                subtitle: 'Choose distracting apps and focus rules',
                route: AppRoutes.focusModePath,
              ),
              _ToolTile(
                icon: Icons.folder_copy_outlined,
                color: AppPalette.primaryLight,
                title: 'Restriction groups',
                subtitle: 'Shared limits for groups of apps',
                route: AppRoutes.restrictionGroupsPath,
              ),
              _ToolTile(
                icon: Icons.slow_motion_video_rounded,
                color: AppPalette.secondary,
                title: 'Shorts blocking',
                subtitle: 'Set limits on short-form content',
                route: AppRoutes.shortsBlockingPath,
              ),
              _ToolTile(
                icon: Icons.language_rounded,
                color: AppPalette.primaryLight,
                title: 'Website blocking',
                subtitle: 'Manage blocked websites and content',
                route: AppRoutes.websitesBlockingPath,
              ),
              _ToolTile(
                icon: Icons.family_restroom_rounded,
                color: AppPalette.highlight,
                title: 'Parental controls',
                subtitle: 'Protection and enforced restrictions',
                route: AppRoutes.parentalControlsPath,
              ),
              const _SectionTitle('Routines & notifications'),
              _ToolTile(
                icon: Icons.bedtime_outlined,
                color: AppPalette.primaryLight,
                title: 'Bedtime routine',
                subtitle: 'Schedule downtime and quiet hours',
                route: AppRoutes.bedtimePath,
              ),
              _ToolTile(
                icon: Icons.notifications_none_rounded,
                color: AppPalette.primaryLight,
                title: 'Notification controls',
                subtitle: 'Batch apps, schedules, and notification history',
                route: AppRoutes.notificationControlsPath,
              ),
              _ToolTile(
                icon: Icons.alarm_rounded,
                color: AppPalette.secondary,
                title: 'Planner & alarms',
                subtitle: 'Tasks, reminders, and saved notes in one place',
                onTap: () => openPlanner(ref, section: PlannerSection.alarms),
              ),
              const _SectionTitle('Mindful games'),
              _ToolTile(
                icon: Icons.calculate_rounded,
                color: AppPalette.secondary,
                title: 'Mental Maths',
                subtitle:
                    'Choose levels, practise, and review results · 10 min/day',
                route: AppRoutes.mentalMathsPath,
              ),
              const _SectionTitle('App preferences'),
              const FloatingFocusSettings(),
              const SizedBox(height: 12),
              _ToolTile(
                icon: Icons.shield_outlined,
                color: AppPalette.primaryLight,
                title: 'Device permissions',
                subtitle: 'Usage access, overlay, alarms, and notifications',
                route: root_routes.AppRoutes.ManoDhyanPermissions,
              ),
              _ToolTile(
                icon: Icons.settings_outlined,
                color: AppPalette.primaryLight,
                title: 'Settings',
                subtitle: 'Appearance, wellbeing, and app preferences',
                route: AppRoutes.settingsPath,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.route,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white38,
        ),
        onTap: onTap ?? () => Navigator.of(context).pushNamed(route!),
      ),
    ),
  );
}
