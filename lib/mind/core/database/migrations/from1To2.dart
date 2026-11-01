// ignore_for_file: file_names

import 'package:drift/drift.dart';
import 'package:focusjoy/mind/core/database/schemas/schema_versions.dart';
import 'package:focusjoy/mind/core/utils/db_utils.dart';

Future<void> from1To2(Migrator m, Schema2 schema) async => await runSafe(
      "Migration(1 to 2)",
      () async {
        /// Add protective access [Bool] column
        await m.addColumn(
          schema.ManoDhyanSettingsTable,
          schema.ManoDhyanSettingsTable.protectedAccess,
        );

        /// Add uninstall window time [TimeOfDayAdapter] column
        await m.addColumn(
          schema.ManoDhyanSettingsTable,
          schema.ManoDhyanSettingsTable.uninstallWindowTime,
        );
      },
    );
