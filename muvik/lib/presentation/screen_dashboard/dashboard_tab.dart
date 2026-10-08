import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_nav.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';

/// Greeting by device hour (spec §4.2): morning 05–10, noon 11–13,
/// afternoon 14–17, evening 18–04.
String greetingKey(int hour) {
  if (hour >= 5 && hour <= 10) return 'greeting_morning';
  if (hour >= 11 && hour <= 13) return 'greeting_noon';
  if (hour >= 14 && hour <= 17) return 'greeting_afternoon';
  return 'greeting_evening';
}

/// sc_home — every block uses real local data; nothing is filled with demo
/// content (P08-05..P08-10).
class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    required this.scrollController,
    required this.onOpenLibrary,
  });
  final ScrollController scrollController;
  final VoidCallback onOpenLibrary;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with WidgetsBindingObserver {
  late int _hour = DateTime.now().hour;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleHourTick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshHour();
  }

  void _scheduleHourTick() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    _timer?.cancel();
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      _refreshHour();
      _scheduleHourTick();
    });
  }

  void _refreshHour() {
    final h = DateTime.now().hour;
    if (h != _hour && mounted) setState(() => _hour = h);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final recent = lib.recent.take(5).toList();
          return CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.xs,
                    0,
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
                                '${greetingKey(_hour).tr} 👋',
                                style: AppTypography.headingL.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'home_subtitle'.tr,
                              style: AppTypography.bodyL.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'action_search'.tr,
                        filled: true,
                        onPressed: () => Get.toNamed(RouteName.search),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'home_your_music'.tr,
                  onMore: pc.hasSong ? pc.openNowPlaying : null,
                  moreLabel: '',
                ),
              ),
              SliverToBoxAdapter(
                child: _YourMusicCard(onOpenLibrary: widget.onOpenLibrary),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.sm,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppChip(
                        label: 'home_recent'.tr,
                        icon: Icons.history_rounded,
                        onTap: () => AppNav.openSongs(
                          SongListArgs(
                            title: 'home_recent_title'.tr,
                            songs: () => lib.recent,
                            emptyMessage: 'home_recent_empty'.tr,
                          ),
                        ),
                      ),
                      AppChip(
                        label: 'favorites'.tr,
                        icon: Icons.favorite_border_rounded,
                        onTap: () =>
                            AppNav.openPlaylist(AppNav.favoritesPlaylistId),
                      ),
                    ],
                  ),
                ),
              ),
              if (!lib.isEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(title: 'home_for_you'.tr),
                ),
                SliverToBoxAdapter(child: _ForYouRow()),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'home_recent_title'.tr,
                  onMore: recent.isEmpty
                      ? null
                      : () => AppNav.openSongs(
                          SongListArgs(
                            title: 'home_recent_title'.tr,
                            songs: () => lib.recent,
                          ),
                        ),
                ),
              ),
              if (recent.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    compact: true,
                    icon: Icons.history_rounded,
                    title: 'home_recent_empty'.tr,
                    message: 'home_recent_empty_desc'.tr,
                    actionLabel: 'home_open_library'.tr,
                    onAction: () async => widget.onOpenLibrary(),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: recent.length,
                  itemBuilder: (context, i) {
                    final Song s = recent[i];
                    return SongTile(
                      song: s,
                      isCurrent: pc.currentSong?.id == s.id,
                      onTap: () => pc.playFrom(lib.recent, s),
                      onMore: () => showSongActions(s),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: MiniPlayerSpacer()),
            ],
          );
        }),
      ),
    );
  }
}

class _YourMusicCard extends StatelessWidget {
  const _YourMusicCard({required this.onOpenLibrary});
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final lib = LibraryController.to;
    return Obx(() {
      final s = pc.state.value;
      final song = s.currentSong;
      if (song == null) {
        // Never played: invite to pick music, no demo song (P08-07).
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            child: lib.isEmpty
                ? EmptyState(
                    compact: true,
                    illustration: true,
                    title: 'library_empty_title'.tr,
                    message: lib.hasPermission
                        ? 'library_empty_desc'.tr
                        : 'no_audio_permission'.tr,
                    actionLabel: 'action_scan_music'.tr,
                    onAction: () async => Get.toNamed(RouteName.scanLibrary),
                  )
                : EmptyState(
                    compact: true,
                    icon: Icons.queue_music_rounded,
                    title: 'home_pick_music'.tr,
                    message: 'home_pick_music_desc'.tr,
                    actionLabel: 'home_open_library'.tr,
                    onAction: () async => onOpenLibrary(),
                  ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: AppCard(
          onTap: pc.openNowPlaying,
          child: Row(
            children: [
              SongArtwork(song: song, size: 120, radius: AppRadius.input),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.playing
                          ? 'home_now_playing'.tr.toUpperCase()
                          : 'home_continue'.tr.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingS.copyWith(
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
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        PlayPauseButton(
                          playing: s.playing,
                          loading: s.loading,
                          onPressed: pc.togglePlay,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            s.playing ? 'action_pause'.tr : 'home_continue'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.more_vert_rounded,
                          tooltip: 'song_menu'.tr,
                          onPressed: () => showSongActions(song),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// "Playlist dành cho bạn": user playlists first, then local rule-based
/// groups (favorites, most played, recently added). No online content.
class _ForYouRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return Obx(() {
      final cards = <Widget>[];
      if (lib.favorites.isNotEmpty) {
        cards.add(
          CoverCard(
            title: 'favorites'.tr,
            subtitle: 'count_songs_n'.trParams({
              'args1': '${lib.favorites.length}',
            }),
            coverSong: lib.favorites.first,
            placeholderIcon: Icons.favorite_rounded,
            onTap: () => AppNav.openPlaylist(AppNav.favoritesPlaylistId),
            onPlay: () => pc.playAll(lib.favorites),
          ),
        );
      }
      for (final p in lib.playlists.take(6)) {
        cards.add(
          CoverCard(
            title: p.name,
            subtitle: 'count_songs_n'.trParams({'args1': '${p.songCount}'}),
            coverSong: p.firstSongId == null
                ? null
                : lib.songById(p.firstSongId!),
            onTap: () => AppNav.openPlaylist(p.id!),
            onPlay: p.songCount == 0
                ? null
                : () async {
                    final songs = await lib.playlistSongs(p.id!);
                    await pc.playAll(songs);
                  },
          ),
        );
      }
      final most = lib.mostPlayed(limit: 50);
      if (most.isNotEmpty) {
        cards.add(_auto('explore_replay'.tr, most, Icons.replay_rounded));
      }
      final added = lib.recentlyAdded(limit: 50);
      if (added.isNotEmpty) {
        cards.add(
          _auto('explore_recently_added'.tr, added, Icons.new_releases_rounded),
        );
      }
      return SizedBox(
        height: 236,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) => cards[i],
        ),
      );
    });
  }

  Widget _auto(String title, List<Song> songs, IconData icon) {
    final pc = PlaybackController.to;
    return CoverCard(
      title: title,
      subtitle: 'count_songs_n'.trParams({'args1': '${songs.length}'}),
      coverSong: songs.first,
      placeholderIcon: icon,
      onTap: () =>
          AppNav.openSongs(SongListArgs(title: title, songs: () => songs)),
      onPlay: () => pc.playAll(songs),
    );
  }
}
