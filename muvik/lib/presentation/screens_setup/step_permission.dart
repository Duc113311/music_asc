import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/setup_controller.dart';
import '../../services/application/library_scan_service.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';
import 'setup_screen.dart';

/// sc_step_01: request audio access. Refusal offers Retry / Later; when the
/// system won't ask again, "Mở cài đặt" (P06-09, P06-10).
class StepPermission extends GetView<SetupController> {
  const StepPermission({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Obx(() {
      final perm = controller.permission.value;
      final permanently = perm == AudioPermissionStatus.permanentlyDenied;
      final denied = controller.askedOnce.value || permanently;
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          Image.asset(AppAssets.step1, height: 220, fit: BoxFit.contain),
          const SizedBox(height: AppSpacing.md),
          SetupTitle(
            title: 'step1_title'.tr,
            highlight: 'step1_highlight'.tr,
            description: 'step1_desc'.tr,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.surfaceSelected,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: c.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'step1_card_title'.tr,
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        'step1_card_desc'.tr,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (denied) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: c.warning.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: c.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      permanently
                          ? 'step1_denied_permanent'.tr
                          : 'step1_denied'.tr,
                      style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: permanently
                ? 'action_open_settings'.tr
                : (denied ? 'action_retry'.tr : 'step1_allow'.tr),
            variant: ButtonVariant.gradient,
            trailingIcon: Icons.arrow_forward_rounded,
            loading: controller.requesting.value,
            onPressed: controller.requestPermission,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'action_later'.tr,
            variant: ButtonVariant.secondary,
            onPressed: controller.later,
          ),
        ],
      );
    });
  }
}
