import 'dart:math' as math;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusjoy/mind/ui/controllers/home_tab_provider.dart';
import 'package:focusjoy/mind/ui/screens/universal_home.dart';
import 'package:focusjoy/services/alarm_service.dart';
import 'package:focusjoy/services/floating_focus_service.dart';
import 'package:focusjoy/mind/config/navigation/app_routes_observer.dart';

/// Android uses a real overlay; other platforms keep this movable app shortcut.
class GlobalFocusButton extends ConsumerWidget {
  const GlobalFocusButton({super.key, this.shortcut});
  final FloatingFocusService? shortcut;

  void _openFocus(WidgetRef ref) {
    final navigator = AlarmService.instance.navigatorKey.currentState;
    if (navigator == null) return;
    ref.read(homeTabProvider.notifier).state = UniversalHomeScreen.focusTab;
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = shortcut ?? FloatingFocusService.instance;
    return AnimatedBuilder(
      animation: service,
      builder:
          (context, _) => ValueListenableBuilder<bool>(
            valueListenable: AppRoutesObserver.instance.showFocusShortcut,
            builder: (context, visible, _) {
              if (!visible || !service.enabled || service.usesNativeOverlay) {
                return const SizedBox.shrink();
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final media = MediaQuery.of(context);
                  final left = media.viewPadding.left + 8;
                  final top = media.viewPadding.top + 8;
                  final travelX = math.max(
                    0.0,
                    constraints.maxWidth -
                        left -
                        media.viewPadding.right -
                        8 -
                        124,
                  );
                  final travelY = math.max(
                    0.0,
                    constraints.maxHeight -
                        top -
                        math.max(
                          media.viewPadding.bottom,
                          media.viewInsets.bottom,
                        ) -
                        8 -
                        52,
                  );
                  void save() => service.savePosition(service.x, service.y);
                  return SizedBox.expand(
                    child: Stack(
                      children: [
                        Positioned(
                          left: left + service.x * travelX,
                          top: top + service.y * travelY,
                          width: 124,
                          height: 52,
                          child: GestureDetector(
                            key: const ValueKey('floating-focus-button'),
                            onPanUpdate:
                                (details) => service.previewPosition(
                                  travelX == 0
                                      ? 0
                                      : service.x + details.delta.dx / travelX,
                                  travelY == 0
                                      ? 0
                                      : service.y + details.delta.dy / travelY,
                                ),
                            onPanEnd: (_) => save(),
                            onPanCancel: save,
                            child: Semantics(
                              label: 'Open Focus. Drag to move the shortcut.',
                              button: true,
                              child: Material(
                                color: Theme.of(context).colorScheme.primary,
                                elevation: 6,
                                borderRadius: BorderRadius.circular(28),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () => _openFocus(ref),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FluentIcons.target_arrow_20_filled,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Focus',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelLarge?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
