import 'package:focusjoy/mind/config/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/config/app_themes.dart';
import 'package:focusjoy/mind/config/navigation/app_routes.dart'
    as manodhyan_nav;
import 'package:focusjoy/mind/initializer.dart';
import 'package:focusjoy/mind/providers/system/manodhyan_settings_provider.dart';

import '../mind_bootstrap.dart';

class ManoDhyanFeatureShell extends ConsumerStatefulWidget {
  const ManoDhyanFeatureShell({
    super.key,
    required this.initialRoute,
    this.child,
  });

  final String initialRoute;
  final Widget? child;

  @override
  ConsumerState<ManoDhyanFeatureShell> createState() =>
      _ManoDhyanFeatureShellState();
}

class _ManoDhyanFeatureShellState extends ConsumerState<ManoDhyanFeatureShell> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _bootstrapManoDhyanStack();
  }

  Future<void> _bootstrapManoDhyanStack() async {
    await ManoDhyanBootstrap.instance.ensureInitialized();
    await ref.read(ManoDhyanSettingsProvider.notifier).init();
    await Initializer.initializeServicesAndSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('FocusJoy')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load this screen. Please try again.'),
                  FilledButton(
                    onPressed:
                        () => setState(() {
                          _initFuture = _bootstrapManoDhyanStack();
                        }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = ref.watch(ManoDhyanSettingsProvider);
        final baseTheme = AppTheme.darkTheme(
          isAmoled: settings.useAmoledDark,
          seedColor: AppTheme.materialColors[settings.accentColor],
        );

        final themed = baseTheme.copyWith(
          scaffoldBackgroundColor: AppPalette.background,
          colorScheme: baseTheme.colorScheme.copyWith(
            surface: AppPalette.card,
            primary: AppPalette.primary,
          ),
        );

        // Feature pages share the app's navigator. Creating another MaterialApp
        // here mounted the same global navigator key for every open feature.
        return Theme(
          data: themed,
          child:
              widget.child ??
              Builder(
                builder: manodhyan_nav.AppRoutes.routes[widget.initialRoute]!,
              ),
        );
      },
    );
  }
}
