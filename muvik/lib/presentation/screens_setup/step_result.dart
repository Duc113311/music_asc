import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/setup_controller.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_button.dart';
import 'setup_screen.dart';

/// sc_step_03: real totals; "Bắt đầu nghe" never autoplays. Zero songs offers
/// Choose again / Rescan / Enter app (P06-13, P06-14).
class StepResult extends GetView<SetupController> {
  const StepResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lib = controller.library;
      final songs = lib.availableCount;
      final empty = songs == 0;
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.md,
              ),
              children: [
                Image.asset(AppAssets.step3, height: 200, fit: BoxFit.contain),
                const SizedBox(height: AppSpacing.md),
                SetupTitle(
                  title: empty ? 'step3_empty_title'.tr : 'step3_title'.tr,
                  highlight: empty ? '' : 'step3_highlight'.tr,
                  description: empty ? 'step3_empty_desc'.tr : 'step3_desc'.tr,
                ),
                const SizedBox(height: AppSpacing.xl),
                // Rows size to their content; a fixed-ratio grid overflowed
                // on narrow screens and with larger system fonts.
                _CountRow(
                  children: [
                    _Count(
                      icon: Icons.music_note_rounded,
                      value: songs,
                      label: 'count_songs'.tr,
                    ),
                    _Count(
                      icon: Icons.album_rounded,
                      value: lib.albums.length,
                      label: 'count_albums'.tr,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _CountRow(
                  children: [
                    _Count(
                      icon: Icons.person_rounded,
                      value: lib.artists.length,
                      label: 'count_artists'.tr,
                    ),
                    _Count(
                      icon: Icons.folder_rounded,
                      value: lib.folders.length,
                      label: 'count_folders'.tr,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              AppSpacing.lg,
            ),
            child: empty
                ? Column(
                    children: [
                      PrimaryButton(
                        label: 'action_choose_folders_again'.tr,
                        onPressed: () async => controller.chooseAgain(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      PrimaryButton(
                        label: 'action_rescan'.tr,
                        variant: ButtonVariant.secondary,
                        onPressed: controller.rescan,
                      ),
                      PrimaryButton(
                        label: 'action_enter_app'.tr,
                        variant: ButtonVariant.tertiary,
                        onPressed: controller.finish,
                      ),
                    ],
                  )
                : PrimaryButton(
                    label: 'step3_start'.tr,
                    variant: ButtonVariant.gradient,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: controller.finish,
                  ),
          ),
        ],
      );
    });
  }
}

/// Two equal-width, equal-height tiles.
class _CountRow extends StatelessWidget {
  const _CountRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: children[1]),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c.primary),
            const SizedBox(height: AppSpacing.xxs),
            FittedBox(
              child: Text(
                '$value',
                style: AppTypography.statNumber.copyWith(color: c.textPrimary),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
