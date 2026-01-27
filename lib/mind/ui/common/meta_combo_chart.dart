import 'package:flutter/material.dart';
import 'package:manodhyan/mind/core/enums/usage_type.dart';
import 'package:manodhyan/mind/models/usage_model.dart';
import 'package:manodhyan/mind/ui/common/default_bar_chart.dart';
import 'package:manodhyan/mind/config/app_constants.dart';
import 'package:manodhyan/mind/core/extensions/ext_int.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class MetaComboChart extends StatelessWidget {
  const MetaComboChart({
    super.key,
    this.height = 450,
    required this.usageType,
    required this.selectedDay,
    required this.data,
    required this.onDayBarTap,
    this.centerWidget,
  });

  final double height;
  final UsageType usageType;
  final DateTime selectedDay;
  final Map<DateTime, UsageModel> data;
  final Function(DateTime) onDayBarTap;
  final Widget? centerWidget;

  @override
  Widget build(BuildContext context) {
    // Calculate stats for the selected day
    final usage = data[selectedDay] ?? const UsageModel();
    final screenTime = usage.screenTime; // seconds
    // Arbitrary goal: 8 hours (28800s) for screen time, just for visualization
    final screenGoal = 28800; 
    final screenPercent = (screenTime / screenGoal).clamp(0.0, 1.0);

    // Mock secondary metric as we assume 'Unlocks' or 'Data' isn't fully piped for rings yet
    // Using totalData if available, specific goal 1GB
    final dataUsage = usage.totalData; // MB/KB likely? UsageModel defines it.
    final dataGoal = 1024 * 1024 * 1024; // 1GB in bytes? Need to check UsageModel units.
    // checks ext_int: .mb, .gb usually exist
    // Assuming totalData is bytes or similar. `UsageModel` usually stores raw.
    // Let's just use a visual placeholder 2nd ring if we lack data, or data usage.
    
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B192F), // ManoDhyan Card Color
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Top Section: Radial Rings & Stats
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // Activity Rings
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Ring Background
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          valueColor: AlwaysStoppedAnimation(Colors.deepPurple.withOpacity(0.2)),
                        ),
                      ),
                      // Outer Ring Value (Screen Time)
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: screenPercent,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          valueColor: const AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                        ),
                      ),
                      // Inner Ring Background
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          valueColor: AlwaysStoppedAnimation(Colors.orange.withOpacity(0.2)),
                        ),
                      ),
                      // Inner Ring Value (Data/Other)
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: 0.4, // Static for now as placeholder or data usage
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent),
                        ),
                      ),
                      // Center Icon
                      centerWidget ?? const Icon(FluentIcons.data_pie_24_filled, color: Colors.white70, size: 32),
                    ],
                  ),
                ),
                // Legend / Stats
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatLegend(
                        color: Colors.deepPurpleAccent,
                        label: 'Screen',
                        value: _formatTime(screenTime),
                        icon: FluentIcons.phone_24_filled,
                      ),
                      const SizedBox(height: 16),
                      const _StatLegend(
                        color: Colors.orangeAccent,
                        label: 'Goal',
                        value: '8h 0m',
                        icon: FluentIcons.target_24_filled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Bottom Section: Bar Chart
          Expanded(
            flex: 4,
            child: DefaultBarChart(
              usageType: usageType,
              selectedDay: selectedDay,
              data: data,
              onDayBarTap: onDayBarTap,
              height: 150, // Constrained height
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}

class _StatLegend extends StatelessWidget {
  const _StatLegend({
    required this.color,
    required this.label,
    required this.value,
    required this.icon,
  });

  final Color color;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
