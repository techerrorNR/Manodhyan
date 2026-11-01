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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/core/extensions/ext_build_context.dart';
import 'package:focusjoy/mind/core/extensions/ext_widget.dart';
import 'package:focusjoy/mind/providers/restrictions/wellbeing_provider.dart';
import 'package:focusjoy/mind/ui/common/empty_list_indicator.dart';
import 'package:focusjoy/mind/ui/common/sliver_implicitly_animated_list.dart';
import 'package:focusjoy/mind/ui/screens/websites_blocking/website_tile.dart';

class SliverBlockedWebsitesList extends ConsumerWidget {
  const SliverBlockedWebsitesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedWebsites = ref.watch(wellBeingProvider.select(
      (v) => v.blockedWebsites,
    ));
    final nsfwWebsites = ref.watch(wellBeingProvider.select(
      (v) => v.nsfwWebsites,
    ));

    final allWebsites = {...nsfwWebsites.reversed, ...blockedWebsites.reversed};

    return allWebsites.isNotEmpty
        ? SliverImplicitlyAnimatedList(
            itemExtent: 64,
            items: allWebsites.toList(),
            keyBuilder: (item) => item,
            itemBuilder: (context, i, item, position) => WebsiteTile(
              websitehost: item,
              isRemovable: !nsfwWebsites.contains(item),
              position: position,
            ),
          )
        : EmptyListIndicator(
            info: context.locale.blocked_websites_empty_list_hint,
          ).sliver;
  }
}
