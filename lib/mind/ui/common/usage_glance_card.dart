/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:manodhyan/mind/core/enums/item_position.dart';
import 'package:manodhyan/mind/core/extensions/ext_num.dart';
import 'package:manodhyan/mind/core/utils/widget_utils.dart';
import 'package:manodhyan/mind/ui/common/rounded_container.dart';
import 'package:manodhyan/mind/ui/common/styled_text.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UsageGlanceCard extends StatelessWidget {
  const UsageGlanceCard({
    super.key,
    required this.title,
    required this.info,
    this.icon,
    this.onTap,
    this.badge,
    this.isPrimary = false,
    this.position = ItemPosition.mid,
  });

  final IconData? icon;
  final bool isPrimary;
  final String title;
  final String info;
  final VoidCallback? onTap;
  final ItemPosition position;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final mini = icon == null;

    return RoundedContainer(
      circularRadius: 6,
      borderRadius: getBorderRadiusFromPosition(position),
      padding: const EdgeInsets.all(16),
      color:
          isPrimary ? Theme.of(context).colorScheme.secondaryContainer : null,
      onPressed: onTap,
      child: Stack(
        children: [
          /// Usage
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mini) Icon(icon),
              mini ? 0.vBox : 14.vBox,
              StyledText(
                title,
                fontSize: 12,
              ),
              Skeleton.leaf(
                child: FittedBox(
                  child: StyledText(
                    info.isEmpty ? " " : info,
                    fontSize: 24,
                    maxLines: 1,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          /// Badge
          Align(
            alignment: Alignment.topRight,
            child: badge ?? 0.hBox,
          )
        ],
      ),
    );
  }
}
