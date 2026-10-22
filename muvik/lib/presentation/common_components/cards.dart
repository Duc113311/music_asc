import 'package:flutter/material.dart';
import 'app_touchable.dart';
import 'package:get/get.dart';

import '../../models/data_models/song.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'song_artwork.dart';

/// Square cover card (width 160) for playlists/albums with an optional play
/// button. Name wraps to at most 2 lines.
class CoverCard extends StatelessWidget {
  const CoverCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.coverSong,
    this.onTap,
    this.onPlay,
    this.onMore,
    this.width = AppSizes.playlistCard,
    this.placeholderIcon,
  });

  final String title;
  final String subtitle;
  final Song? coverSong;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onMore;
  final double width;
  final IconData? placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: width,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, box) {
              final art = coverSong == null
                  ? ArtworkPlaceholder(
                      size: width,
                      icon: placeholderIcon ?? Icons.queue_music_rounded,
                    )
                  : SongArtwork(song: coverSong, size: width, radius: 0);
              final info = _info(c);
              if (!box.hasBoundedHeight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [art, info],
                );
              }
              // Fixed-height slot (horizontal list / grid cell): the cover
              // gives up height so long titles or large fonts never overflow.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRect(
                      child: FittedBox(fit: BoxFit.cover, child: art),
                    ),
                  ),
                  info,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _info(AppColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(color: c.textPrimary),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        if (onPlay != null)
          AppIconButton(
            icon: Icons.play_circle_fill_rounded,
            tooltip: 'action_play'.tr,
            size: 32,
            color: c.primary,
            onPressed: onPlay,
          ),
        if (onMore != null)
          AppIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: 'more_options'.tr,
            onPressed: onMore,
          ),
      ],
    ),
  );
}

/// Generic surface card with Design System padding/radius.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.selected = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: selected ? c.surfaceSelected : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: selected ? c.primary : c.border),
        boxShadow: [c.cardShadow],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section title with optional "Xem tất cả" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onMore,
    this.moreLabel,
    this.titleStyle,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      AppSpacing.groupGap,
      AppSpacing.xs,
      AppSpacing.sm,
    ),
  });

  final String title;
  final VoidCallback? onMore;
  final String? moreLabel;
  final EdgeInsets padding;

  /// Overrides the default heading size.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: (titleStyle ?? AppTypography.headingM).copyWith(
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          if (onMore != null)
            TextButton.icon(
              onPressed: onMore,
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: Icon(Icons.chevron_right_rounded, color: c.primary),
              label: Text(
                moreLabel ?? 'see_all'.tr,
                style: AppTypography.label.copyWith(color: c.primaryLight),
              ),
            ),
        ],
      ),
    );
  }
}

/// Large tab title ("Cài đặt", "Thư viện") + subtitle + trailing actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.headingL.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodyL.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Detail app bar: height 56, title 20 sp / 600, back button.
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBack,
    this.backgroundColor,
    this.titleStyle,
  });
  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final TextStyle? titleStyle;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBar);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor == null ? null : Colors.transparent,
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'action_back'.tr,
        color: c.textPrimary,
        onPressed: onBack ?? () => Get.back<void>(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
      actions: actions,
    );
  }
}

/// Settings row: min height 64, icon 24, padding 16.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.settingsTile),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(icon, color: c.primary, size: AppSizes.icon),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyL.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.bodyM.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Title takes the remaining width; the value hugs its text so
                // every chevron lines up on the right edge.
                if (value != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Text(
                        value!,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyM.copyWith(color: c.primaryLight),
                      ),
                    ),
                  ),
                ?trailing,
                if (showChevron && onTap != null)
                  Icon(Icons.chevron_right_rounded, color: c.iconDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Group of settings rows with an uppercase caption and dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                4,
                AppSpacing.groupGap,
                4,
                AppSpacing.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title!.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: c.primaryLight,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          // Material (not a decorated Container) so the rows' ripples show.
          Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: c.border),
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
          ),
        ],
      ),
    );
  }
}

/// Gradient background used by tab roots (Design System §1).
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  /// The shared wave background is painted once per route (AppBackground),
  /// so this stays transparent.
  @override
  Widget build(BuildContext context) => child;
}

/// The app-wide background of the Settings screen: theme color plus the wave
/// artwork (dimmed on dark). Wrapped around every route in AppPages.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
              color: dark ? const Color(0x73040B22) : null,
              colorBlendMode: dark ? BlendMode.srcATop : null,
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
