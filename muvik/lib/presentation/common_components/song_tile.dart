import 'package:flutter/material.dart';
import 'app_touchable.dart';
import 'package:get/get.dart';

import '../../models/data_models/song.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'song_artwork.dart';

/// Song row: min height 80, art 56, gap 12 (Design System §9). Unavailable
/// files are dimmed with a reason (spec §4.3).
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onMore,
    this.isCurrent = false,
    this.leadingIndex,
    this.trailing,
    this.subtitleOverride,
    this.dense = false,
  });

  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final bool isCurrent;
  final String? leadingIndex;
  final Widget? trailing;
  final String? subtitleOverride;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final artist = song.artistOrNull ?? 'unknown_artist'.tr;
    final subtitle =
        subtitleOverride ??
        (song.available
            ? '$artist • ${DurationFormatter.clockMs(song.durationMs)}'
            : 'song_unavailable'.tr);
    return Opacity(
      opacity: song.available ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: dense ? 64 : AppSizes.songTile,
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.screenH,
              right: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                if (leadingIndex != null) ...[
                  SizedBox(
                    width: 28,
                    child: Text(
                      leadingIndex!,
                      style: AppTypography.label.copyWith(color: c.primary),
                    ),
                  ),
                ],
                Stack(
                  children: [
                    SongArtwork(
                      song: song,
                      size: dense ? 48 : AppSizes.songArt,
                    ),
                    if (isCurrent)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: c.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.songTitle.copyWith(
                          color: isCurrent ? c.primary : c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (song.favorite) ...[
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: c.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (!song.available) ...[
                            Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: c.warning,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyM.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ?trailing,
                if (onMore != null)
                  AppIconButton(
                    icon: Icons.more_vert_rounded,
                    tooltip: 'song_menu'.tr,
                    onPressed: onMore,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
