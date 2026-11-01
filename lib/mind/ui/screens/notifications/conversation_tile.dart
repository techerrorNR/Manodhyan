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
import 'package:focusjoy/mind/core/database/app_database.dart' as db;
import 'package:focusjoy/mind/core/enums/item_position.dart';
import 'package:focusjoy/mind/core/extensions/ext_build_context.dart';
import 'package:focusjoy/mind/ui/common/default_expandable_list_tile.dart';
import 'package:focusjoy/mind/ui/common/styled_text.dart';
import 'package:focusjoy/mind/ui/screens/notifications/notification_tile.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.appName,
    required this.packageName,
    required this.leading,
    required this.conversations,
    required this.position,
  });

  final String packageName;
  final List<db.Notification> conversations;
  final Widget leading;
  final String appName;

  final ItemPosition position;

  @override
  Widget build(BuildContext context) {
    return DefaultExpandableListTile(
      titleText: appName,
      position: position,
      subtitle: StyledText(
        "${conversations.length} ${context.locale.conversations_label}",
        fontSize: 14,
        color: Theme.of(context).hintColor,
      ),
      leading: leading,
      content: ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.all(0),
        itemCount: conversations.length,
        itemBuilder: (context, index) => NotificationTile(
          notification: conversations[index],
          position: ItemPosition.mid,
        ),
      ),
    );
  }
}
