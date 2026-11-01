/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:focusjoy/mind/config/app_palette.dart';
import 'package:focusjoy/mind/core/services/method_channel_service.dart';

/// Company and product information, without contribution or external-action buttons.
class TabAbout extends StatelessWidget {
  const TabAbout({super.key});

  @override
  Widget build(BuildContext context) {
    final version = MethodChannelService.instance.deviceInfo.ManoDhyanVersion;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 120),
          sliver: SliverList.list(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/logo/focusjoy-app-icon.png',
                    width: 104,
                    height: 104,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'FocusJoy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Focus with purpose.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $version',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 28),
              const _AboutCard(
                icon: Icons.center_focus_strong_rounded,
                title: 'About the app',
                child: Text(
                  'FocusJoy brings focus sessions, gem rewards, app restrictions, tasks, alarms, and notes together to help you build a more intentional day.',
                  style: TextStyle(color: Colors.white70, height: 1.6),
                ),
              ),
              const SizedBox(height: 14),
              const _AboutCard(
                icon: Icons.business_outlined,
                title: 'Continued development',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shree Ji Technovation',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.primaryLight,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'A Mumbai-based technology company building websites, mobile applications, dashboards, SaaS platforms, business automation systems, and custom software for businesses across India.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Shree Ji Technovation is building on the existing foundation with new features, interface improvements, and future enhancements for this edition of FocusJoy.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                    SizedBox(height: 20),
                    _CompanyDetail(
                      label: 'Owner ? Shree Ji Technovation',
                      value: 'Rakesh Yadav',
                    ),
                    SizedBox(height: 14),
                    _CompanyDetail(
                      label: 'GitHub ? @techerrorNR',
                      value: 'https://github.com/techerrorNR',
                    ),
                    SizedBox(height: 14),
                    _CompanyDetail(label: 'Location', value: 'Mumbai, India'),
                    SizedBox(height: 14),
                    _CompanyDetail(
                      label: 'Website',
                      value: 'https://sjtechnovation.in/',
                    ),
                    SizedBox(height: 14),
                    _CompanyDetail(
                      label: 'Contact',
                      value: 'contact@sjtechnovation.in',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _AboutCard(
                icon: Icons.favorite_outline_rounded,
                title: 'With respect & gratitude',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pawan Nagar',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.primaryLight,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Creator of Mindful, the open-source project that provides a foundation for this app.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'A heartfelt salute to Pawan Nagar and the Mindful contributors for their dedication and generosity in sharing their work openly. We gratefully acknowledge their contribution and respect the original authorship as we continue building new features.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                    SizedBox(height: 20),
                    _CompanyDetail(
                      label: 'Original developer on GitHub',
                      value: 'https://github.com/akaMrNagar',
                    ),
                    SizedBox(height: 14),
                    _CompanyDetail(
                      label: 'Original project · Mindful',
                      value: 'https://github.com/akaMrNagar/Mindful',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _AboutCard(
                icon: Icons.description_outlined,
                title: 'Open-source acknowledgement',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FocusJoy includes code from Mindful released under the GNU General Public License v2. Original copyright and license notices continue to apply. Our new features do not replace or remove those notices.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                    SizedBox(height: 14),
                    _CompanyDetail(
                      label: 'Upstream license',
                      value:
                          'https://github.com/akaMrNagar/Mindful/blob/main/LICENSE',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppPalette.secondary, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _CompanyDetail extends StatelessWidget {
  const _CompanyDetail({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 4),
      SelectableText(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
      ),
    ],
  );
}
