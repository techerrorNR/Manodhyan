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
import 'package:manodhyan/mind/config/navigation/app_routes.dart'
    as mind_routes;
import 'package:manodhyan/mind/core/enums/default_home_tab.dart';
import 'package:manodhyan/mind/core/enums/item_position.dart';
import 'package:manodhyan/mind/core/extensions/ext_build_context.dart';
import 'package:manodhyan/mind/core/extensions/ext_list.dart';
import 'package:manodhyan/mind/core/extensions/ext_num.dart';
import 'package:manodhyan/mind/providers/usage/todays_apps_usage_provider.dart';
import 'package:manodhyan/mind/ui/common/content_section_header.dart';
import 'package:manodhyan/mind/ui/common/default_expandable_list_tile.dart';
import 'package:manodhyan/mind/ui/common/default_list_tile.dart';
import 'package:manodhyan/mind/ui/common/sliver_active_session_alert.dart';
import 'package:manodhyan/mind/ui/common/default_refresh_indicator.dart';
import 'package:manodhyan/mind/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:manodhyan/mind/ui/controllers/tab_controller_provider.dart';
import 'package:manodhyan/mind/ui/screens/home/dashboard/glance_cards/focus_daily_glance.dart';
import 'package:manodhyan/mind/ui/screens/home/dashboard/glance_cards/screen_time_glance.dart';
import 'package:manodhyan/mind/ui/screens/home/dashboard/glance_cards_grid.dart';
import 'package:manodhyan/mind/ui/screens/home/dashboard/sliver_tips_and_tricks.dart';
import 'package:manodhyan/mind/ui/transitions/default_effects.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:manodhyan/routes.dart' as mano_routes;
import 'package:manodhyan/services/alarm_service.dart';

class TabDashboard extends ConsumerWidget {
  const TabDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsageLoading =
        ref.watch(todaysAppsUsageProvider.select((v) => v.isLoading));

    return DefaultRefreshIndicator(
      onRefresh: () async => ref
          .read(todaysAppsUsageProvider.notifier)
          .refreshTodaysUsage(resetState: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// Active session
          const SliverActiveSessionAlert(),

          MultiSliver(
            children: [
              8.vBox,
              Skeletonizer.zone(
                enabled: isUsageLoading,
                enableSwitchAnimation: true,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      /// Screen time
                      const Expanded(child: ScreenTimeGlance()),
                      4.hBox,

                      /// Data usage
                      const Expanded(child: FocusDailyGlance()),
                    ],
                  ),
                ),
              ),

              /// Usage glance
              DefaultExpandableListTile(
                position: ItemPosition.mid,
                titleText: context.locale.glance_tile_title,
                subtitleText: context.locale.glance_tile_subtitle,
                content: Skeletonizer.zone(
                  enabled: isUsageLoading,
                  enableSwitchAnimation: true,
                  child: const GlanceCardsGrid(),
                ),
              ),

              /// Parental controls
              DefaultListTile(
                position: ItemPosition.bottom,
                leadingIcon: FluentIcons.shield_keyhole_20_regular,
                titleText: context.locale.parental_controls_tab_title,
                subtitleText: context.locale.parental_controls_tile_subtitle,
                color: Theme.of(context).colorScheme.secondaryContainer,
                trailing: const Icon(FluentIcons.chevron_right_20_regular),
                onPressed: () => Navigator.of(context)
                    .pushNamed(mind_routes.AppRoutes.parentalControlsPath),
              ),

              /// Restrictions
              ..._restrictions(context),

              /// Productivity
              ..._productivity(context),
            ].animateListOnce(
              ref: ref,
              uniqueKey: "home.dashboard",
              delay: 100.ms,
              effects: DefaultEffects.transitionIn,
              interval: 100.ms,
            ),
          ),

          /// Tips and tricks
          const SliverTipsAndTricks(),

          const SliverTabsBottomPadding(),
        ],
      ),
    );
  }

  static List<Widget> _restrictions(BuildContext context) => [
        /// Restrictions
        ContentSectionHeader(
          title: context.locale.restrictions_heading,
        ),

        /// Apps blocking
        DefaultListTile(
          position: ItemPosition.top,
          leadingIcon: FluentIcons.app_title_20_regular,
          titleText: context.locale.apps_blocking_tile_title,
          subtitleText: context.locale.apps_blocking_tile_subtitle,
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => AlarmService.instance.navigatorKey.currentState
              ?.pushNamed(mano_routes.AppRoutes.ManoDhyanFocus),
        ),

        /// Grouped apps blocking
        DefaultListTile(
          position: ItemPosition.mid,
          leadingIcon: FluentIcons.app_recent_20_regular,
          titleText: context.locale.grouped_apps_blocking_tile_title,
          subtitleText: context.locale.grouped_apps_blocking_tile_subtitle,
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => Navigator.of(context)
              .pushNamed(mind_routes.AppRoutes.restrictionGroupsPath),
        ),

        /// Shorts restrictions
        DefaultListTile(
          position: ItemPosition.mid,
          leadingIcon: FluentIcons.resize_video_20_regular,
          titleText: context.locale.shorts_blocking_tab_title,
          subtitleText: context.locale.shorts_blocking_tile_subtitle,
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => AlarmService.instance.navigatorKey.currentState
              ?.pushNamed(mano_routes.AppRoutes.ManoDhyanShortsBlocking),
        ),

        /// Website restrictions
        DefaultListTile(
          position: ItemPosition.bottom,
          leadingIcon: FluentIcons.earth_20_regular,
          titleText: context.locale.websites_blocking_tab_title,
          subtitleText: context.locale.websites_blocking_tile_subtitle,
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => Navigator.of(context)
              .pushNamed(mind_routes.AppRoutes.websitesBlockingPath),
        ),
      ];

  static List<Widget> _productivity(BuildContext context) => [
        /// Productivity
        const ContentSectionHeader(title: "Productivity"),

        /// Habits
        DefaultListTile(
          position: ItemPosition.top,
          leadingIcon: FluentIcons.drink_coffee_20_regular,
          titleText: "Habits",
          subtitleText: "Build better habits and track them.",
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => context.showSnackAlert(
            "Coming soon...",
            icon: FluentIcons.info_20_filled,
          ),
        ),

        /// Tasks and todos
        DefaultListTile(
          position: ItemPosition.mid,
          leadingIcon: FluentIcons.reading_list_20_regular,
          titleText: "Tasks and todos",
          subtitleText: "Plan your future with tasks and todos.",
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => AlarmService.instance.navigatorKey.currentState
              ?.pushNamed(mano_routes.AppRoutes.ManoDhyanTasks),
        ),

        /// Notes & lists
        DefaultListTile(
          position: ItemPosition.bottom,
          leadingIcon: FluentIcons.note_20_regular,
          titleText: "Notes and lists",
          subtitleText: "Capture thoughts, checklists, or ideas.",
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () => context.showSnackAlert(
            "Coming soon...",
            icon: FluentIcons.info_20_filled,
          ),
        ),
      ];
}
