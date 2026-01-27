import 'package:flutter/material.dart';

import '../mind_bootstrap.dart';
import 'manodhyan_permissions_flow.dart';

class ManoDhyanPermissionsScreen extends StatefulWidget {
  const ManoDhyanPermissionsScreen({super.key});

  @override
  State<ManoDhyanPermissionsScreen> createState() =>
      _ManoDhyanPermissionsScreenState();
}

class _ManoDhyanPermissionsScreenState extends State<ManoDhyanPermissionsScreen> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = ManoDhyanBootstrap.instance.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          );
        }

        return Theme(
          data: theme,
          child: const ManoDhyanPermissionsFlow(),
        );
      },
    );
  }
}
