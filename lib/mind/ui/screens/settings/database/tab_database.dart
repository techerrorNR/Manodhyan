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
import 'package:manodhyan/mind/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:manodhyan/mind/ui/screens/settings/database/export_clear_crash_logs.dart';
import 'package:manodhyan/mind/ui/screens/settings/database/import_export_db.dart';

class TabDatabase extends ConsumerWidget {
  const TabDatabase({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        /// Backup, restore and reset
        ImportExportDb(),

        /// Crash logs
        ExportClearCrashLogs(),

        SliverTabsBottomPadding()
      ],
    );
  }
}
