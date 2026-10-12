import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../controller/settings_controller.dart';
import '../../models/ui_models/repeat_mode.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/add_to_playlist_sheet.dart';
import '../bottom_sheets/equalizer_sheet.dart';
import '../bottom_sheets/player_mode_sheets.dart';
import '../bottom_sheets/queue_sheet.dart';
import '../bottom_sheets/sleep_timer_sheet.dart';
import '../bottom_sheets/song_info_sheet.dart';
import '../common_components/app_touchable.dart';
import '../common_components/seek_bar.dart';
import '../common_components/song_artwork.dart';
import '../dialogs/app_dialogs.dart';

/// Sc_phat_nhac. Back only closes this screen; playback continues (P07-15).
/// Every control talks to the shared handler, so mini player, notification
/// and lock screen stay in sync.
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    return Scaffold(
      body: _PlayerBackground(
        child: SafeArea(
          child: Obx(() {
            final s = pc.state.value;
            final song = s.currentSong;
            if (song == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.currentRoute == RouteName.player) Get.back<void>();
              });
              return const SizedBox.shrink();
            }
            final sleepActive = pc.sleep.value.active;
            return LayoutBuilder(
              builder: (context, box) {
                final artSize = (box.maxWidth - 48).clamp(
                  120.0,
                  box.maxHeight * 0.42,
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                AppIconButton(
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  tooltip: 'action_close'.tr,
                                  color: c.textPrimary,
                                  onPressed: () => Get.back<void>(),
                                ),
                                Expanded(
                                  child: Text(
                                    'player_title'.tr,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headingS.copyWith(
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                                AppIconButton(
                                  icon: Icons.queue_music_rounded,
                                  tooltip: 'player_queue'.tr,
                                  color: c.textPrimary,
                                  onPressed: showQueueSheet,
                                ),
                                SizedBox.square(
                                  dimension: AppSizes.touch,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    tooltip: 'more_options'.tr,
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: c.textPrimary,
                                    ),
                                    color: c.surfaceElevated,
                                    onSelected: (v) {
                                      switch (v) {
                                        case 'info':
                                          showSongInfo(song);
                                        case 'quality':
                                          Get.toNamed(
                                              RouteName.playbackQuality);
                                        case 'stop':
                                          confirmStopPlayback();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'info',
                                        child: Text('action_file_info'.tr),
                                      ),
                                      PopupMenuItem(
                                        value: 'quality',
                                        child: Text('settings_quality'.tr),
                                      ),
                                      PopupMenuItem(
                                        value: 'stop',
                                        child: Text('action_stop'.tr),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                AppSpacing.md,
                                AppSpacing.xl,
                                AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Hero(
                                      tag: 'now-playing-art',
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.card),
                                          boxShadow: [c.sheetShadow],
                                        ),
                                        child: SongArtwork(
                                          song: song,
                                          size: artSize,
                                          radius: AppRadius.card,
                                          iconSize: 96,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  Text(
                                    song.displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.headingM.copyWith(
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    song.artistOrNull ?? 'unknown_artist'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyL
                                        .copyWith(color: c.primary),
                                  ),
                                  const Spacer(),
                                  SeekBar(
                                    position: pc.position.value,
                                    duration: s.duration,
                                    onSeek: pc.seek,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Tap toggles the play order right away (no sheet).
                                      AppIconButton(
                                        icon: s.shuffle
                                            ? Icons.shuffle_rounded
                                            : Icons
                                                .format_list_numbered_rounded,
                                        tooltip: s.shuffle
                                            ? 'shuffle_on'.tr
                                            : 'shuffle_off'.tr,
                                        active: s.shuffle,
                                        onPressed: () => _toggleShuffle(pc),
                                      ),
                                      AppIconButton(
                                        icon: Icons.skip_previous_rounded,
                                        tooltip: 'action_previous'.tr,
                                        size: 40,
                                        color: c.textPrimary,
                                        onPressed: pc.previous,
                                      ),
                                      PlayPauseButton(
                                        playing: s.playing,
                                        loading: s.loading,
                                        large: true,
                                        onPressed: pc.togglePlay,
                                      ),
                                      AppIconButton(
                                        icon: Icons.skip_next_rounded,
                                        tooltip: 'action_next'.tr,
                                        size: 40,
                                        color: c.textPrimary,
                                        onPressed: pc.next,
                                      ),
                                      AppIconButton(
                                        icon: s.repeat == RepeatMode.one
                                            ? Icons.repeat_one_rounded
                                            : Icons.repeat_rounded,
                                        tooltip: switch (s.repeat) {
                                          RepeatMode.off => 'repeat_off'.tr,
                                          RepeatMode.all => 'repeat_all'.tr,
                                          RepeatMode.one => 'repeat_one'.tr,
                                        },
                                        active: s.repeat != RepeatMode.off,
                                        // Off → All → One → Off, applied right away.
                                        onPressed: () => _cycleRepeat(pc),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      _Option(
                                        icon: song.favorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        label: 'favorites_short'.tr,
                                        active: song.favorite,
                                        onTap: () => showFavoriteSheet(song),
                                      ),
                                      _Option(
                                        icon: Icons.playlist_add_rounded,
                                        label: 'player_add_to'.tr,
                                        onTap: () => showAddToPlaylist([song]),
                                      ),
                                      _Option(
                                        icon: Icons.tune_rounded,
                                        label: 'settings_equalizer'.tr,
                                        active: pc.eq.value.enabled,
                                        onTap: showEqualizerSheet,
                                      ),
                                      _Option(
                                        icon: Icons.timer_outlined,
                                        label: 'player_timer'.tr,
                                        active: sleepActive,
                                        onTap: showSleepTimerSheet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.primary : c.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.input),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppTypography.caption.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme gradient, or a blurred copy of the playing cover when "Mờ từ ảnh
/// bìa" is on (sc_theme). Falls back to the gradient without artwork.
class _PlayerBackground extends StatelessWidget {
  const _PlayerBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.surfaceSelected, c.background],
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        gradient,
        Obx(() {
          final uri = PlaybackController.to.currentSong?.uri;
          if (!SettingsController.to.playerBlurBackground.value ||
              uri == null) {
            return const SizedBox.shrink();
          }
          final peek = ArtworkCache.peek(uri);
          return FutureBuilder<Uint8List?>(
            key: ValueKey(uri),
            initialData: peek,
            future: peek == null ? ArtworkCache.load(uri) : null,
            builder: (context, snap) {
              final bytes = snap.data;
              if (bytes == null) return const SizedBox.shrink();
              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      cacheWidth: 200,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  // Keeps text and controls readable over any cover.
                  ColoredBox(color: c.background.withValues(alpha: 0.6)),
                ],
              );
            },
          );
        }),
        child,
      ],
    );
  }
}

Future<void> _toggleShuffle(PlaybackController pc) async {
  final on = !pc.state.value.shuffle;
  await pc.setShuffle(on);
  HapticFeedback.selectionClick();
}

Future<void> _cycleRepeat(PlaybackController pc) async {
  final next = pc.state.value.repeat.next;
  await pc.setRepeat(next);
  HapticFeedback.selectionClick();
}
