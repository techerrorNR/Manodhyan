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
import 'package:manodhyan/mind/core/extensions/ext_num.dart';
import 'package:manodhyan/mind/core/utils/widget_utils.dart';
import 'package:manodhyan/mind/ui/common/default_list_tile.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SliverShimmerList extends StatelessWidget {
  /// Placeholder shimmer list while the data is loading
  const SliverShimmerList({
    super.key,
    this.includeLeading = true,
    this.includeSubtitle = false,
    this.includeTrailing = false,
  });

  final bool includeLeading;
  final bool includeSubtitle;
  final bool includeTrailing;

  @override
  Widget build(BuildContext context) {
    const itemCount = 20;

    return SliverSkeletonizer.zone(
      enabled: true,
      child: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (_, i) => DefaultListTile(
          position: getItemPositionInList(i, itemCount),
          leading: includeLeading ? const Bone.iconButton() : null,
          trailing: includeTrailing ? const Bone.icon() : null,
          title: Bone.text(
            width: 120.randomHalf.toDouble(),
            fontSize: 16,
          ),
          subtitle: includeSubtitle
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Bone.text(
                    fontSize: 12,
                    width: 208.randomHalf.toDouble(),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
