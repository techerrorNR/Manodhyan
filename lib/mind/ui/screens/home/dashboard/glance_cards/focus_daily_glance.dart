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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manodhyan/mind/core/enums/item_position.dart';
import 'package:manodhyan/mind/core/extensions/ext_build_context.dart';
import 'package:manodhyan/mind/core/extensions/ext_duration.dart';
import 'package:manodhyan/mind/core/extensions/ext_int.dart';
import 'package:manodhyan/mind/core/utils/date_time_utils.dart';
import 'package:manodhyan/mind/providers/focus/monthly_focus_provider.dart';
import 'package:manodhyan/mind/ui/common/progress_percentage_indicator.dart';
import 'package:manodhyan/mind/ui/common/usage_glance_card.dart';

class FocusDailyGlance extends ConsumerWidget {
  const FocusDailyGlance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customRange =
        DateTimeRange(start: dateToday.subtract(1.days), end: dateToday);

    final (today, yesterday) = ref.watch(
      monthlyFocusProvider(customRange).select((v) => (
            v.monthlyFocus[customRange.end] ?? 0,
            v.monthlyFocus[customRange.start] ?? 0
          )),
    );

    return UsageGlanceCard(
      isPrimary: true,
      position: ItemPosition.topRight,
      icon: FluentIcons.target_20_filled,
      title: context.locale.focus_today_label,
      info: today.seconds.toTimeShort(context),
      badge: ProgressPercentageIndicator(
        invertProgress: true,
        progressPercentage: today.toDiffPercentage(yesterday),
      ),
    );
  }
}
