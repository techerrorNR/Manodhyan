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
import 'package:manodhyan/mind/config/navigation/app_routes.dart';
import 'package:manodhyan/mind/config/hero_tags.dart';
import 'package:manodhyan/mind/core/extensions/ext_build_context.dart';
import 'package:manodhyan/mind/ui/common/default_fab_button.dart';

class FocusNowFab extends StatelessWidget {
  const FocusNowFab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultFabButton(
      heroTag: HeroTags.focusModeFABTag,
      icon: FluentIcons.target_arrow_20_filled,
      label: context.locale.focus_now_fab_button,
      onPressed: () => Navigator.of(context).pushNamed(
        AppRoutes.focusModePath,
        arguments: 0,
      ),
    );
  }
}
