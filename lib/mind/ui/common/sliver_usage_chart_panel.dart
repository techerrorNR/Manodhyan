/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manodhyan/mind/core/enums/usage_type.dart';
import 'package:manodhyan/mind/core/extensions/ext_date_time.dart';
import 'package:manodhyan/mind/core/extensions/ext_num.dart';
import 'package:manodhyan/mind/core/utils/date_time_utils.dart';
import 'package:manodhyan/mind/models/usage_model.dart';
import 'package:manodhyan/mind/ui/common/styled_text.dart';
import 'package:manodhyan/mind/ui/common/meta_combo_chart.dart';

class SliverUsageChartPanel extends StatelessWidget {
  /// Sliver list containing base bar chart for usage and
  /// selected day of week changer buttons
  const SliverUsageChartPanel({
    super.key,
    this.chartHeight = 460, // Increased default height for combo layout
    required this.selectedDay,
    required this.selectedWeek,
    required this.usageType,
    required this.barChartData,
    required this.onDayOfWeekChanged,
    required this.onWeekChanged,
    this.centerWidget,
  });

  final double chartHeight;
  final DateTime selectedDay;
  final DateTimeRange selectedWeek;
  final UsageType usageType;
  final Map<DateTime, UsageModel> barChartData;
  final ValueChanged<DateTime> onDayOfWeekChanged;
  final ValueChanged<DateTime> onWeekChanged;
  final Widget? centerWidget;

  void _changeWeek(int direction) {
    final newDate = selectedDay.add((direction * 7).days);

    /// Invoke on day and week changed
    onWeekChanged(newDate);
    onDayOfWeekChanged(newDate.startOfWeek);
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        /// Meta Combo Chart
        Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16),
           child: MetaComboChart(
            height: chartHeight,
            usageType: usageType,
            selectedDay: selectedDay,
            onDayBarTap: onDayOfWeekChanged,
            data: barChartData,
            centerWidget: centerWidget,
          ),
        ),

        8.vBox,

        /// Selected day changer
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              /// Previous week
              IconButton(
                icon: const Icon(FluentIcons.chevron_left_20_filled),
                onPressed: () => _changeWeek(-1),
              ),

              const Spacer(),

              /// Current day
              StyledText(
                "${selectedWeek.start.dateStringShort(context)} - ${selectedWeek.end.dateStringShort(context)}",
                color: Theme.of(context).hintColor,
                fontSize: 14,
              ),

              /// Reset button
              if (selectedWeek.end.isBefore(dateToday.startOfWeek))
                IconButton(
                  iconSize: 18,
                  icon: const Icon(
                    FluentIcons.arrow_counterclockwise_20_regular,
                  ),
                  onPressed: () {
                    onDayOfWeekChanged(dateToday);
                    onWeekChanged(dateToday);
                  },
                ),

              const Spacer(),

              /// Next week
              selectedWeek.end.isBefore(dateToday.endOfWeek)
                  ? IconButton(
                      icon: const Icon(FluentIcons.chevron_right_20_filled),
                      onPressed: () => _changeWeek(1),
                    )
                  : 48.hBox,
            ],
          ),
        ),
      ],
    );
  }
}
