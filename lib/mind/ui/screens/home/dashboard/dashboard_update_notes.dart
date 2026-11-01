import 'package:flutter/material.dart';
import 'package:focusjoy/mind/config/app_palette.dart';

/// Planned features, kept distinct from functionality available today.
class DashboardUpdateNotes extends StatelessWidget {
  const DashboardUpdateNotes({super.key});

  static const _updates = [
    (
      Icons.alarm_on_rounded,
      'Task-based alarms',
      'Planned: connect alarms to your tasks so reminders support what you want to get done.',
    ),
    (
      Icons.extension_rounded,
      'More mindful games',
      'Planned: 8×8 Mini Sudoku, memory, and attention challenges for a purposeful mental break.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppPalette.primary.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.campaign_outlined, color: AppPalette.secondary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Future updates',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Coming in future updates. These features are not available yet.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
        ),
        for (final (icon, title, description) in _updates)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 21, color: AppPalette.primaryLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
