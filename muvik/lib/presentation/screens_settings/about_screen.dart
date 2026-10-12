import '../../values/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../configs/app_config.dart';
import '../../services/feedback_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import 'settings_detail_widgets.dart';

/// sc_gioi_thieu: name, real version from the install, policy, licenses and
/// the entry point to Feedback (P14-15).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    return DetailScaffold(
      title: 'settings_about'.tr,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 26, 15, 24),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(AppAssets.logo, width: 96, height: 96),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConfig.appName,
            textAlign: TextAlign.center,
            style: AppTypography.display.copyWith(
              fontSize: 46,
              height: 1.2,
              color: p.text,
            ),
          ),
          Text(
            'about_tagline'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(
              fontSize: 16,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => Text(
              snap.data == null
                  ? ''
                  : 'about_version'.trParams({'args1': snap.data!.version}),
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(
                fontSize: 13.5,
                color: p.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'about_offline_player'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          DetailCard(
            children: [
              _Row(
                icon: Icons.music_note_outlined,
                title: 'settings_permissions'.tr,
                onTap: () => Get.toNamed(RouteName.permissions),
              ),
              _Row(
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
              _Row(
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
              _Row(
                icon: Icons.sms_outlined,
                title: 'about_feedback'.tr,
                onTap: () => Get.toNamed(RouteName.feedback),
              ),
            ],
          ),
          const SizedBox(height: 23),
          Divider(height: 1, thickness: 1, color: p.border),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: DetailNote(
              'about_local_note'.tr,
              color: Color.lerp(p.textSecondary, c.primary, 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56.5,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, size: 23, color: c.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyL.copyWith(
                    fontSize: 14,
                    color: p.text,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: p.textSecondary,
              ),
              const SizedBox(width: 9),
            ],
          ),
        ),
      ),
    );
  }
}
