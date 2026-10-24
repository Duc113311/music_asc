import 'package:asc_common/asc_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/language_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';

/// Language picker: first-run screen after the splash, and the "Ngôn ngữ"
/// screen of Settings (same list, no Continue button there).
class LanguageScreen extends GetView<LanguageController> {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fromSettings = controller.fromSettings;
    return Scaffold(
      appBar: fromSettings
          ? DetailAppBar(title: 'settings_language'.tr)
          : null,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!fromSettings) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'language_title'.tr,
                    style: AppTypography.headingL.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ] else
                  const SizedBox(height: AppSpacing.sm),
                Text(
                  'language_subtitle'.tr,
                  style: AppTypography.bodyL.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Obx(() {
                    // Read here, not in itemBuilder: the builder runs lazily,
                    // outside the scope Obx watches.
                    final current = controller.selected.value;
                    return ListView.separated(
                      itemCount: controller.languages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final l = controller.languages[i];
                        final on = l == current;
                        return Semantics(
                          selected: on,
                          button: true,
                          label: LanguageNames.nativeName(l),
                          excludeSemantics: true,
                          child: AppCard(
                            selected: on,
                            onTap: () => controller.select(l),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LanguageNames.nativeName(l),
                                        style: AppTypography.headingS.copyWith(
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        LanguageNames.englishName(l),
                                        style: AppTypography.bodyM.copyWith(
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: AppMotion.state,
                                  child: on
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          key: const ValueKey('on'),
                                          color: c.primary,
                                        )
                                      : Icon(
                                          Icons.circle_outlined,
                                          key: const ValueKey('off'),
                                          color: c.iconDefault,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                if (!fromSettings) ...[
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'action_continue'.tr,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: controller.confirm,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
