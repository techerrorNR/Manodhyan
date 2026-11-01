/// Collectible tiers depend on completed focus time, not real-world prices.
enum FocusGem {
  amber('Amber', 'Starter', 'assets/crystals/amber.png', 0xFFFFA726, 5, 10),
  amethyst(
    'Amethyst',
    'Growing',
    'assets/crystals/Amethyst.png',
    0xFFBA68C8,
    10,
    15,
  ),
  aquamarine(
    'Aquamarine',
    'Focused',
    'assets/crystals/Aquamarine.png',
    0xFF4DD0E1,
    15,
    30,
  ),
  emerald(
    'Emerald',
    'Deep Focus',
    'assets/crystals/Emerald.png',
    0xFF66BB6A,
    30,
    60,
  ),
  ruby(
    'Ruby',
    'Master Focus',
    'assets/crystals/Ruby.png',
    0xFFEF5350,
    60,
    null,
  );

  const FocusGem(
    this.label,
    this.category,
    this.assetPath,
    this.colorValue,
    this.minimumMinutes,
    this.nextTierMinutes,
  );

  final String label;
  final String category;
  final String assetPath;
  final int colorValue;
  final int minimumMinutes;
  final int? nextTierMinutes;

  String get timeRange =>
      nextTierMinutes == null
          ? '$minimumMinutes+ min'
          : '$minimumMinutes–${nextTierMinutes! - 1} min';
}

class FocusReward {
  const FocusReward({this.gem, this.points = 0});

  /// Only a successfully completed session earns points or a collectible.
  factory FocusReward.forSession({
    required int seconds,
    required bool successful,
  }) {
    if (!successful || seconds <= 0) return const FocusReward();
    final minutes = seconds ~/ 60;
    FocusGem? gem;
    for (final tier in FocusGem.values) {
      if (minutes >= tier.minimumMinutes) gem = tier;
    }
    return FocusReward(gem: gem, points: minutes);
  }

  final FocusGem? gem;
  final int points;
}

/// Saved session IDs form the reward ledger. Rebuilding this collection never
/// increments a balance, so restarts and repeated completion events are harmless.
class FocusRewardCollection {
  FocusRewardCollection.fromCompletedSessions(Map<int, int> sessionDurations) {
    for (final seconds in sessionDurations.values) {
      final reward = FocusReward.forSession(seconds: seconds, successful: true);
      _points += reward.points;
      if (reward.gem case final gem?) {
        _counts[gem] = (_counts[gem] ?? 0) + 1;
      }
    }
  }

  final Map<FocusGem, int> _counts = {};
  int _points = 0;

  int get points => _points;
  int get totalGems => _counts.values.fold(0, (total, count) => total + count);
  int count(FocusGem gem) => _counts[gem] ?? 0;
}
