import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../controller/auth_controller.dart';
import '../../controller/playback_controller.dart';
import '../../controller/settings_controller.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/accent_sheet.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/primary_button.dart';
import '../dialogs/app_dialogs.dart';
import '../dialogs/rate_app_dialog.dart';

/// sc_cat_dat: account + Tiện ích / Âm thanh / Giao diện / Ứng dụng only
/// (spec §1.4, P14-01). Every row leads to a real feature.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.to;
    final pc = PlaybackController.to;
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          controller: scrollController,
          children: [
            PageHeader(
              title: 'tab_settings'.tr,
              subtitle: 'settings_subtitle'.tr,
            ),
            const _AccountCard(),
            SettingsGroup(
              title: 'settings_group_utilities'.tr,
              children: [
                SettingsTile(
                  icon: Icons.folder_copy_rounded,
                  title: 'settings_scan'.tr,
                  onTap: () => Get.toNamed(RouteName.scanLibrary),
                ),
                Obx(() {
                  final st = pc.sleep.value;
                  return SettingsTile(
                    icon: Icons.timer_outlined,
                    title: 'settings_sleep_timer'.tr,
                    value: st.waitingForTrackEnd
                        ? 'sleep_waiting_track_short'.tr
                        : (st.deadline == null
                              ? 'value_off'.tr
                              : DurationFormatter.clock(
                                  st.remaining(DateTime.now()),
                                )),
                    onTap: () => Get.toNamed(RouteName.sleepTimer),
                  );
                }),
              ],
            ),
            SettingsGroup(
              title: 'settings_group_audio'.tr,
              children: [
                Obx(() {
                  final eq = pc.eq.value;
                  return SettingsTile(
                    icon: Icons.tune_rounded,
                    title: 'settings_equalizer'.tr,
                    value: eq.enabled ? eq.preset.labelKey.tr : 'value_off'.tr,
                    onTap: () => Get.toNamed(RouteName.equalizer),
                  );
                }),
                SettingsTile(
                  icon: Icons.graphic_eq_rounded,
                  title: 'settings_quality'.tr,
                  value: 'quality_original'.tr,
                  onTap: () => Get.toNamed(RouteName.playbackQuality),
                ),
                SettingsTile(
                  icon: Icons.headphones_rounded,
                  title: 'settings_headphones'.tr,
                  onTap: () => Get.toNamed(RouteName.headphones),
                ),
              ],
            ),
            SettingsGroup(
              title: 'settings_group_appearance'.tr,
              children: [
                Obx(
                  () => SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'settings_theme'.tr,
                    value: settings.themeLabelKey.tr,
                    onTap: () => Get.toNamed(RouteName.theme),
                  ),
                ),
                Obx(
                  () => SettingsTile(
                    icon: Icons.palette_rounded,
                    title: 'settings_accent'.tr,
                    // sc_cat_dat shows only the swatch; the name stays for
                    // screen readers.
                    trailing: Semantics(
                      label: settings.accent.value.labelKey.tr,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: context.colors.primary,
                        ),
                      ),
                    ),
                    onTap: showAccentSheet,
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'settings_group_app'.tr,
              children: [
                SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'settings_permissions'.tr,
                  onTap: () => Get.toNamed(RouteName.permissions),
                ),
                SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'settings_rate'.tr,
                  onTap: showRateAppDialog,
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) => SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'settings_about'.tr,
                    value: snap.data == null ? null : 'v${snap.data!.version}',
                    onTap: () => Get.toNamed(RouteName.about),
                  ),
                ),
                if (kDebugMode)
                  SettingsTile(
                    icon: Icons.widgets_outlined,
                    title: 'Component preview (debug)',
                    onTap: () => Get.toNamed(RouteName.componentPreview),
                  ),
              ],
            ),
            const MiniPlayerSpacer(extra: 8),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = AuthController.to;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        0,
      ),
      child: AppCard(
        child: Obx(() {
          final u = auth.user.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Avatar(url: u?.photoUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u?.displayName ??
                              (u == null ? 'account_title'.tr : u.email),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          u?.email ?? 'account_desc'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyM.copyWith(color: c.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (u == null) ...[
                PrimaryButton(
                  label: 'account_google_sign_in'.tr,
                  icon: Icons.login_rounded,
                  variant: ButtonVariant.secondary,
                  loading: auth.busy.value,
                  onPressed: auth.signIn,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'account_optional'.tr,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ] else
                PrimaryButton(
                  label: 'account_sign_out'.tr,
                  icon: Icons.logout_rounded,
                  variant: ButtonVariant.secondary,
                  onPressed: () async => confirmLogout(auth.signOut),
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Network avatar with offline/error fallback (P15-04).
class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = CircleAvatar(
      radius: 28,
      backgroundColor: c.surfaceSelected,
      child: Icon(Icons.person_rounded, color: c.primary, size: 30),
    );
    if (url == null) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
