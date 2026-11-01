import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:provider/provider.dart';

import 'controllers/alarm_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/notes_controller.dart';
import 'controllers/timer_controller.dart';
import 'mind/config/navigation/app_routes.dart' as manodhyan_nav;
import 'mind/config/navigation/app_routes_observer.dart';
import 'mind/config/app_themes.dart';
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
import 'widgets/focusjoy_splash.dart';

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
            create: (_) {
              final controller = NotesController();
              controller.initialize();
              return controller;
            },
          ),
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
  bool _showLaunchSplash = true;

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
    if (_showLaunchSplash) return;
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
          .whenComplete(
            () => _maybePromptForPermissions(ref.read(permissionProvider)),
          );
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
      title: 'FocusJoy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(
        isAmoled: false,
      ).copyWith(pageTransitionsTheme: ThemeData.dark().pageTransitionsTheme),
      navigatorKey: AlarmService.instance.navigatorKey,
      navigatorObservers: [AppRoutesObserver.instance],
      home: const ManoDhyanFeatureShell(
        initialRoute: manodhyan_nav.AppRoutes.homePath,
      ),
      builder:
          (context, child) => Stack(
            children: [
              if (child != null)
                ExcludeSemantics(
                  excluding: _showLaunchSplash,
                  child: IgnorePointer(
                    ignoring: _showLaunchSplash,
                    child: child,
                  ),
                ),
              if (!_showLaunchSplash) const GlobalFocusButton(),
              if (_showLaunchSplash)
                Positioned.fill(
                  child: FocusJoySplash(
                    onComplete: () {
                      if (!mounted) return;
                      setState(() => _showLaunchSplash = false);
                      _maybePromptForPermissions(ref.read(permissionProvider));
                    },
                  ),
                ),
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
        if (settings.name == AppRoutes.ManoDhyanTasks) {
          return MaterialPageRoute(
            builder:
                (_) => const ManoDhyanFeatureShell(
                  initialRoute: manodhyan_nav.AppRoutes.homePath,
                  child: UniversalHomeScreen(
                    initialTab: UniversalHomeScreen.tasksTab,
                  ),
                ),
            settings: settings,
          );
        }
        const featureRoutes = {
          AppRoutes.ManoDhyanDashboard: manodhyan_nav.AppRoutes.homePath,
          AppRoutes.ManoDhyanFocus: manodhyan_nav.AppRoutes.focusModePath,
          AppRoutes.ManoDhyanRestrictionGroups:
              manodhyan_nav.AppRoutes.restrictionGroupsPath,
          AppRoutes.ManoDhyanShortsBlocking:
              manodhyan_nav.AppRoutes.shortsBlockingPath,
          AppRoutes.ManoDhyanWebsitesBlocking:
              manodhyan_nav.AppRoutes.websitesBlockingPath,
          AppRoutes.ManoDhyanNotifications:
              manodhyan_nav.AppRoutes.notificationControlsPath,
          AppRoutes.ManoDhyanBedtime: manodhyan_nav.AppRoutes.bedtimePath,
        };
        final path = featureRoutes[settings.name] ?? settings.name;
        if (manodhyan_nav.AppRoutes.routes.containsKey(path)) {
          return MaterialPageRoute(
            builder:
                (_) => ManoDhyanFeatureShell(
                  initialRoute: path!,
                  child:
                      settings.name == AppRoutes.ManoDhyanDashboard
                          ? const UniversalHomeScreen(
                            initialTab: UniversalHomeScreen.dashboardTab,
                          )
                          : null,
                ),
            settings: RouteSettings(name: path, arguments: settings.arguments),
          );
        }
        return null;
      },
    );
  }
}
