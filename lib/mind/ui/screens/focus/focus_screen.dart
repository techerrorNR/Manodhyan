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
import 'package:focusjoy/mind/core/extensions/ext_build_context.dart';
import 'package:focusjoy/mind/ui/common/scaffold_shell.dart';
import 'package:focusjoy/mind/ui/screens/focus/focus_mode/tab_focus.dart';
import 'package:focusjoy/mind/ui/screens/focus/focus_timeline/tab_focus_timeline.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, this.initialTabIndex});

  final int? initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return ScaffoldShell(
      initialTab: initialTabIndex,
      items: [
        NavbarItem(
          icon: FluentIcons.target_arrow_20_regular,
          filledIcon: FluentIcons.target_arrow_20_filled,
          titleText: context.locale.focus_tab_title,
          sliverBody: const TabFocus(),
        ),
        NavbarItem(
          icon: FluentIcons.history_20_regular,
          filledIcon: FluentIcons.history_20_filled,
          titleText: context.locale.timeline_tab_title,
          sliverBody: const TabFocusTimeline(),
        ),
      ],
    );
  }
}
