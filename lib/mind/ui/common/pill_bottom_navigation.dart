import 'package:focusjoy/mind/config/app_palette.dart';
import 'package:flutter/material.dart';

/// A floating Activity-palette bar with a white selected pill.
class PillBottomNavigation extends StatelessWidget {
  const PillBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<({String label, IconData icon})> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: AppPalette.card,
            elevation: 8,
            shadowColor: Colors.black38,
            shape: StadiumBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: List.generate(destinations.length, (index) {
                  final destination = destinations[index];
                  final selected = selectedIndex == index;
                  final foreground =
                      selected
                          ? AppPalette.background
                          : AppPalette.textPrimary;
                  return Expanded(
                    flex: selected ? 23 : 10,
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: destination.label,
                      onTap: () => onSelected(index),
                      excludeSemantics: true,
                      child: Tooltip(
                        message: destination.label,
                        child: AnimatedContainer(
                          duration:
                              reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? AppPalette.textPrimary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: () => onSelected(index),
                              child: SizedBox(
                                height: 52,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      destination.icon,
                                      color: foreground,
                                      size: 21,
                                    ),
                                    if (selected) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          destination.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: foreground,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
