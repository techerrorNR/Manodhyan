import 'package:flutter/material.dart';
import '../models/focus_reward.dart';

class FocusRewardPreview extends StatelessWidget {
  const FocusRewardPreview({
    super.key,
    required this.seconds,
    this.completed = false,
    this.isOpenEnded = false,
  });

  final int seconds;
  final bool completed;
  final bool isOpenEnded;

  @override
  Widget build(BuildContext context) {
    final reward = FocusReward.forSession(seconds: seconds, successful: true);
    final gem = reward.gem;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              completed ? 'Session rewards earned' : 'Session reward',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${gem == null ? 'No gem' : '1 ${gem.label}'} + ${reward.points} ranking points',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: gem == null ? null : Color(gem.colorValue),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              completed
                  ? 'Your collection and ranking points have been updated.'
                  : isOpenEnded
                  ? 'Based on time focused so far. Finish successfully to collect.'
                  : 'Complete the session to collect. Giving up earns no rewards.',
              textAlign: TextAlign.center,
            ),
            if (gem == null && !completed)
              const Text('Focus for at least 5 minutes to earn an Amber.'),
            if (gem != null && !completed)
              Text('${gem.category} · ${gem.timeRange}'),
          ],
        ),
      ),
    );
  }
}
