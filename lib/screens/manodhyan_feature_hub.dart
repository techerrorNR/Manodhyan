import 'package:flutter/material.dart';
import '../mind/ui/screens/home/tools/tab_tools.dart';

/// Older control-center shortcuts open the same controls as the Tools tab.
class ManoDhyanFeatureHubScreen extends StatelessWidget {
  const ManoDhyanFeatureHubScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tools')),
    body: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: TabTools(),
    ),
  );
}
