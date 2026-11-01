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
import 'package:focusjoy/mind/core/extensions/ext_build_context.dart';
import 'package:focusjoy/mind/core/extensions/ext_num.dart';
import 'package:focusjoy/mind/core/extensions/ext_widget.dart';
import 'package:focusjoy/mind/core/utils/widget_utils.dart';
import 'package:focusjoy/mind/providers/restrictions/restriction_groups_provider.dart';
import 'package:focusjoy/mind/ui/common/default_fab_button.dart';
import 'package:focusjoy/mind/ui/common/scaffold_shell.dart';
import 'package:focusjoy/mind/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:focusjoy/mind/ui/common/styled_text.dart';
import 'package:focusjoy/mind/ui/screens/restriction_groups/create_update_group_screen.dart';
import 'package:focusjoy/mind/ui/screens/restriction_groups/restriction_group_card.dart';
import 'package:focusjoy/mind/ui/screens/restriction_groups/sample_restriction_group.dart';
import 'package:sliver_tools/sliver_tools.dart';

class RestrictionGroupsScreen extends ConsumerWidget {
  const RestrictionGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups =
        ref.watch(restrictionGroupsProvider.select((v) => v.values.toList()));

    return ScaffoldShell(
      items: [
        NavbarItem(
          icon: FluentIcons.app_title_20_regular,
          filledIcon: FluentIcons.app_title_20_filled,
          titleText: context.locale.restriction_groups_tab_title,
          fab: DefaultFabButton(
            label: context.locale.create_group_fab_button,
            icon: FluentIcons.tab_add_20_filled,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const CreateUpdateRestrictionGroupScreen(),
              ),
            ),
          ),
          sliverBody: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              /// Information about groups
              StyledText(context.locale.restriction_groups_tab_info).sliver,

              16.vSliverBox,

              SliverAnimatedSwitcher(
                duration: 250.ms,
                child: groups.isEmpty
                    ? const SampleRestrictionGroup().sliver
                    : SliverList.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) => RestrictionGroupCard(
                          group: groups[index],
                          position: getItemPositionInList(index, groups.length),
                        ),
                      ),
              ),

              const SliverTabsBottomPadding(),
            ],
          ),
        )
      ],
    );
  }
}
