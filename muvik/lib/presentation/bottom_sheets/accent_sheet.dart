import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';

/// "Màu nhấn": preview, then Save. Closing before saving drops the draft
/// (spec §8.4). onPrimary is recomputed per accent for contrast (P14-13).
Future<void> showAccentSheet() =>
    showAppSheet<void>(builder: (_) => const _AccentSheet());

class _AccentSheet extends StatefulWidget {
  const _AccentSheet();
  @override
  State<_AccentSheet> createState() => _AccentSheetState();
}

class _AccentSheetState extends State<_AccentSheet> {
  late AccentColor _draft = SettingsController.to.accent.value;

  @override
  Widget build(BuildContext context) {
    final base = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final preview = dark ? AppColors.dark(_draft) : AppColors.light(_draft);
    return SheetScaffold(
      title: 'settings_accent'.tr,
      subtitle: 'accent_desc'.tr,
      footer: PrimaryButton(
        label: 'action_save'.tr,
        onPressed: () async {
          await SettingsController.to.setAccent(_draft);
          Get.back<void>();
        },
      ),
      child: Column(
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: [
              for (final a in AccentColor.values)
                Semantics(
                  button: true,
                  selected: a == _draft,
                  label: a.labelKey.tr,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _draft = a),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: AppMotion.state,
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: a == _draft
                                  ? base.textPrimary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: dark ? a.dark : a.light,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.labelKey.tr,
                          style: AppTypography.caption.copyWith(
                            color: base.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Live preview of controls in the draft accent.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: base.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: base.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: preview.primary,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: preview.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'accent_preview'.tr,
                        style: AppTypography.label.copyWith(
                          color: base.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: 0.45,
                          minHeight: 4,
                          color: preview.primary,
                          backgroundColor: base.border,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.favorite_rounded, color: preview.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
