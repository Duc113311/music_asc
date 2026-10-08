import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/app_config.dart';
import '../../controller/feedback_controller.dart';
import '../../services/feedback_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_inputs.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';
import '../common_components/state_views.dart';

class FeedbackScreen extends GetView<FeedbackController> {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: DetailAppBar(title: 'about_feedback'.tr),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              Image.asset(AppAssets.feedback, height: 110, fit: BoxFit.contain),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'feedback_title'.tr,
                textAlign: TextAlign.center,
                style: AppTypography.headingS.copyWith(color: c.textPrimary),
              ),
              Text(
                'feedback_desc'.trParams({'args1': AppConfig.supportEmail}),
                textAlign: TextAlign.center,
                style: AppTypography.bodyM.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'feedback_type'.tr,
                style: AppTypography.label.copyWith(color: c.textSecondary),
              ),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final t in FeedbackType.values)
                    AppChip(
                      label: t.labelKey.tr,
                      selected: controller.type.value == t,
                      onTap: () => controller.type.value = t,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextArea(
                controller: controller.content,
                label: 'feedback_content'.tr,
                hint: 'feedback_content_hint'.tr,
                error: controller.contentError.value,
                maxLength: FeedbackController.maxLength,
                onChanged: (_) => controller.contentError.value = null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: controller.email,
                label: 'feedback_email'.tr,
                hint: 'feedback_email_hint'.tr,
                error: controller.emailError.value,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => controller.emailError.value = null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: c.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'feedback_privacy_note'.tr,
                      style: AppTypography.caption.copyWith(color: c.textMuted),
                    ),
                  ),
                ],
              ),
              if (controller.noEmailApp.value) ...[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  message: 'feedback_no_email_app'.trParams({
                    'args1': AppConfig.supportEmail,
                  }),
                  actionLabel: 'action_copy'.tr,
                  onAction: () async {
                    await FeedbackService.copySupportEmail();
                    ToastUtils.success('toast_copied'.tr);
                  },
                ),
              ],
              if (controller.opened.value) ...[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  icon: Icons.mark_email_unread_rounded,
                  color: c.info,
                  message: 'feedback_composer_opened'.tr,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'feedback_send'.tr,
                icon: Icons.send_rounded,
                onPressed: controller.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
