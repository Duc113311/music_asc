import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/feedback_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_button.dart';
import '../common_components/primary_dialog.dart';

/// sc_rate_app: stars, Rate / Later / close. Every star count opens the store
/// — low ratings are not diverted to feedback (P14-19). Only "store opened"
/// is recorded, never "rated" (P14-20).
Future<void> showRateAppDialog() async {
  await FeedbackService.markRatePrompted();
  await Get.dialog<void>(const _RateDialog());
}

class _RateDialog extends StatefulWidget {
  const _RateDialog();
  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  int _stars = 0;

  /// Opening effect: the stars light up one by one, up to 5. A tap on a
  /// star stops it and keeps the user's choice.
  Timer? _intro;
  static const _introDelay = Duration(milliseconds: 250);
  static const _introStep = Duration(milliseconds: 160);

  @override
  void initState() {
    super.initState();
    _intro = Timer(_introDelay, () {
      if (!mounted) return;
      setState(() => _stars = 1);
      _intro = Timer.periodic(_introStep, (t) {
        if (!mounted || _stars >= 5) {
          t.cancel();
          return;
        }
        setState(() => _stars++);
      });
    });
  }

  @override
  void dispose() {
    _intro?.cancel();
    super.dispose();
  }

  void _pick(int i) {
    _intro?.cancel();
    setState(() => _stars = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppDialog(
      onClose: () => Get.back<void>(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.rateApp, height: 96, fit: BoxFit.contain),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'rate_title'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.headingS.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'rate_desc'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.bodyM.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          // 5 × 48 dp is wider than the dialog content on 320 dp phones.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 5; i++)
                  Semantics(
                    button: true,
                    selected: i <= _stars,
                    label: 'rate_stars_n'.trParams({'args1': '$i'}),
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => _pick(i),
                      customBorder: const CircleBorder(),
                      containedInkWell: true,
                      highlightShape: BoxShape.circle,
                      child: SizedBox.square(
                        dimension: AppSizes.touch,
                        // Pops in when it lights up.
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(i <= _stars),
                          tween: Tween(begin: i <= _stars ? 0.6 : 1, end: 1),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Icon(
                            i <= _stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 36,
                            color: i <= _stars ? c.primary : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_stars > 0)
            Text(
              'rate_label_$_stars'.tr,
              style: AppTypography.label.copyWith(color: c.primary),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'rate_cta'.tr,
            onPressed: _stars == 0
                ? null
                : () async {
                    final ok = await FeedbackService.openStoreReview();
                    Get.back<void>();
                    if (!ok) ToastUtils.error('error_no_store_app'.tr);
                  },
          ),
          PrimaryButton(
            label: 'action_later'.tr,
            variant: ButtonVariant.tertiary,
            onPressed: () async => Get.back<void>(),
          ),
        ],
      ),
    );
  }
}
