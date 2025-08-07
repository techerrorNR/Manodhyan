import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppUsageChart extends StatelessWidget {
  final Map<String, int> usageData;

  const AppUsageChart({super.key, required this.usageData});

  @override
  Widget build(BuildContext context) {
    final sorted = usageData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sorted.take(5).toList();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= topApps.length) return const Text('');
                final appName = topApps[value.toInt()].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    appName.length > 10 ? "${appName.substring(0, 10)}…" : appName,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(topApps.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: topApps[i].value / 1000 / 60, // minutes
                width: 14,
                color: Colors.deepPurpleAccent,
              )
            ],
          );
        }),
      ),
    );
  }
}
