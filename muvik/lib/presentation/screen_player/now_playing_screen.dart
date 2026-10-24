import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../controller/settings_controller.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/repeat_mode.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/add_to_playlist_sheet.dart';
import '../bottom_sheets/equalizer_sheet.dart';
import '../bottom_sheets/queue_sheet.dart';
import '../bottom_sheets/sleep_timer_sheet.dart';
import '../bottom_sheets/song_info_sheet.dart';
import '../common_components/app_touchable.dart';
import '../common_components/seek_bar.dart';
import '../common_components/song_artwork.dart';
import 'lyrics_view.dart';
import 'player_widgets.dart';

const Color _heartColor = Color(0xFFFF5C8A);

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
                final discSize = (box.maxWidth - 72).clamp(
                  120.0,
                  box.maxHeight * 0.40,
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            child: SizedBox(
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Centered on the screen, independent of
                                  // the buttons on either side.
                                  Text(
                                    'player_title'.tr,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headingS.copyWith(
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    // Pulled left so the glyph (not its 48 px touch
                                    // box) lines up with the 16 px page margin.
                                    child: Transform.translate(
                                      offset: const Offset(-12, 0),
                                      child: AppIconButton(
                                        icon: Icons.keyboard_arrow_down_rounded,
                                        tooltip: 'action_close'.tr,
                                        size: 28,
                                        color: c.textPrimary,
                                        onPressed: () => Get.back<void>(),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _HeaderButton(
                                          tooltip: 'player_queue'.tr,
                                          onTap: showQueueSheet,
                                          child: Icon(
                                            Icons.queue_music_rounded,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        _HeaderButton(
                                          tooltip: 'action_file_info'.tr,
                                          onTap: () => showSongInfo(song),
                                          child: Icon(
                                            Icons.info_outline_rounded,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          _PlayerStage(
                            uri: song.uri,
                            playing: s.playing,
                            discSize: discSize,
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: AppSizes.touch),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        song.displayTitle,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.headingM.copyWith(
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        song.artistOrNull ??
                                            'unknown_artist'.tr,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyL.copyWith(
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppIconButton(
                                  icon: song.favorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  tooltip: 'favorites_short'.tr,
                                  color: _heartColor,
                                  onPressed: () => _toggleFavorite(song),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: SeekBar(
                              position: pc.position.value,
                              duration: s.duration,
                              onSeek: pc.seek,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Tap toggles the play order right away (no sheet).
                                AppIconButton(
                                  icon: s.shuffle
                                      ? Icons.shuffle_rounded
                                      : Icons.format_list_numbered_rounded,
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
                                GlowPlayButton(
                                  playing: s.playing,
                                  loading: s.loading,
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
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                _Option(
                                  icon: song.favorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label: 'favorites_short'.tr,
                                  active: song.favorite,
                                  activeColor: _heartColor,
                                  onTap: () => _toggleFavorite(song),
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

/// Rounded-square button used in the header (queue, more).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.child, required this.tooltip, this.onTap});
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surfaceInput.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Round dark button with a label underneath (favorite, add, equalizer, timer).
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = activeColor ?? c.primary;
    final color = active ? accent : c.textPrimary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: c.surfaceInput.withValues(alpha: 0.6),
                shape: CircleBorder(
                  side: BorderSide(
                    color: active
                        ? accent.withValues(alpha: 0.7)
                        : c.border.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox.square(
                    dimension: 54,
                    child: Icon(icon, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: active ? accent : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _toggleFavorite(Song song) async {
  final lib = LibraryController.to;
  await lib.toggleFavorite(lib.songById(song.id!) ?? song);
  HapticFeedback.selectionClick();
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
  // No sheet any more: a short toast says which mode is now on.
  ToastUtils.show(
    on ? 'shuffle_on'.tr : 'shuffle_off'.tr,
    duration: const Duration(milliseconds: 1200),
  );
}

Future<void> _cycleRepeat(PlaybackController pc) async {
  final next = pc.state.value.repeat.next;
  await pc.setRepeat(next);
  HapticFeedback.selectionClick();
  ToastUtils.show(
    switch (next) {
      RepeatMode.off => 'repeat_off'.tr,
      RepeatMode.all => 'repeat_all'.tr,
      RepeatMode.one => 'repeat_one'.tr,
    },
    duration: const Duration(milliseconds: 1200),
  );
}

/// Swipeable middle of the player: the spinning record, and (swipe right to
/// left) the lyrics.
class _PlayerStage extends StatefulWidget {
  const _PlayerStage({
    required this.uri,
    required this.playing,
    required this.discSize,
  });

  final String uri;
  final bool playing;
  final double discSize;

  @override
  State<_PlayerStage> createState() => _PlayerStageState();
}

class _PlayerStageState extends State<_PlayerStage> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Room above/below the record for the rising notes and the tonearm.
    final height = widget.discSize + 32;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: PageView(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              Center(
                child: VinylPlayer(
                  playing: widget.playing,
                  size: widget.discSize,
                ),
              ),
              LyricsView(uri: widget.uri),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 2; i++)
              AnimatedContainer(
                duration: AppMotion.state,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _page
                      ? c.primary
                      : c.textSecondary.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
