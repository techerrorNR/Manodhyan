import 'package:focusjoy/mind/config/app_palette.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../controllers/timer_controller.dart';
import '../models/focus_reward.dart';
import '../widgets/focus_gem_collection.dart';
import '../widgets/focus_reward_preview.dart';
import '../mind/config/navigation/app_routes.dart' as focus_routes;
import '../mind/providers/focus/focus_mode_provider.dart';
import '../mind/providers/focus/focus_session_gems_provider.dart';
import '../mind/ui/screens/focus/focus_mode/tab_focus.dart';
import '../routes.dart';

/// The crystal page and Focus Mode use the same session and blocking controls.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusModeProvider);
    final session = focus.activeSession.valueOrNull;
    final isActive = session != null;
    final duration =
        session?.durationSecs ?? focus.focusProfile.sessionDuration;
    final remaining =
        isActive && duration > 0
            ? max(0, duration - focus.elapsedTimeSec)
            : duration;
    final progress =
        isActive && duration > 0 ? (remaining / duration).clamp(0.0, 1.0) : 1.0;
    final rewards = ref.watch(focusRewardsProvider);
    final previewSeconds = duration == 0 ? focus.elapsedTimeSec : duration;
    final preview = FocusReward.forSession(
      seconds: previewSeconds,
      successful: true,
    );
    // Retain crystals earned with the earlier timer alongside Focus Mode gems.
    final legacyGems = context.watch<TimerController>().crystals;
    final canConfigure = !isActive && !focus.activeSession.isLoading;

    void changeDuration(int delta) {
      final next = (duration + delta).clamp(5 * 60, 120 * 60).toInt();
      ref.read(focusModeProvider.notifier).setSessionDuration(next);
    }

    return TabFocus(
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Text(
              isActive ? 'Focus in progress' : 'Select Focus Time',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 16,
              children: [
                _StatBadge(
                  icon: Icons.local_fire_department,
                  value: '${focus.focusMode.currentStreak}',
                  label: 'Streak',
                  color: AppPalette.secondary,
                ),
                _StatBadge(
                  icon: Icons.diamond,
                  value: rewards.when(
                    data:
                        (collection) => '${legacyGems + collection.totalGems}',
                    loading: () => '...',
                    error: (_, _) => 'Unavailable',
                  ),
                  label: 'Gems',
                  color: AppPalette.primaryLight,
                ),
                _StatBadge(
                  icon: Icons.emoji_events,
                  value: rewards.when(
                    data: (collection) => '${collection.points}',
                    loading: () => '...',
                    error: (_, _) => 'Unavailable',
                  ),
                  label: 'Ranking points',
                  color: AppPalette.highlight,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation(
                      Color(
                        preview.gem?.colorValue ?? FocusGem.amber.colorValue,
                      ),
                    ),
                    backgroundColor: AppPalette.primary.withValues(alpha: 0.3),
                  ),
                ),
                ClipOval(
                  child: Image.asset(
                    (preview.gem ?? FocusGem.amber).assetPath,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              duration == 0
                  ? 'Open-ended · ${focus.elapsedTimeSec ~/ 60} min focused'
                  : '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white, fontSize: 26),
            ),
            const SizedBox(height: 12),
            if (canConfigure)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Decrease focus time',
                    onPressed:
                        duration > 5 * 60
                            ? () => changeDuration(-5 * 60)
                            : null,
                    icon: const Icon(Icons.remove_circle),
                    iconSize: 36,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    tooltip: 'Increase focus time',
                    onPressed:
                        duration < 120 * 60
                            ? () => changeDuration(5 * 60)
                            : null,
                    icon: const Icon(Icons.add_circle),
                    iconSize: 36,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            FocusRewardPreview(
              seconds: previewSeconds,
              isOpenEnded: duration == 0,
            ),
            if (isActive)
              FilledButton.icon(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pushNamed(focus_routes.AppRoutes.activeSessionPath),
                icon: const Icon(Icons.timer),
                label: const Text('View active session'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            rewards.when(
              data:
                  (collection) => FocusGemCollection(
                    collection: collection,
                    legacyGems: legacyGems,
                  ),
              loading: () => const CircularProgressIndicator(),
              error:
                  (_, _) => Column(
                    children: [
                      const Text('Unable to load your gem collection.'),
                      TextButton(
                        onPressed: () => ref.invalidate(focusRewardsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.ManoDhyanPermissions),
              icon: const Icon(Icons.shield_moon_outlined),
              label: const Text('Device permissions'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.ManoDhyanFeatureHub),
              child: const Text('Open FocusJoy Controls'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
