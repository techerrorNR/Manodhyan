import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/ui/controllers/home_tab_provider.dart';
import 'package:focusjoy/mind/ui/screens/universal_home.dart';
import 'package:focusjoy/services/alarm_service.dart';
import 'package:focusjoy/mind/config/navigation/app_routes_observer.dart';

/// Returns to the crystal Focus tab in the existing home navigation bar.
class GlobalFocusButton extends ConsumerWidget {
  const GlobalFocusButton({super.key});

  void _openFocus(WidgetRef ref) {
    final navigator = AlarmService.instance.navigatorKey.currentState;
    if (navigator == null) return;
    ref.read(homeTabProvider.notifier).state = UniversalHomeScreen.focusTab;
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppRoutesObserver.instance.showFocusShortcut,
      builder:
          (context, visible, _) =>
              visible ? _button(context, ref) : const SizedBox.shrink(),
    );
  }

  Widget _button(BuildContext context, WidgetRef ref) {
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
              onTap: () => _openFocus(ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
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
