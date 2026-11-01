import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/core/services/drift_db_service.dart';
import 'package:focusjoy/models/focus_reward.dart';

/// Successful focus history is the durable ledger for tiered gems and points.
/// This also includes sessions completed while the crystal page was not open.
final focusRewardsProvider = StreamProvider<FocusRewardCollection>((ref) {
  return DriftDbService.instance.driftDb.dynamicRecordsDao
      .watchSuccessfulFocusSessions()
      .map(
        (sessions) => FocusRewardCollection.fromCompletedSessions({
          for (final session in sessions) session.id: session.durationSecs,
        }),
      );
});
