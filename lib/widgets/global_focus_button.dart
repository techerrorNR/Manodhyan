import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:manodhyan/routes.dart';
import 'package:manodhyan/services/alarm_service.dart';

/// Floating shortcut that can launch the ManoDhyan focus stack
/// from anywhere inside the app.
class GlobalFocusButton extends StatelessWidget {
  const GlobalFocusButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Material(
            color: colorScheme.primary,
            elevation: 6,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => AlarmService.instance.navigatorKey.currentState
                  ?.pushNamed(AppRoutes.ManoDhyanFocus),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.target_arrow_20_filled,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Focus',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
