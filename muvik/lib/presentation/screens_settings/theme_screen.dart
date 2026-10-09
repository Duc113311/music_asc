import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/cards.dart';

/// sc_theme "Giao diện": theme, accent, player background and screen
/// transitions. Every choice applies immediately and is saved; the player is
/// not restarted (P14-12).
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_group_appearance'.tr),
      body: SafeArea(
        child: Obx(() {
          // With "system" the radios mirror what is on screen right now;
          // picking one stores an explicit mode.
          final dark = switch (s.themeMode.value) {
            ThemeMode.dark => true,
            ThemeMode.light => false,
            ThemeMode.system =>
              MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          };
          final accent = s.accent.value;
          final blur = s.playerBlurBackground.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              _Section(
                title: 'theme_section_title'.tr,
                subtitle: 'theme_desc'.tr,
                bottomPadding: 18,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 17, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ThemeOption(
                          dark: true,
                          accent: accent,
                          label: 'theme_dark'.tr,
                          selected: dark,
                          onTap: () => s.setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeOption(
                          dark: false,
                          accent: accent,
                          label: 'theme_light'.tr,
                          selected: !dark,
                          onTap: () => s.setThemeMode(ThemeMode.light),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'settings_accent'.tr,
                subtitle: 'accent_desc'.tr,
                bottomPadding: 20,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final a in AccentColor.values)
                        Expanded(
                          child: _Swatch(
                            accent: a,
                            selected: a == accent,
                            onTap: () => s.setAccent(a),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'player_bg_title'.tr,
                subtitle: 'player_bg_desc'.tr,
                bottomPadding: 10,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      _RadioOption(
                        title: 'player_bg_blur'.tr,
                        subtitle: 'player_bg_blur_desc'.tr,
                        selected: blur,
                        onTap: () => s.setPlayerBlurBackground(true),
                      ),
                      _RadioOption(
                        title: 'player_bg_solid'.tr,
                        subtitle: 'player_bg_solid_desc'.tr,
                        selected: !blur,
                        onTap: () => s.setPlayerBlurBackground(false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'transitions_title'.tr,
                subtitle: 'transitions_desc'.tr,
                bottomPadding: 18,
                trailing: AppSwitch(
                  value: s.screenTransitions.value,
                  semanticLabel: 'transitions_title'.tr,
                  onChanged: s.setScreenTransitions,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Card with a title + subtitle header; [trailing] sits beside the header.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    this.child,
    this.trailing,
    this.bottomPadding = 18,
  });

  final String title;
  final String subtitle;
  final Widget? child;
  final Widget? trailing;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTypography.headingS.copyWith(
              fontSize: 15.5,
              height: 1.35,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTypography.bodyM.copyWith(
            fontSize: 11.5,
            height: 1.4,
            color: c.textSecondary,
          ),
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      padding: EdgeInsets.only(top: 17, bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 17,
              right: trailing == null ? 17 : 8,
            ),
            child: trailing == null
                ? header
                : Row(
                    children: [
                      Expanded(child: header),
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// One theme choice: a mini player mockup, then radio + label.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.dark,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool dark;
  final AccentColor accent;
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
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.state,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? accent.dark.withValues(alpha: 0.10)
                    : Colors.transparent,
                border: Border.all(
                  color: selected ? c.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 155.6 / 163,
                child: _PlayerMockup(dark: dark, accent: accent.dark),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppRadio(selected: selected, size: 20),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyL.copyWith(
                      fontSize: 12.5,
                      color: c.textPrimary,
                    ),
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

/// Static Now Playing mockup in a fixed dark or light palette, drawn on a
/// 155.6×163 design box and scaled to the available width.
class _PlayerMockup extends StatelessWidget {
  const _PlayerMockup({required this.dark, required this.accent});
  final bool dark;
  final Color accent;

  static const _w = 155.6;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0D1018) : const Color(0xFFF8F6F5);
    final fg = dark ? const Color(0xFFF5F6FC) : const Color(0xFF1E1E2A);
    final icon = dark ? const Color(0xFFE6E7EE) : const Color(0xFF2A2A3A);
    final line = dark ? const Color(0xFF4D5161) : const Color(0xFFCFCDD2);
    final lineHi = dark ? const Color(0xFF797B8D) : const Color(0xFFCFCDD2);
    final track = dark ? const Color(0xFF383B4C) : const Color(0xFFEAE8EF);
    return LayoutBuilder(
      builder: (context, box) {
        final k = box.maxWidth / _w;
        Widget at(double left, double centerY, double size, Widget child) =>
            Positioned(
              left: (left - size / 2) * k,
              top: (centerY - size / 2) * k,
              width: size * k,
              height: size * k,
              child: child,
            );
        Widget bar(double left, double centerY, double w, Color color) =>
            Positioned(
              left: left * k,
              top: (centerY - 2.5) * k,
              width: w * k,
              height: 5 * k,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3 * k),
                ),
              ),
            );
        Icon ic(IconData d, double size) =>
            Icon(d, size: size * k, color: icon);
        return ExcludeSemantics(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10 * k),
              boxShadow: dark
                  ? null
                  : const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 15.6 * k,
                  top: 11 * k,
                  child: Text(
                    'Melo',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5 * k,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                at(118, 19.8, 15, ic(Icons.search_rounded, 15)),
                at(139.1, 19.8, 15, ic(Icons.more_vert_rounded, 15)),
                Positioned(
                  left: 12.6 * k,
                  top: 38 * k,
                  width: 60 * k,
                  height: 60 * k,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5 * k),
                    child: Image.asset(AppAssets.themeCover, fit: BoxFit.cover),
                  ),
                ),
                bar(82.2, 56.9, 52.3, lineHi),
                bar(82.2, 70.4, 39.6, line),
                bar(82.2, 82.6, 44.7, line),
                // Seek bar: track, played part, thumb.
                Positioned(
                  left: 12.6 * k,
                  top: (113.4 - 1.25) * k,
                  width: 131.6 * k,
                  height: 2.5 * k,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(2 * k),
                    ),
                  ),
                ),
                Positioned(
                  left: 12.6 * k,
                  top: (113.4 - 1.25) * k,
                  width: 45.6 * k,
                  height: 2.5 * k,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2 * k),
                    ),
                  ),
                ),
                at(
                  58.2,
                  113.4,
                  6,
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                at(18.5, 137.9, 16, ic(Icons.shuffle_rounded, 16)),
                at(47.6, 137.9, 19, ic(Icons.skip_previous_rounded, 19)),
                at(
                  79.3,
                  137.9,
                  28,
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 20 * k,
                      color: Colors.white,
                    ),
                  ),
                ),
                at(110.5, 137.9, 19, ic(Icons.skip_next_rounded, 19)),
                at(
                  138.3,
                  137.9,
                  17,
                  ic(Icons.format_list_bulleted_rounded, 17),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Accent circle (40) with a ring around the selected one, and its name.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AccentColor accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = Theme.of(context).brightness == Brightness.dark
        ? accent.dark
        : accent.light;
    return Semantics(
      button: true,
      selected: selected,
      label: accent.labelKey.tr,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.state,
              width: 49,
              height: 49,
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              accent.labelKey.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio row with title + description (player background choices).
class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(31 - 14, 8, 17, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: AppRadio(selected: selected, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 13.5,
                        height: 1.5,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodyM.copyWith(
                        fontSize: 11.5,
                        height: 1.4,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
