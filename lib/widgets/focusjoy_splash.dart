import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:focusjoy/mind/config/app_palette.dart';

/// Shared startup artwork; the original logo is kept as editable vector paths.
class FocusJoySplash extends StatefulWidget {
  const FocusJoySplash({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<FocusJoySplash> createState() => _FocusJoySplashState();
}

class _FocusJoySplashState extends State<FocusJoySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) _complete();
  });
  bool _started = false;
  bool _completed = false;

  void _complete() {
    if (_completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Keep the logo visible for the first frame without introducing motion.
      _controller.value = 0.8;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _complete();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gem = _controller.drive(
      CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOutCubic)),
    );
    final label = _controller.drive(
      CurveTween(curve: const Interval(0.25, 0.65, curve: Curves.easeOut)),
    );
    final exit =
        widget.onComplete == null
            ? const AlwaysStoppedAnimation<double>(1)
            : _controller.drive(
              Tween<double>(
                begin: 1,
                end: 0,
              ).chain(CurveTween(curve: const Interval(0.86, 1))),
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppPalette.background,
      ),
      child: FadeTransition(
        opacity: exit,
        child: ColoredBox(
          color: AppPalette.background,
          child: SafeArea(
            child: Semantics(
              label: 'FocusJoy. Focus and productivity.',
              image: true,
              child: ExcludeSemantics(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: gem,
                              child: ScaleTransition(
                                scale: gem.drive(
                                  Tween<double>(begin: 0.88, end: 1),
                                ),
                                child: SvgPicture.asset(
                                  'assets/logo/focusjoy-gem.svg',
                                  width: 200,
                                  height: 175,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeTransition(
                              opacity: label,
                              child: SlideTransition(
                                position: label.drive(
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.15),
                                    end: Offset.zero,
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  'assets/logo/focusjoy-wordmark-dark.svg',
                                  width: 260,
                                  height: 58,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
