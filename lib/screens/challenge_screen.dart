import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manodhyan/mind/core/enums/usage_type.dart';
import 'package:manodhyan/mind/providers/usage/weekly_device_usage_provider.dart';
import 'package:manodhyan/mind/ui/common/meta_combo_chart.dart';
import 'package:manodhyan/mind/models/usage_model.dart';
import 'package:manodhyan/mind/core/utils/date_time_utils.dart';
import 'package:manodhyan/mind/core/extensions/ext_date_time.dart';

import 'package:manodhyan/mind/providers/usage/daily_apps_usage_provider.dart';
import 'package:manodhyan/mind/ui/common/application_icon.dart';
import 'package:manodhyan/services/app_name_resolver.dart';
import 'package:manodhyan/mind/models/app_info.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  DateTime _selectedDay = dateToday;
  DateTimeRange _selectedWeek = dateToday.weekRange;
  UsageType _usageType = UsageType.screenUsage;

  @override
  Widget build(BuildContext context) {
    // Check global stats
    final weeklyUsages = ref.watch(weeklyDeviceUsageProvider(_selectedWeek));
    final dailyAppsUsage = ref.watch(dailyAppsUsageProvider(_selectedDay));

    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Activity Hub",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Meta Combo Chart
              MetaComboChart(
                height: 460,
                usageType: _usageType,
                selectedDay: _selectedDay,
                data: weeklyUsages,
                onDayBarTap: (day) {
                  setState(() {
                    _selectedDay = day;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Apps Usage List
              dailyAppsUsage.when(
                data: (usageMap) {
                  if (usageMap.isEmpty) {
                    return const Center(
                      child: Text(
                        "No usage data available",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final sortedEntries = usageMap.entries.toList()
                    ..sort((a, b) =>
                        b.value.screenTime.compareTo(a.value.screenTime));

                  // Show top 15 apps
                  final topApps = sortedEntries.take(15).toList();

                  return Column(
                    children: [
                      const Align(
                         alignment: Alignment.centerLeft,
                         child: Text(
                          "Top Apps",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...topApps.map((e) => _AppUsageItem(
                            packageName: e.key,
                            usage: e.value,
                            maxDuration: topApps.first.value.screenTime,
                          )),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B192F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      "Crystal Challenges",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Stay within your 8h goal to earn extra crystals!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _AppUsageItem extends StatelessWidget {
  const _AppUsageItem({
    required this.packageName,
    required this.usage,
    required this.maxDuration,
  });

  final String packageName;
  final UsageModel usage;
  final int maxDuration;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInfo?>(
      future: AppNameResolver.getAppInfo(packageName),
      builder: (context, snapshot) {
        final appInfo = snapshot.data;
        if (appInfo == null && snapshot.connectionState == ConnectionState.done) {
             // Avoid showing items we can't identify if needed, or show placeholder
             // For now, let's show separate placeholder if needed or just wait
             return const SizedBox();
        }
        
        // If loading or found:
        final name = appInfo?.name ?? packageName;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
               if (appInfo != null)
                 ApplicationIcon(appInfo: appInfo, size: 20)
               else
                 const CircleAvatar(
                   radius: 20,
                   backgroundColor: Colors.white10,
                   child: Icon(Icons.android, size: 20, color: Colors.white54),
                 ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Text(
                             name,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.w500),
                           ),
                         ),
                         Text(
                           _formatTime(usage.screenTime),
                           style: const TextStyle(
                               color: Colors.white70, fontSize: 13),
                         ),
                       ],
                     ),
                     const SizedBox(height: 6),
                     Stack(
                       children: [
                         Container(
                           height: 6,
                           decoration: BoxDecoration(
                             color: Colors.white10,
                             borderRadius: BorderRadius.circular(3),
                           ),
                         ),
                         FractionallySizedBox(
                           widthFactor: (usage.screenTime / maxDuration).clamp(0.0, 1.0),
                           child: Container(
                             height: 6,
                             decoration: BoxDecoration(
                               color: Colors.deepPurpleAccent,
                               borderRadius: BorderRadius.circular(3),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
