/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/core/database/app_database.dart';
import 'package:focusjoy/mind/core/services/drift_db_service.dart';

final searchedNotificationsProvider =
    FutureProvider.family<List<Notification>, String>(
  (ref, query) async => query.isEmpty
      ? Future.value([])
      : DriftDbService.instance.driftDb.dynamicRecordsDao
          .searchNotificationsWithQuery(query: query),
);
