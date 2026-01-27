import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manodhyan/mind/core/services/drift_db_service.dart';
import 'package:manodhyan/mind/core/utils/date_time_utils.dart';
import 'package:manodhyan/mind/core/extensions/ext_date_time.dart';
import 'package:manodhyan/mind/models/usage_model.dart';
import 'package:manodhyan/mind/providers/usage/todays_apps_usage_provider.dart';

/// Provides a map of package name to usage model for a specific date.
/// If date is today, it uses [todaysAppsUsageProvider].
/// Otherwise, it fetches from database.
final dailyAppsUsageProvider = FutureProvider.family.autoDispose<Map<String, UsageModel>, DateTime>((ref, date) async {
  if (date.isSameDay(dateToday)) {
    final todaysUsage = ref.watch(todaysAppsUsageProvider);
    return todaysUsage.value ?? {};
  } else {
    return await DriftDbService.instance.driftDb.dynamicRecordsDao.fetchDatedAppsUsage(selectedDay: date);
  }
});
