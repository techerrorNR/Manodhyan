import 'package:flutter/material.dart';
import 'package:manodhyan/mind/core/extensions/ext_num.dart';
import 'package:manodhyan/mind/core/services/drift_db_service.dart';
import 'package:manodhyan/mind/core/services/method_channel_service.dart';
import 'package:manodhyan/mind/ui/common/styled_text.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverAppVersionInfo extends StatelessWidget {
  const SliverAppVersionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final appVersion = MethodChannelService.instance.deviceInfo.ManoDhyanVersion;

    return MultiSliver(
      children: [
        /// App version
        StyledText(
          appVersion,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          isSubtitle: true,
          height: 1,
        ),
        2.vBox,

        /// Database version
        StyledText(
          "db-v${DriftDbService.instance.driftDb.schemaVersion}",
          fontWeight: FontWeight.bold,
          fontSize: 14,
          isSubtitle: true,
          height: 1,
        ),
      ],
    );
  }
}
