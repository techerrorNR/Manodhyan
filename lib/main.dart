import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';

import 'controllers/alarm_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/timer_controller.dart';
import 'mind/config/navigation/app_routes.dart' as manodhyan_nav;
import 'mind/l10n/generated/app_localizations.dart';
import 'mind/providers/system/permissions_provider.dart';
import 'mind/models/permissions_model.dart';
import 'mind_bootstrap.dart';
import 'routes.dart';
import 'mind/ui/screens/universal_home.dart';
import 'screens/math_challenge_screen.dart';
import 'screens/manodhyan_feature_hub.dart';
import 'screens/manodhyan_feature_shell.dart';
import 'screens/manodhyan_permissions_screen.dart';
import 'services/alarm_service.dart';
import 'widgets/global_focus_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ManoDhyanBootstrap.instance.ensureInitialized();
  final alarmService = AlarmService.instance;
  await alarmService.initialize();
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TimerController(alarmService: alarmService),
          ),
          ChangeNotifierProvider(
            create: (_) {
              final controller = AlarmController();
              controller.initialize();
              return controller;
            },
          ),
          ChangeNotifierProvider(
            create: (_) {
              final controller = TaskController();
              controller.initialize();
              return controller;
            },
          ),
        ],
        child: const ManoDhyanApp(),
      ),
    ),
  );
}

class ManoDhyanApp extends ConsumerStatefulWidget {
  const ManoDhyanApp({super.key});

  @override
  ConsumerState<ManoDhyanApp> createState() => _ManoDhyanAppState();
}

class _ManoDhyanAppState extends ConsumerState<ManoDhyanApp> {
  ProviderSubscription? _permissionSubscription;
  bool _permissionRouteVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybePromptForPermissions(ref.read(permissionProvider)),
    );
    _permissionSubscription = ref.listenManual<PermissionsModel>(
      permissionProvider,
      (_, next) => _maybePromptForPermissions(next),
    );
  }

  bool _hasAllEssentialPermissions(PermissionsModel perms) =>
      perms.haveUsageAccessPermission &&
      perms.haveDisplayOverlayPermission &&
      perms.haveAlarmsPermission &&
      perms.haveNotificationPermission;

  void _maybePromptForPermissions(PermissionsModel perms) {
    if (_hasAllEssentialPermissions(perms)) {
      _permissionRouteVisible = false;
      return;
    }
    if (_permissionRouteVisible) return;
    _permissionRouteVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = AlarmService.instance.navigatorKey.currentState;
      if (navigator == null) return;
      navigator
          .pushNamed(AppRoutes.ManoDhyanPermissions)
          .whenComplete(() => _maybePromptForPermissions(
                ref.read(permissionProvider),
              ));
    });
  }

  @override
  void dispose() {
    _permissionSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ManoDhyan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      navigatorKey: AlarmService.instance.navigatorKey,
      home: const UniversalHomeScreen(),
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const GlobalFocusButton(),
        ],
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.mathChallenge) {
          return MathChallengeScreen.routeFromSettings(settings);
        }
        if (settings.name == AppRoutes.ManoDhyanPermissions) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanPermissionsScreen(),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanFeatureHub) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureHubScreen(),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanDashboard) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.homePath,
              parameters: {"tab": "0"},
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanTasks) {
          return MaterialPageRoute(
            builder: (_) => const UniversalHomeScreen(
              initialTab: 1,
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanFocus) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.focusModePath,
              parameters: {"tab": "0"},
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanRestrictionGroups) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.restrictionGroupsPath,
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanShortsBlocking) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.shortsBlockingPath,
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanWebsitesBlocking) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.websitesBlockingPath,
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanNotifications) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.notificationsPath,
            ),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.ManoDhyanBedtime) {
          return MaterialPageRoute(
            builder: (_) => const ManoDhyanFeatureShell(
              initialRoute: manodhyan_nav.AppRoutes.homePath,
              parameters: {"tab": "2"},
            ),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
