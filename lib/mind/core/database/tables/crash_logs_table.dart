/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:drift/drift.dart';

@DataClassName("CrashLog")
class CrashLogsTable extends Table {
  /// Unique ID for crash logs
  IntColumn get id => integer().autoIncrement()();

  /// Current version of ManoDhyan app
  TextColumn get appVersion => text().withDefault(const Constant(""))();

  /// [DateTime] when the error was thrown
  DateTimeColumn get timeStamp =>
      dateTime().withDefault(Constant(DateTime(0)))();

  /// The error string
  TextColumn get error => text().withDefault(const Constant(""))();

  /// Stack trace when the error or exception was thrown
  TextColumn get stackTrace => text().withDefault(const Constant(""))();
}
