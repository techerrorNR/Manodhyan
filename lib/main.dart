import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/alarm_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/timer_controller.dart';
import 'routes.dart';
import 'screens/math_challenge_screen.dart';
import 'screens/nav_screen.dart';
import 'services/alarm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final alarmService = AlarmService.instance;
  await alarmService.initialize();
  runApp(
    MultiProvider(
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
  );
}

class ManoDhyanApp extends StatelessWidget {
  const ManoDhyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ManoDhyan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      navigatorKey: AlarmService.instance.navigatorKey,
      home: const NavScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.mathChallenge) {
          return MathChallengeScreen.routeFromSettings(settings);
        }
        return null;
      },
    );
  }
}
