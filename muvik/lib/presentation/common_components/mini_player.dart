import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'app_touchable.dart';
import 'song_artwork.dart';

/// Mini player bound to the shared player (P03-15, P08-03). Shown only when
/// a song is selected; tapping opens Now Playing. Height grows with font size.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = PlaybackController.to;
    final c = context.colors;
    return Obx(() {
      final s = pc.state.value;
      final song = s.currentSong;
      if (song == null) return const SizedBox.shrink();
      final total = s.duration?.inMilliseconds ?? 0;
      final progress = total > 0
          ? (pc.position.value.inMilliseconds / total).clamp(0.0, 1.0)
          : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: pc.openNowPlaying,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.miniPlayer),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: c.border),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Hero(
                    tag: 'now-playing-art',
                    child: SongArtwork(
                      song: song,
                      size: AppSizes.miniPlayerArt,
                    ),
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
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          song.artistOrNull ?? 'unknown_artist'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyM.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: c.border,
                            color: c.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'action_previous'.tr,
                    onPressed: pc.previous,
                    color: c.textPrimary,
                  ),
                  PlayPauseButton(
                    playing: s.playing,
                    loading: s.loading,
                    onPressed: pc.togglePlay,
                  ),
                  AppIconButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'action_next'.tr,
                    onPressed: pc.next,
                    color: c.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Bottom padding that keeps list ends visible above the mini player.
class MiniPlayerSpacer extends StatelessWidget {
  const MiniPlayerSpacer({super.key, this.extra = 0});
  final double extra;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PlaybackController>()) return SizedBox(height: extra);
    return Obx(
      () => SizedBox(
        height:
            (PlaybackController.to.hasSong ? AppSizes.miniPlayer + 24 : 16) +
                extra +
                MediaQuery.paddingOf(context).bottom,
      ),
    );
  }
}

/// Scaffold for detail screens: content + mini player pinned at the bottom.
class ScaffoldWithMiniPlayer extends StatelessWidget {
  const ScaffoldWithMiniPlayer({super.key, this.appBar, required this.body});
  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 8,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
