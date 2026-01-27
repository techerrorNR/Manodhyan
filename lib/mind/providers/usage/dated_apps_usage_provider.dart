import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:manodhyan/mind/core/services/drift_db_service.dart';
import 'package:manodhyan/mind/core/utils/date_time_utils.dart';
import 'package:manodhyan/mind/models/usage_model.dart';
import 'package:manodhyan/mind/providers/usage/todays_apps_usage_provider.dart';

/// A future provider that manages a map of Package and its usage for the selected day.
final appsUsageProvider =
    FutureProvider.family<Map<String, UsageModel>, DateTime>(
  (ref, selectedDay) => selectedDay == dateToday
      ? Future.value(ref.watch(todaysAppsUsageProvider).value ?? {})
      : DriftDbService.instance.driftDb.dynamicRecordsDao.fetchDatedAppsUsage(
          selectedDay: selectedDay,
        ),
);
