import 'package:asc_common/asc_common.dart' show AscLocale, LanguageNames;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../controller/playback_controller.dart';
import '../../controller/settings_controller.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/app_localize.dart';
import '../../utils/legal_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/accent_sheet.dart';
import '../common_components/mini_player.dart';
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
    final c = context.colors;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              const _Header(),
              _Group(
                title: 'settings_group_utilities'.tr,
                children: [
                  _Row(
                    icon: const _FolderSyncIcon(),
                    title: 'settings_scan'.tr,
                    subtitle: 'settings_scan_desc'.tr,
                    onTap: () => Get.toNamed(RouteName.scanLibrary),
                  ),
                  Obx(
                    () => _Row(
                      icon: const _GradientIcon(Icons.sync_rounded),
                      title: 'settings_auto_scan'.tr,
                      subtitle: 'settings_auto_scan_desc'.tr,
                      chevron: false,
                      trailing: Switch(
                        value: settings.autoScanNewMusic.value,
                        onChanged: settings.setAutoScanNewMusic,
                      ),
                      onTap: () => settings.setAutoScanNewMusic(
                        !settings.autoScanNewMusic.value,
                      ),
                    ),
                  ),
                  Obx(() {
                    final st = pc.sleep.value;
                    return _Row(
                      icon: const _GradientIcon(Icons.schedule_rounded),
                      title: 'settings_sleep_timer'.tr,
                      subtitle: 'settings_sleep_timer_desc'.tr,
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
              _Group(
                title: 'settings_group_audio'.tr,
                children: [
                  Obx(() {
                    final eq = pc.eq.value;
                    return _Row(
                      // Vertical sliders, as in the mockup.
                      icon: const RotatedBox(
                        quarterTurns: 1,
                        child: _GradientIcon(
                          Icons.tune_rounded,
                          horizontal: true,
                        ),
                      ),
                      title: 'settings_equalizer'.tr,
                      subtitle: 'settings_equalizer_desc'.tr,
                      value:
                          eq.enabled ? eq.preset.labelKey.tr : 'value_off'.tr,
                      onTap: () => Get.toNamed(RouteName.equalizer),
                    );
                  }),
                  _Row(
                    icon: const _GradientIcon(Icons.graphic_eq_rounded),
                    title: 'settings_quality'.tr,
                    subtitle: 'settings_quality_desc'.tr,
                    value: 'quality_original'.tr,
                    onTap: () => Get.toNamed(RouteName.playbackQuality),
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.headphones_outlined),
                    title: 'settings_headphones'.tr,
                    subtitle: 'settings_headphones_desc'.tr,
                    onTap: () => Get.toNamed(RouteName.headphones),
                  ),
                ],
              ),
              _Group(
                title: 'settings_group_appearance'.tr,
                children: [
                  Obx(
                    () => _Row(
                      icon: const _GradientIcon(Icons.dark_mode_outlined),
                      title: 'settings_theme'.tr,
                      subtitle: 'settings_theme_desc'.tr,
                      value: settings.themeLabelKey.tr,
                      onTap: () => Get.toNamed(RouteName.theme),
                    ),
                  ),
                  Obx(
                    () => _Row(
                      icon: const _GradientIcon(Icons.palette_outlined),
                      title: 'settings_accent'.tr,
                      subtitle: 'settings_accent_desc'.tr,
                      // sc_cat_dat shows only the swatch; the name stays
                      // for screen readers.
                      trailing: Semantics(
                        label: settings.accent.value.labelKey.tr,
                        child: Container(
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      onTap: showAccentSheet,
                    ),
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.language_rounded),
                    title: 'settings_language'.tr,
                    subtitle: 'settings_language_desc'.tr,
                    value: LanguageNames.nativeName(
                      AppLocalize.resolve(AscLocale.getAppLocale()),
                    ),
                    onTap: () =>
                        Get.toNamed(RouteName.language, arguments: true),
                  ),
                ],
              ),
              _Group(
                title: 'settings_group_app'.tr,
                children: [
                  Obx(
                    () => _Row(
                      icon: const _GradientIcon(Icons.notifications_outlined),
                      title: 'settings_nudge'.tr,
                      subtitle: 'settings_nudge_desc'.tr,
                      chevron: false,
                      trailing: Switch(
                        value: settings.nudgeEnabled.value,
                        onChanged: settings.setNudgeEnabled,
                      ),
                      onTap: () => settings.setNudgeEnabled(
                        !settings.nudgeEnabled.value,
                      ),
                    ),
                  ),
                  Obx(
                    () => _Row(
                      icon: const _GradientIcon(Icons.music_note_rounded),
                      title: 'settings_ongoing'.tr,
                      subtitle: 'settings_ongoing_desc'.tr,
                      chevron: false,
                      trailing: Switch(
                        value: settings.ongoingNotification.value,
                        onChanged: settings.setOngoingNotification,
                      ),
                      onTap: () => settings.setOngoingNotification(
                        !settings.ongoingNotification.value,
                      ),
                    ),
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.shield_outlined),
                    title: 'settings_permissions'.tr,
                    subtitle: 'settings_permissions_desc'.tr,
                    onTap: () => Get.toNamed(RouteName.permissions),
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.star_outline_rounded),
                    title: 'settings_rate'.tr,
                    subtitle: 'settings_rate_desc'.tr,
                    onTap: showRateAppDialog,
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.privacy_tip_outlined),
                    title: 'about_privacy'.tr,
                    subtitle: 'settings_privacy_desc'.tr,
                    onTap: LegalUtils.openPrivacyPolicy,
                  ),
                  if (kDebugMode)
                    _Row(
                      icon: const _GradientIcon(Icons.widgets_outlined),
                      title: 'Component preview (debug)',
                      onTap: () => Get.toNamed(RouteName.componentPreview),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) => snap.data == null
                      ? const SizedBox.shrink()
                      : Text(
                          'about_version'
                              .trParams({'args1': snap.data!.version}),
                          style: AppTypography.caption.copyWith(
                            fontSize: 12.5,
                            color: c.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const MiniPlayerSpacer(extra: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card colors of sc_cat_dat over the wave background (dark); the light
/// theme keeps the regular surface tokens.
class _CardStyle {
  _CardStyle(BuildContext context)
      : dark = Theme.of(context).brightness == Brightness.dark,
        _c = context.colors;

  final bool dark;
  final AppColors _c;

  Color get fill => dark ? const Color(0xD90B1B45) : _c.surface;
  Color get border => dark ? const Color(0xFF222D7D) : _c.border;
  Color get divider => dark ? const Color(0xFF1D366C) : _c.divider;

  ShapeBorder get shape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      );

  BoxDecoration get decoration => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      );
}

/// Icon tinted top-to-bottom from the accent to sky blue.
class _GradientIcon extends StatelessWidget {
  const _GradientIcon(this.icon, {this.horizontal = false});
  final IconData icon;

  /// For icons shown rotated a quarter turn, so the gradient still runs
  /// top-to-bottom on screen.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(
        begin: horizontal ? Alignment.centerRight : Alignment.topCenter,
        end: horizontal ? Alignment.centerLeft : Alignment.bottomCenter,
        colors: [c.primary, const Color(0xFF86A2FB)],
      ).createShader(r),
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }
}

/// Folder with a small sync badge (no single Material glyph for it).
class _FolderSyncIcon extends StatelessWidget {
  const _FolderSyncIcon();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _GradientIcon(Icons.folder_outlined),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              decoration: BoxDecoration(
                color: _CardStyle(context).fill.withValues(alpha: 1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(1),
              child: Icon(Icons.sync_rounded, size: 13, color: c.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 14, 7, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'tab_settings'.tr,
              style: AppTypography.display.copyWith(
                fontSize: 33,
                height: 1.25,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'settings_subtitle'.tr,
            style: AppTypography.bodyL.copyWith(
              fontSize: 14.5,
              height: 1.4,
              color: c.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase accent title + card with full-width dividers between rows.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = _CardStyle(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: AppTypography.label.copyWith(
                fontSize: 12.5,
                height: 1.25,
                letterSpacing: 0.5,
                color: c.primaryLight,
              ),
            ),
          ),
        ),
        // Material (not a decorated Container) so the rows' ripples show.
        Material(
          color: style.fill,
          shape: style.shape,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 68,
                    endIndent: 0,
                    color: style.divider,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact settings row: icon, title, optional accent value/trailing, chevron.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = true,
  });

  final bool chevron;
  final Widget icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 66),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: c.primary.withValues(alpha: 0.25)),
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyL.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 12.5,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: c.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTypography.bodyM.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.primaryLight,
                        ),
                      ),
                    ),
                  ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: trailing,
                  ),
                const SizedBox(width: 2),
                if (chevron)
                  Icon(Icons.chevron_right_rounded, size: 24, color: c.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

