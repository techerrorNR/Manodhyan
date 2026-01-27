import 'package:flutter/material.dart';

import '../routes.dart';

class ManoDhyanFeatureHubScreen extends StatelessWidget {
  const ManoDhyanFeatureHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _ManoDhyanFeature(
        title: 'Usage Insights',
        description:
            'Review weekly stats, app usage, and focus history powered by ManoDhyan’s dashboard.',
        route: AppRoutes.ManoDhyanDashboard,
      ),
      _ManoDhyanFeature(
        title: 'Focus Mode',
        description:
            'See distracting apps, start focus sessions, and view your focus timeline.',
        route: AppRoutes.ManoDhyanFocus,
      ),
      _ManoDhyanFeature(
        title: 'Restriction Groups',
        description:
            'Create app groups, shared limits, and Invincible Mode parental controls.',
        route: AppRoutes.ManoDhyanRestrictionGroups,
      ),
      _ManoDhyanFeature(
        title: 'Shorts Blocking',
        description:
            'Set limits for short-form apps, timers, and emergency pauses.',
        route: AppRoutes.ManoDhyanShortsBlocking,
      ),
      _ManoDhyanFeature(
        title: 'Websites Blocking',
        description:
            'Block distracting or NSFW sites with VPN-backed controls.',
        route: AppRoutes.ManoDhyanWebsitesBlocking,
      ),
      _ManoDhyanFeature(
        title: 'Notifications Control',
        description:
            'Batch, mute, or schedule app notifications during focus blocks.',
        route: AppRoutes.ManoDhyanNotifications,
      ),
      _ManoDhyanFeature(
        title: 'Bedtime Routine',
        description:
            'Plan downtime with app pauses and Do Not Disturb overnight.',
        route: AppRoutes.ManoDhyanBedtime,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ManoDhyan Controls'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final feature = features[index];
          return Card(
            color: const Color(0xFF1B192F),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(feature.route);
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: features.length,
      ),
    );
  }
}

class _ManoDhyanFeature {
  const _ManoDhyanFeature({
    required this.title,
    required this.description,
    required this.route,
  });

  final String title;
  final String description;
  final String route;
}
