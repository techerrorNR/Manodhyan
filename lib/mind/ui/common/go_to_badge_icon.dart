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

class GoToBadgeIcon extends StatelessWidget {
  const GoToBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      FluentIcons.arrow_up_right_20_filled,
      color: Theme.of(context).hintColor,
      size: 12,
    );
  }
}
