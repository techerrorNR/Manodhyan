import 'package:usage_stats/usage_stats.dart';

class UsageService {
  static Future<Map<String, int>> getAppUsage() async {
    DateTime end = DateTime.now();
    DateTime start = end.subtract(const Duration(hours: 24));

    Map<String, UsageInfo> usageStats = await UsageStats.queryAndAggregateUsageStats(start, end);
    Map<String, int> usageMap = {};

    usageStats.forEach((package, info) {
      int totalTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      if (totalTime > 0) {
        usageMap[package] = totalTime;
      }
    });

    return usageMap;
  }
}
