import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manodhyan/mind/config/app_themes.dart';
import 'package:manodhyan/mind/config/navigation/app_routes.dart'
    as manodhyan_nav;
import 'package:manodhyan/mind/config/navigation/app_routes_observer.dart';
import 'package:manodhyan/mind/config/navigation/navigation_service.dart';
import 'package:manodhyan/mind/initializer.dart';
import 'package:manodhyan/mind/l10n/generated/app_localizations.dart';
import 'package:manodhyan/mind/providers/system/manodhyan_settings_provider.dart';

import '../mind_bootstrap.dart';

class ManoDhyanFeatureShell extends ConsumerStatefulWidget {
  const ManoDhyanFeatureShell({
    super.key,
    required this.initialRoute,
    this.parameters,
  });

  final String initialRoute;
  final Map<String, String>? parameters;

  @override
  ConsumerState<ManoDhyanFeatureShell> createState() =>
      _ManoDhyanFeatureShellState();
}

class _ManoDhyanFeatureShellState extends ConsumerState<ManoDhyanFeatureShell> {
  late final Future<void> _initFuture;

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

  Route<dynamic>? _buildRoute(RouteSettings settings) {
    final builder = manodhyan_nav.AppRoutes.routes[settings.name];
    if (builder == null) return null;
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final settings = ref.watch(ManoDhyanSettingsProvider);
        final baseTheme = AppTheme.darkTheme(
          isAmoled: settings.useAmoledDark,
          seedColor: AppTheme.materialColors[settings.accentColor],
        );

        final themed = baseTheme.copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F0D21),
          colorScheme: baseTheme.colorScheme.copyWith(
            background: const Color(0xFF0F0D21),
            surface: const Color(0xFF1B192F),
            primary: Colors.deepPurpleAccent,
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themed,
          navigatorKey: NavigationService.navigatorKey,
          navigatorObservers: [AppRoutesObserver.instance],
          onGenerateRoute: _buildRoute,
          onGenerateInitialRoutes: (_) {
            final builder =
                manodhyan_nav.AppRoutes.routes[widget.initialRoute];
            if (builder == null) return <Route<dynamic>>[];
            return [
              MaterialPageRoute(
                builder: builder,
                settings: RouteSettings(
                  name: widget.initialRoute,
                  arguments: widget.parameters,
                ),
              ),
            ];
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
