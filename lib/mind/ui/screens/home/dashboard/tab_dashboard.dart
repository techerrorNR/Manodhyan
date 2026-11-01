import 'package:focusjoy/mind/config/app_palette.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show WatchContext;
import 'package:focusjoy/controllers/task_controller.dart';
import 'package:focusjoy/controllers/timer_controller.dart';
import 'package:focusjoy/models/focus_reward.dart';
import 'package:focusjoy/mind/config/navigation/app_routes.dart';
import 'package:focusjoy/mind/core/database/app_database.dart';
import 'package:focusjoy/mind/core/services/drift_db_service.dart';
import 'package:focusjoy/mind/models/app_info.dart';
import 'package:focusjoy/mind/providers/focus/focus_mode_provider.dart';
import 'package:focusjoy/mind/providers/focus/focus_session_gems_provider.dart';
import 'package:focusjoy/mind/providers/system/manodhyan_settings_provider.dart';
import 'package:focusjoy/mind/providers/system/permissions_provider.dart';
import 'package:focusjoy/mind/providers/usage/todays_apps_usage_provider.dart';
import 'package:focusjoy/mind/ui/common/application_icon.dart';
import 'package:focusjoy/mind/ui/controllers/tab_controller_provider.dart';
import 'package:focusjoy/services/app_name_resolver.dart';
import 'dashboard_update_notes.dart';

final _dashboardSessionsProvider = StreamProvider<List<FocusSession>>(
  (ref) =>
      DriftDbService.instance.driftDb.dynamicRecordsDao
          .watchSuccessfulFocusSessions(),
);

class TabDashboard extends ConsumerWidget {
  const TabDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusModeProvider);
    final rewards = ref.watch(focusRewardsProvider);
    final history = ref.watch(_dashboardSessionsProvider);
    final usage = ref.watch(todaysAppsUsageProvider);
    final permissions = ref.watch(permissionProvider);
    final tasks = context.watch<TaskController>().todaysTasks;
    final legacyGems = context.watch<TimerController>().crystals;
    final username = ref.watch(ManoDhyanSettingsProvider).username.trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dailySeconds = List<int>.filled(7, 0);
    var todaysSessions = 0;
    for (final session in history.valueOrNull ?? <FocusSession>[]) {
      final date = session.startDateTime;
      final day = DateTime(date.year, date.month, date.day);
      // Compare calendar days in UTC so local daylight-saving changes cannot
      // shift a session into the wrong daily column.
      final daysAgo =
          DateTime.utc(
            today.year,
            today.month,
            today.day,
          ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        dailySeconds[6 - daysAgo] += session.durationSecs;
      }
      if (daysAgo == 0) todaysSessions++;
    }
    final screenSeconds =
        usage.valueOrNull?.values.fold<int>(
          0,
          (total, entry) => total + entry.screenTime,
        ) ??
        0;
    final sessionActive = focus.activeSession.valueOrNull != null;
    final expected = FocusReward.forSession(
      seconds: focus.focusProfile.sessionDuration,
      successful: true,
    );
    final targetGem = expected.gem ?? FocusGem.amber;
    final appEntries = usage.valueOrNull?.entries.toList() ?? [];
    appEntries.sort((a, b) => b.value.screenTime.compareTo(a.value.screenTime));
    final topApps =
        appEntries
            .where((entry) => entry.value.screenTime > 0)
            .take(3)
            .toList();

    void openFocus() {
      if (sessionActive) {
        Navigator.of(context).pushNamed(AppRoutes.activeSessionPath);
      } else {
        final tabs = TabControllerProvider.maybeOf(context);
        if (tabs != null && tabs.controller.length == 5) {
          tabs.animateToTab(2);
        } else {
          Navigator.of(context).pushNamed(AppRoutes.focusModePath);
        }
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_dashboardSessionsProvider);
        ref.invalidate(focusRewardsProvider);
        await ref
            .read(todaysAppsUsageProvider.notifier)
            .refreshTodaysUsage(resetState: true);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 120),
            sliver: SliverList.list(
              children: [
                Text(
                  username.isEmpty
                      ? 'Your day, with intention.'
                      : 'Your day, $username.',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Small moments of focus. Meaningful progress.',
                  style: TextStyle(color: Colors.white60, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPalette.primaryContainer,
                        AppPalette.card,
                        AppPalette.background,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppPalette.highlight,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sessionActive
                                  ? 'SESSION IN PROGRESS'
                                  : 'A LITTLE FOCUS GOES FAR',
                              style: const TextStyle(
                                color: AppPalette.primaryLight,
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sessionActive
                                      ? 'Keep your focus flowing.'
                                      : 'Make room for what matters.',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  sessionActive
                                      ? 'Your session is running. Return whenever you need.'
                                      : 'Turn focused time into a gem worth collecting.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.5,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            targetGem.assetPath,
                            width: 84,
                            height: 105,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: AppPalette.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onPressed: openFocus,
                        icon: Icon(
                          sessionActive
                              ? Icons.timer_outlined
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          sessionActive
                              ? 'Return to session'
                              : 'Start focusing',
                        ),
                      ),
                    ],
                  ),
                ),
                const _Heading(
                  'Today at a glance',
                  caption: 'Your progress, one session at a time',
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width =
                        constraints.maxWidth < 300
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: _Metric(
                            icon: Icons.center_focus_strong_rounded,
                            color: AppPalette.primaryLight,
                            title: 'Focused today',
                            value:
                                history.hasValue
                                    ? _time(dailySeconds.last)
                                    : '?',
                            detail:
                                history.hasError
                                    ? 'Unable to load sessions'
                                    : '$todaysSessions successful sessions',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _Metric(
                            icon: Icons.phone_android_rounded,
                            color: AppPalette.secondary,
                            title: 'Screen time',
                            value:
                                !permissions.haveUsageAccessPermission
                                    ? '?'
                                    : usage.hasValue
                                    ? _time(screenSeconds)
                                    : '?',
                            detail:
                                permissions.haveUsageAccessPermission
                                    ? 'Across your apps today'
                                    : 'Usage access needed',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _Metric(
                            icon: Icons.local_fire_department_rounded,
                            color: AppPalette.secondary,
                            title: 'Focus streak',
                            value: '${focus.focusMode.currentStreak} days',
                            detail: 'Keep showing up for yourself',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _Metric(
                            icon: Icons.check_circle_outline_rounded,
                            color: AppPalette.primaryLight,
                            title: 'Tasks completed',
                            value:
                                '${tasks.where((task) => task.isCompleted).length} / ${tasks.length}',
                            detail:
                                tasks.isEmpty
                                    ? 'A fresh page for your plans'
                                    : 'From your task list today',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const _Heading(
                  'Your focus rhythm',
                  caption: 'Completed focus time over the last 7 days',
                ),
                _Panel(
                  child: history.when(
                    data:
                        (_) => _WeekChart(seconds: dailySeconds, today: today),
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    error:
                        (_, _) => _Retry(
                          message: 'Unable to load focus activity.',
                          retry:
                              () => ref.invalidate(_dashboardSessionsProvider),
                        ),
                  ),
                ),
                const _Heading(
                  'Time well spent',
                  caption: 'Your gem collection and ranking progress',
                ),
                _Panel(
                  child: rewards.when(
                    data:
                        (collection) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 24,
                              runSpacing: 12,
                              children: [
                                _RewardTotal(
                                  value: '${collection.totalGems + legacyGems}',
                                  label: 'Gems collected',
                                ),
                                _RewardTotal(
                                  value: '${collection.points}',
                                  label: 'Ranking points',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                for (final gem in FocusGem.values)
                                  SizedBox(
                                    width: 68,
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          gem.assetPath,
                                          height: 42,
                                          width: 42,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${collection.count(gem)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          gem.label,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              legacyGems > 0
                                  ? 'Includes $legacyGems earlier gems. Every new focused minute earns 1 ranking point.'
                                  : 'Every completed focus minute earns 1 ranking point.',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            TextButton(
                              onPressed: openFocus,
                              child: const Text('Explore your next gem ?'),
                            ),
                          ],
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (_, _) => _Retry(
                          message: 'Unable to load your rewards.',
                          retry: () => ref.invalidate(focusRewardsProvider),
                        ),
                  ),
                ),
                const _Heading(
                  'Your most-used apps',
                  caption: 'A little awareness goes a long way',
                ),
                _Panel(
                  child:
                      !permissions.haveUsageAccessPermission
                          ? const Text(
                            'Enable usage access in Tools to see your daily app insights.',
                            style: TextStyle(color: Colors.white60),
                          )
                          : usage.when(
                            data:
                                (_) =>
                                    topApps.isEmpty
                                        ? const Text(
                                          'No app usage recorded today.',
                                          style: TextStyle(
                                            color: Colors.white60,
                                          ),
                                        )
                                        : Column(
                                          children: [
                                            for (final entry in topApps)
                                              _UsageRow(
                                                package: entry.key,
                                                seconds: entry.value.screenTime,
                                                maxSeconds:
                                                    topApps
                                                        .first
                                                        .value
                                                        .screenTime,
                                              ),
                                          ],
                                        ),
                            loading:
                                () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error:
                                (_, _) => _Retry(
                                  message: 'Unable to load app usage.',
                                  retry:
                                      () => ref
                                          .read(
                                            todaysAppsUsageProvider.notifier,
                                          )
                                          .refreshTodaysUsage(resetState: true),
                                ),
                          ),
                ),
                const SizedBox(height: 24),
                const DashboardUpdateNotes(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _time(int seconds) {
  final minutes = seconds ~/ 60;
  return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {required this.caption});
  final String title;
  final String caption;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 28, 2, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          caption,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    ),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final Color color;
  final String title, value, detail;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _RewardTotal extends StatelessWidget {
  const _RewardTotal({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppPalette.highlight,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ],
  );
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.seconds, required this.today});
  final List<int> seconds;
  final DateTime today;
  @override
  Widget build(BuildContext context) {
    final maximum = max(60, seconds.reduce(max));
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final day = DateTime(
              today.year,
              today.month,
              today.day - (6 - index),
            );
            return Expanded(
              child: Semantics(
                label:
                    '${day.day}/${day.month}: ${seconds[index] ~/ 60} focused minutes',
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                      child: Text(
                        '${seconds[index] ~/ 60}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 92,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 18,
                          height:
                              seconds[index] == 0
                                  ? 4
                                  : max(6, 92 * seconds[index] / maximum),
                          decoration: BoxDecoration(
                            color:
                                seconds[index] == 0
                                    ? Colors.white12
                                    : index == 6
                                    ? AppPalette.highlight
                                    : AppPalette.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      weekdays[day.weekday - 1],
                      style: TextStyle(
                        color:
                            index == 6 ? AppPalette.highlight : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        if (seconds.every((value) => value == 0)) ...[
          const SizedBox(height: 16),
          const Text(
            'Your first completed session starts the rhythm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.package,
    required this.seconds,
    required this.maxSeconds,
  });
  final String package;
  final int seconds, maxSeconds;
  @override
  Widget build(BuildContext context) => FutureBuilder<AppInfo?>(
    future: AppNameResolver.getAppInfo(package),
    builder:
        (context, snapshot) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => Navigator.of(context).pushNamed(
                AppRoutes.appDashboardPath,
                arguments: {'package': package},
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                if (snapshot.data != null)
                  ApplicationIcon(appInfo: snapshot.data!, size: 19)
                else
                  const Icon(
                    Icons.android_rounded,
                    color: Colors.white54,
                    size: 32,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              snapshot.data?.name ?? package,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _time(seconds),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      LinearProgressIndicator(
                        value: seconds / maxSeconds,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.white10,
                        color: AppPalette.primaryLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message),
      TextButton(onPressed: retry, child: const Text('Retry')),
    ],
  );
}
