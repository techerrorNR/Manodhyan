import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../widgets/app_usage_chart.dart';
import 'package:usage_stats/usage_stats.dart';
import '../services/app_name_resolver.dart';


class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  Map<String, int> _usageData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  void _loadUsage() async {
    bool granted = await UsageStats.checkUsagePermission() ?? false;

    if (!granted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text("This feature requires Usage Access. Please allow permission in settings."),
          actions: [
            TextButton(
              onPressed: () {
                UsageStats.grantUsagePermission();
                Navigator.of(ctx).pop();
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            )
          ],
        ),
      );
      setState(() => _loading = false);
      return;
    }

    final rawData = await UsageService.getAppUsage();

    // ✅ Resolve app names dynamically
    final nameMap = await AppNameResolver.resolveNames(rawData.keys.toList());

    // 🔁 Rebuild usage data with app names as keys
    final resolvedData = <String, int>{};
    rawData.forEach((pkg, time) {
      final name = nameMap[pkg] ?? pkg;
      resolvedData[name] = time;
    });

    setState(() {
      _usageData = resolvedData;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D21),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "App Usage (Last 24 hrs)",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const CircularProgressIndicator()
          else if (_usageData.isEmpty)
            const Text("No usage data found.", style: TextStyle(color: Colors.grey))
          else
            SizedBox(height: 200, child: AppUsageChart(usageData: _usageData)),
          const Spacer(),
          const Text("Crystal Challenges Below...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
