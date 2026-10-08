import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../bottom_sheets/accent_sheet.dart';
import '../common_components/app_controls.dart';
import '../common_components/cards.dart';

/// sc_theme: Light / Dark / System applied immediately and saved; the player
/// is not restarted (P14-12).
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = SettingsController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_theme'.tr),
      body: SafeArea(
        child: Obx(() {
          final mode = s.themeMode.value;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              Text(
                'theme_desc'.tr,
                style: AppTypography.bodyL.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Preview(
                      asset: AppAssets.bgDark,
                      label: 'theme_dark'.tr,
                      selected: mode == ThemeMode.dark,
                      onTap: () => s.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Preview(
                      asset: AppAssets.bgLight,
                      label: 'theme_light'.tr,
                      selected: mode == ThemeMode.light,
                      onTap: () => s.setThemeMode(ThemeMode.light),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: SelectableOptionTile(
                  title: 'theme_system'.tr,
                  subtitle: 'theme_system_desc'.tr,
                  selected: mode == ThemeMode.system,
                  onTap: () => s.setThemeMode(ThemeMode.system),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  icon: Icons.palette_rounded,
                  title: 'settings_accent'.tr,
                  value: s.accent.value.labelKey.tr,
                  onTap: showAccentSheet,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.state,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: selected ? c.primary : c.border,
                  width: selected ? 2 : 1,
                ),
                image: DecorationImage(
                  image: AssetImage(asset),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: c.primary,
                  child: Icon(Icons.play_arrow_rounded, color: c.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppRadio(selected: selected),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyL.copyWith(color: c.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
