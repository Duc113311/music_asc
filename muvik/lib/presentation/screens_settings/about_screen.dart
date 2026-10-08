import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../configs/app_config.dart';
import '../../services/feedback_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/cards.dart';

/// sc_gioi_thieu: name, real version/build from the install, policy,
/// licenses and the entry point to Feedback (P14-15).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_about'.tr),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(AppAssets.logo, width: 96, height: 96),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppConfig.appName,
              textAlign: TextAlign.center,
              style: AppTypography.headingL.copyWith(color: c.textPrimary),
            ),
            Text(
              'splash_tagline'.tr,
              textAlign: TextAlign.center,
              style: AppTypography.bodyL.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) => Text(
                snap.data == null
                    ? ''
                    : 'about_version'.trParams({
                        'args1': snap.data!.version,
                        'args2': snap.data!.buildNumber,
                      }),
                textAlign: TextAlign.center,
                style: AppTypography.bodyM.copyWith(color: c.textPrimary),
              ),
            ),
            Text(
              'about_offline_player'.tr,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsGroupCardLike(
              children: [
                SettingsTile(
                  icon: Icons.music_note_outlined,
                  title: 'settings_permissions'.tr,
                  onTap: () => Get.toNamed(RouteName.permissions),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'about_privacy'.tr,
                  onTap: () async {
                    final ok = await FeedbackService.openUrl(
                      AppConfig.privacyPolicyUrl,
                    );
                    if (!ok) {
                      ToastUtils.show(
                        'about_privacy_unavailable'.tr,
                        type: ToastType.warning,
                      );
                    }
                  },
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'about_licenses'.tr,
                  onTap: () async {
                    final info = await PackageInfo.fromPlatform();
                    showLicensePage(
                      context: Get.context!,
                      applicationName: AppConfig.appName,
                      applicationVersion: info.version,
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'about_feedback'.tr,
                  onTap: () => Get.toNamed(RouteName.feedback),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: c.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'about_local_note'.tr,
                    style: AppTypography.caption.copyWith(color: c.textMuted),
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

class SettingsGroupCardLike extends StatelessWidget {
  const SettingsGroupCardLike({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: 56, color: c.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}
