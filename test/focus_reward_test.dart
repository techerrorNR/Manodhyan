import 'package:flutter_test/flutter_test.dart';
import 'package:focusjoy/models/focus_reward.dart';

void main() {
  test(
    'collectibles change only when a complete tier threshold is reached',
    () {
      final boundaries = <int, FocusGem?>{
        0: null,
        299: null,
        300: FocusGem.amber,
        599: FocusGem.amber,
        600: FocusGem.amethyst,
        899: FocusGem.amethyst,
        900: FocusGem.aquamarine,
        1799: FocusGem.aquamarine,
        1800: FocusGem.emerald,
        3599: FocusGem.emerald,
        3600: FocusGem.ruby,
        7200: FocusGem.ruby,
      };
      for (final entry in boundaries.entries) {
        final reward = FocusReward.forSession(
          seconds: entry.key,
          successful: true,
        );
        expect(reward.gem, entry.value, reason: '${entry.key} seconds');
      }
    },
  );

  test('giving up cannot earn a gem or ranking points', () {
    for (final seconds in [0, 300, 1800, 3600, 7200]) {
      final reward = FocusReward.forSession(
        seconds: seconds,
        successful: false,
      );
      expect(reward.gem, isNull);
      expect(reward.points, 0);
    }
  });

  test('ranking points count whole minutes, without rarity multipliers', () {
    final oneHour = FocusReward.forSession(seconds: 3600, successful: true);
    final twoHours = FocusReward.forSession(seconds: 7200, successful: true);
    final shortSession = FocusReward.forSession(seconds: 359, successful: true);
    expect(oneHour.gem, FocusGem.ruby);
    expect(twoHours.gem, FocusGem.ruby);
    expect(oneHour.points, 60);
    expect(twoHours.points, 120);
    expect(shortSession.points * 12, oneHour.points);
  });

  test('reopening saved history restores the same collection and points', () {
    final savedHistory = {1: 300, 2: 600, 3: 900, 4: 1800, 5: 3600, 6: 7200};
    final collection = FocusRewardCollection.fromCompletedSessions(
      savedHistory,
    );
    final reopened = FocusRewardCollection.fromCompletedSessions(savedHistory);
    expect(collection.totalGems, 6);
    expect(collection.points, 240);
    expect(reopened.totalGems, collection.totalGems);
    expect(reopened.points, collection.points);
    for (final gem in FocusGem.values) {
      expect(collection.count(gem), gem == FocusGem.ruby ? 2 : 1);
      expect(reopened.count(gem), collection.count(gem));
    }
  });

  test('sub-five-minute sessions earn points but no gem', () {
    final collection = FocusRewardCollection.fromCompletedSessions({1: 299});
    expect(collection.totalGems, 0);
    expect(collection.points, 4);
  });
}
