import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/timer_controller.dart';
import 'screens/nav_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TimerController(),
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
      home: const NavScreen(),
    );
  }
}
