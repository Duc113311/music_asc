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
import '../common_components/app_inputs.dart';
import '../common_components/app_nav.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';
import '../screen_library/library_tab.dart';

/// sc_kham_pha — suggestions from the device library only (P11). Mood chips
/// are omitted because songs carry no mood tags (P11-04); "Thống kê" opens
/// the separate statistics screen instead of a fifth tab (P11-06).
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          if (lib.isEmpty) {
            return ListView(
              controller: scrollController,
              children: [
                PageHeader(
                  title: 'explore_title'.tr,
                  subtitle: 'explore_subtitle'.tr,
                ),
                EmptyState(
                  illustration: true,
                  title: 'library_empty_title'.tr,
                  message: 'explore_empty_desc'.tr,
                  actionLabel: 'action_scan_music'.tr,
                  onAction: () async => Get.toNamed(RouteName.scanLibrary),
                ),
              ],
            );
          }
          final most = lib.mostPlayed();
          final least = lib.leastPlayed();
          final random = lib.randomMix();
          final added = lib.recentlyAdded(limit: 50);
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: 'explore_title'.tr,
                  subtitle: 'explore_subtitle'.tr,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        onPressed: () => Get.toNamed(RouteName.statistics),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: c.surfaceSelected,
                          shape: const StadiumBorder(),
                        ),
                        icon: Icon(Icons.bar_chart_rounded, color: c.primary),
                        label: Text(
                          'stats_title'.tr,
                          style: AppTypography.label.copyWith(color: c.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.sm,
                    AppSpacing.screenH,
                    AppSpacing.sm,
                  ),
                  child: AppSearchField(
                    hint: 'search_hint'.tr,
                    readOnly: true,
                    onTap: () => Get.toNamed(RouteName.search),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                    ),
                    children: [
                      if (most.isNotEmpty)
                        _SuggestionCard(
                          title: 'explore_replay'.tr,
                          desc: 'explore_replay_desc'.tr,
                          icon: Icons.replay_rounded,
                          songs: most,
                        ),
                      _SuggestionCard(
                        title: 'explore_least'.tr,
                        desc: 'explore_least_desc'.tr,
                        icon: Icons.explore_rounded,
                        songs: least,
                      ),
                      _SuggestionCard(
                        title: 'explore_random'.tr,
                        desc: 'explore_random_desc'.tr,
                        icon: Icons.shuffle_rounded,
                        songs: random,
                        shuffle: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (lib.albums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(title: 'lib_albums'.tr),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                      ),
                      itemCount: lib.albums.length.clamp(0, 12),
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final g = lib.albums[i];
                        return CoverCard(
                          title: groupTitle(g),
                          subtitle: g.subtitle ?? 'various_artists'.tr,
                          coverSong: g.coverSong,
                          placeholderIcon: Icons.album_rounded,
                          onTap: () => openGroup(g),
                          onPlay: () => pc.playAll(g.songs),
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (lib.playlists.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(title: 'lib_playlists'.tr),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                      ),
                      itemCount: lib.playlists.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final p = lib.playlists[i];
                        return CoverCard(
                          title: p.name,
                          subtitle: 'count_songs_n'.trParams({
                            'args1': '${p.songCount}',
                          }),
                          coverSong: p.firstSongId == null
                              ? null
                              : lib.songById(p.firstSongId!),
                          onTap: () => AppNav.openPlaylist(p.id!),
                          onPlay: p.songCount == 0
                              ? null
                              : () async =>
                                    pc.playAll(await lib.playlistSongs(p.id!)),
                        );
                      },
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'explore_recently_added'.tr,
                  onMore: () => AppNav.openSongs(
                    SongListArgs(
                      title: 'explore_recently_added'.tr,
                      songs: () => lib.recentlyAdded(limit: 200),
                    ),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: added.length.clamp(0, 6),
                itemBuilder: (context, i) {
                  final s = added[i];
                  return SongTile(
                    song: s,
                    isCurrent: pc.currentSong?.id == s.id,
                    onTap: () => pc.playFrom(added, s),
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.songs,
    this.shuffle = false,
  });

  final String title;
  final String desc;
  final IconData icon;
  final List<Song> songs;
  final bool shuffle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: SizedBox(
        width: 168,
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => AppNav.openSongs(
              SongListArgs(title: title, subtitle: desc, songs: () => songs),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.55,
                    child: songs.isEmpty
                        ? ArtworkPlaceholder(size: 220, icon: icon)
                        : SongArtwork(song: songs.first, size: 220, radius: 0),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, c.surface],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton.filled(
                          tooltip: 'action_play'.tr,
                          style: IconButton.styleFrom(
                            backgroundColor: c.primary,
                          ),
                          onPressed: songs.isEmpty
                              ? null
                              : () => pc.playAll(songs, shuffle: shuffle),
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            color: c.onPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
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
      ),
    );
  }
}
