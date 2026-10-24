import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../../services/application/bootstrap_service.dart';
import '../../services/storage/pref_store.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/primary_button.dart';
import '../../utils/app_log.dart';

/// sc_splash: logo + finite loading. Initialization errors show "Thử lại";
/// no unbounded polling (P06-02).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// language → onboarding → setup → shell (P06-03). The language screen is
  /// shown once, on a fresh install; an install that already finished
  /// onboarding before the screen existed is treated as having chosen.
  static String nextRoute() {
    final onboarded = PrefStore.getBool(
      PrefConst.onboardingCompleted,
      PrefDefaults.onboardingCompleted,
    );
    if (!onboarded &&
        !PrefStore.getBool(
          PrefConst.languageChosen,
          PrefDefaults.languageChosen,
        )) {
      return RouteName.language;
    }
    if (!onboarded) return RouteName.onboarding;
    if (!PrefStore.getBool(
      PrefConst.setupCompleted,
      PrefDefaults.setupCompleted,
    )) {
      return RouteName.setup;
    }
    return RouteName.home;
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _failed = false);
    try {
      await Future.wait([
        BootstrapService.run(),
        Future<void>.delayed(const Duration(milliseconds: 1200)),
      ]);
    } catch (e) {
      AppLog.error('Splash bootstrap', e);
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    Get.offAllNamed(SplashScreen.nextRoute());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            dark ? AppAssets.bgDark : AppAssets.bgLight,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(AppAssets.logo, width: 120, height: 120),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Muvik',
                    style: AppTypography.display.copyWith(
                      color: c.textPrimary,
                      fontSize: 44,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'splash_tagline'.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyL.copyWith(color: c.primary),
                  ),
                  const Spacer(flex: 2),
                  if (_failed) ...[
                    Text(
                      'splash_init_failed'.tr,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyM.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'action_retry'.tr,
                      onPressed: _start,
                      expand: false,
                    ),
                  ] else
                    const _Dots(),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'loading'.tr,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = reduce ? i == 1 : (_a.value * 3).floor() == i;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? c.primary : c.primary.withValues(alpha: 0.35),
              ),
            );
          }),
        ),
      ),
    );
  }
}
