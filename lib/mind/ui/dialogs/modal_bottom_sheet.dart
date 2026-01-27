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
import 'package:manodhyan/mind/config/app_constants.dart';
import 'package:manodhyan/mind/ui/common/content_section_header.dart';
import 'package:manodhyan/mind/ui/common/sliver_tabs_bottom_padding.dart';

/// Opens modal bottom sheet with the passed sliver body
///
/// [initialSize] should be between 0-1
Future<void> showDefaultBottomSheet({
  required BuildContext context,
  required Widget sliverBody,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12),
  Widget? header,
  String? headerTitle,
  double initialSize = 0.5,
}) async =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppConstants.defaultAnimDuration,
        curve: Curves.easeOutBack,
        reverseDuration: AppConstants.defaultAnimDuration,
        reverseCurve: Curves.easeOutBack.flipped,
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialSize,
        builder: (context, scrollController) => Padding(
          padding: padding,
          child: Column(
            children: [
              /// Header
              headerTitle != null
                  ? ContentSectionHeader(
                      title: headerTitle,
                      padding: const EdgeInsets.only(bottom: 12),
                    )
                  : header ?? 0.vBox,

              /// Body
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    sliverBody,
                    const SliverTabsBottomPadding(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
