import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../controller/auth_controller.dart';
import '../../controller/playback_controller.dart';
import '../../controller/settings_controller.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/accent_sheet.dart';
import '../common_components/mini_player.dart';
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
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: c.background,
            child: Image.asset(
              dark ? AppAssets.bgDark : AppAssets.bgLight,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              // The mockup shows the waves dimmed behind the content.
              color: dark ? const Color(0x73040B22) : null,
              colorBlendMode: dark ? BlendMode.srcATop : null,
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            children: [
              const _Header(),
              const SizedBox(height: 10),
              const _AccountCard(),
              _Group(
                title: 'settings_group_utilities'.tr,
                children: [
                  _Row(
                    icon: const _FolderSyncIcon(),
                    title: 'settings_scan'.tr,
                    onTap: () => Get.toNamed(RouteName.scanLibrary),
                  ),
                  Obx(() {
                    final st = pc.sleep.value;
                    return _Row(
                      icon: const _GradientIcon(Icons.schedule_rounded),
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
                      value: eq.enabled
                          ? eq.preset.labelKey.tr
                          : 'value_off'.tr,
                      onTap: () => Get.toNamed(RouteName.equalizer),
                    );
                  }),
                  _Row(
                    icon: const _GradientIcon(Icons.graphic_eq_rounded),
                    title: 'settings_quality'.tr,
                    value: 'quality_original'.tr,
                    onTap: () => Get.toNamed(RouteName.playbackQuality),
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.headphones_outlined),
                    title: 'settings_headphones'.tr,
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
                      value: settings.themeLabelKey.tr,
                      onTap: () => Get.toNamed(RouteName.theme),
                    ),
                  ),
                  Obx(
                    () => _Row(
                      icon: const _GradientIcon(Icons.palette_outlined),
                      title: 'settings_accent'.tr,
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
                ],
              ),
              _Group(
                title: 'settings_group_app'.tr,
                children: [
                  _Row(
                    icon: const _GradientIcon(Icons.shield_outlined),
                    title: 'settings_permissions'.tr,
                    onTap: () => Get.toNamed(RouteName.permissions),
                  ),
                  _Row(
                    icon: const _GradientIcon(Icons.star_outline_rounded),
                    title: 'settings_rate'.tr,
                    onTap: showRateAppDialog,
                  ),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snap) => _Row(
                      icon: const _GradientIcon(Icons.info_outline_rounded),
                      title: 'settings_about'.tr,
                      value: snap.data == null
                          ? null
                          : 'v${snap.data!.version}',
                      onTap: () => Get.toNamed(RouteName.about),
                    ),
                  ),
                  if (kDebugMode)
                    _Row(
                      icon: const _GradientIcon(Icons.widgets_outlined),
                      title: 'Component preview (debug)',
                      onTap: () => Get.toNamed(RouteName.componentPreview),
                    ),
                ],
              ),
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

  BoxDecoration get decoration => BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(12),
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
              color: c.primary,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 3),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: AppTypography.label.copyWith(
                fontSize: 12.5,
                height: 1.25,
                letterSpacing: 0.5,
                color: c.primary,
              ),
            ),
          ),
        ),
        Container(
          decoration: style.decoration,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 12,
                    endIndent: 12,
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
    this.value,
    this.trailing,
    this.onTap,
  });

  final Widget icon;
  final String title;
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
          constraints: const BoxConstraints(minHeight: 37),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyL.copyWith(
                      fontSize: 13.5,
                      height: 1.35,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (value != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTypography.bodyM.copyWith(
                          fontSize: 12,
                          color: c.primary,
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
                Icon(Icons.chevron_right_rounded, size: 24, color: c.primary),
              ],
            ),
          ),
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
    return Container(
      decoration: _CardStyle(context).decoration,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
      child: Obx(() {
        final u = auth.user.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 4),
                _Avatar(url: u?.photoUrl),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u?.displayName ??
                            (u == null ? 'account_title'.tr : u.email),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyL.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u?.email ?? 'account_desc'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyM.copyWith(
                          fontSize: 12,
                          height: 1.4,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (u == null) ...[
              _PillButton(
                label: 'account_google_sign_in'.tr,
                leading: const _GoogleLogo(size: 17),
                loading: auth.busy.value,
                onTap: auth.signIn,
              ),
              const SizedBox(height: 8),
              Text(
                'account_optional'.tr,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  fontSize: 10.5,
                  color: c.primary,
                ),
              ),
            ] else
              _PillButton(
                label: 'account_sign_out'.tr,
                leading: const Icon(
                  Icons.logout_rounded,
                  size: 17,
                  color: Color(0xFF141455),
                ),
                onTap: () => confirmLogout(auth.signOut),
              ),
          ],
        );
      }),
    );
  }
}

/// White rounded button of the account card (Google sign-in / sign-out).
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.leading,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final Widget leading;
  final Future<void> Function() onTap;
  final bool loading;

  static const _fg = Color(0xFF141455);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFF3F6FD),
        // Outlined on the light theme, where the card is white too.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: Theme.of(context).brightness == Brightness.dark
              ? BorderSide.none
              : BorderSide(color: context.colors.border),
        ),
        child: InkWell(
          // Ignore taps while signing in (double-submit guard, P15-03).
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _fg,
                    ),
                  )
                else
                  leading,
                const SizedBox(width: 18),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontSize: 12.5,
                      color: _fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Four-color Google "G" mark drawn with arcs (no bitmap asset needed).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint p(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = 3.1415926535 / 180;
    // Angles clockwise from 3 o'clock.
    canvas.drawArc(
      rect,
      -45 * deg,
      -100 * deg,
      false,
      p(const Color(0xFFEA4335)),
    );
    canvas.drawArc(
      rect,
      -145 * deg,
      -80 * deg,
      false,
      p(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      135 * deg,
      -90 * deg,
      false,
      p(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      45 * deg,
      -45 * deg,
      false,
      p(const Color(0xFF4285F4)),
    );
    // Blue crossbar.
    canvas.drawRect(
      Rect.fromLTWH(s * 0.5, s * 0.5 - stroke / 2, s * 0.5, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gradient ring with a person outline, or the network photo (P15-04).
class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [c.primary, const Color(0xFF52C7FD)],
    );
    final fallback = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: gradient.createShader,
      child: const Icon(
        Icons.person_outline_rounded,
        size: 38,
        color: Colors.white,
      ),
    );
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _CardStyle(context).fill.withValues(alpha: 1),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: url == null
            ? fallback
            : Image.network(
                url!,
                width: 41,
                height: 41,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
