import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manodhyan/mind/config/app_constants.dart';
import 'package:manodhyan/mind/core/extensions/ext_build_context.dart';
import 'package:manodhyan/mind/core/extensions/ext_num.dart';
import 'package:manodhyan/mind/models/permissions_model.dart';
import 'package:manodhyan/mind/providers/system/manodhyan_settings_provider.dart';
import 'package:manodhyan/mind/providers/system/permissions_provider.dart';
import 'package:manodhyan/mind/ui/onboarding/onboarding_page.dart';
import 'package:manodhyan/mind/ui/onboarding/permission_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Embeds ManoDhyan's onboarding pages + permission checks inside ManoDhyan.
class ManoDhyanPermissionsFlow extends ConsumerStatefulWidget {
  const ManoDhyanPermissionsFlow({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManoDhyanPermissionsFlowState();
}

class _ManoDhyanPermissionsFlowState
    extends ConsumerState<ManoDhyanPermissionsFlow> {
  int _currentPage = 0;
  ProviderSubscription? _subscription;
  final PageController _controller = PageController();
  final _animCurve = Curves.easeInOut;
  final _animDuration = AppConstants.defaultAnimDuration;
  late final List<Widget> _pages = [
    OnboardingPage(
      title: context.locale.onboarding_page_one_title,
      imgArtPath: "assets/illustrations/onboarding_1.png",
      description: context.locale.onboarding_page_one_info,
    ),
    OnboardingPage(
      title: context.locale.onboarding_page_two_title,
      imgArtPath: "assets/illustrations/onboarding_2.png",
      description: context.locale.onboarding_page_two_info,
    ),
    OnboardingPage(
      title: context.locale.onboarding_page_three_title,
      imgArtPath: "assets/illustrations/onboarding_3.png",
      description: context.locale.onboarding_page_three_info,
    ),
    const PermissionsPage(),
  ];

  @override
  void initState() {
    super.initState();

    _subscription = ref.listenManual<PermissionsModel>(
      permissionProvider,
      (_, perms) {
        if (!_haveEssentialPermissions(perms)) return;
        _finishOnboarding();
        _subscription?.close();
      },
    );

    if (ref.read(ManoDhyanSettingsProvider).isOnboardingDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _skipToLastPage());
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  bool _haveEssentialPermissions(PermissionsModel perms) =>
      perms.haveUsageAccessPermission &&
      perms.haveDisplayOverlayPermission &&
      perms.haveAlarmsPermission &&
      perms.haveNotificationPermission;

  void _finishOnboarding() {
    if (!mounted) return;
    ref.read(ManoDhyanSettingsProvider.notifier).markOnboardingDone();
    widget.onFinished?.call();
    Navigator.of(context).maybePop();
  }

  void _skipToLastPage() {
    if (!mounted) return;
    _controller.animateToPage(
      _pages.length - 1,
      duration: _animDuration,
      curve: _animCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final perms = ref.watch(permissionProvider);
    final haveAllEssentialPermissions = _haveEssentialPermissions(perms);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _pages[index],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipToLastPage,
                    child: Text(context.locale.onboarding_skip_btn_label),
                  )
                      .animate(target: isLastPage ? 0 : 1)
                      .scale(duration: 100.ms),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.only(bottom: 32, top: 4),
                    child: Row(
                      children: [
                        SmoothPageIndicator(
                          controller: _controller,
                          count: _pages.length,
                          effect: ExpandingDotsEffect(
                            dotWidth: 10,
                            dotHeight: 10,
                            spacing: 6,
                            expansionFactor: 2.5,
                            dotColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            activeDotColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () => _controller.previousPage(
                            curve: _animCurve,
                            duration: _animDuration,
                          ),
                          padding: const EdgeInsets.all(10),
                          icon: const Icon(FluentIcons.caret_left_20_filled),
                        )
                            .animate(
                              target: _currentPage > 0 && !isLastPage ? 1 : 0,
                            )
                            .scale(duration: 150.ms),
                        4.hBox,
                        isLastPage
                            ? FilledButton(
                                onPressed: haveAllEssentialPermissions
                                    ? _finishOnboarding
                                    : null,
                                child: Text(context
                                    .locale.onboarding_finish_setup_btn_label),
                              )
                                .animate(target: isLastPage ? 1 : 0)
                                .scale(
                                  duration: 250.ms,
                                  alignment: Alignment.centerRight,
                                )
                            : IconButton.filled(
                                padding: const EdgeInsets.all(10),
                                onPressed: () => _controller.nextPage(
                                  curve: _animCurve,
                                  duration: _animDuration,
                                ),
                                icon: const Icon(
                                    FluentIcons.caret_right_20_filled),
                              )
                                .animate(target: isLastPage ? 0 : 1)
                                .scale(duration: 150.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
