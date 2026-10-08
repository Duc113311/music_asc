import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/playlist.dart';
import '../../models/ui_models/library_groups.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/playlist_actions_sheet.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../bottom_sheets/sort_sheet.dart';
import '../common_components/app_nav.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';
import '../screens_playlist/playlist_form_screen.dart';

String groupTitle(SongGroup g) =>
    g.title ??
    switch (g.kind) {
      GroupKind.album => 'unknown_album'.tr,
      GroupKind.artist => 'unknown_artist'.tr,
      GroupKind.folder => g.key,
    };

void openGroup(SongGroup g) {
  final lib = LibraryController.to;
  AppNav.openSongs(
    SongListArgs(
      title: groupTitle(g),
      subtitle: g.subtitle,
      group: g,
      songs: () => lib.group(g.kind, g.key)?.songs ?? const [],
    ),
  );
}

/// Library tab: Songs / Albums / Artists / Folders / Playlists with real
/// counts from the DB (P09-01).
class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            PageHeader(
              title: 'tab_library'.tr,
              actions: [
                AppIconButton(
                  icon: Icons.search_rounded,
                  tooltip: 'action_search'.tr,
                  onPressed: () => Get.toNamed(RouteName.search),
                ),
                AppIconButton(
                  icon: Icons.sort_rounded,
                  tooltip: 'action_sort'.tr,
                  onPressed: showSortSheet,
                ),
                PopupMenuButton<String>(
                  tooltip: 'more_options'.tr,
                  icon: Icon(Icons.more_vert_rounded, color: c.iconDefault),
                  color: c.surfaceElevated,
                  onSelected: (v) {
                    if (v == 'scan') Get.toNamed(RouteName.scanLibrary);
                    if (v == 'new') {
                      Get.toNamed(
                        RouteName.playlistForm,
                        arguments: const PlaylistFormArgs(),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'scan',
                      child: Text('action_scan_music'.tr),
                    ),
                    PopupMenuItem(
                      value: 'new',
                      child: Text('playlist_create'.tr),
                    ),
                  ],
                ),
              ],
            ),
            Obx(
              () => TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: c.primary,
                unselectedLabelColor: c.textSecondary,
                indicatorColor: c.primary,
                dividerColor: c.divider,
                labelStyle: AppTypography.label,
                tabs: [
                  Tab(text: '${'lib_songs'.tr} (${lib.songs.length})'),
                  Tab(text: '${'lib_albums'.tr} (${lib.albums.length})'),
                  Tab(text: '${'lib_artists'.tr} (${lib.artists.length})'),
                  Tab(text: '${'lib_folders'.tr} (${lib.folders.length})'),
                  Tab(
                    text: '${'lib_playlists'.tr} (${lib.playlists.length + 1})',
                  ),
                ],
              ),
            ),
            Obx(
              () =>
                  !lib.hasPermission && lib.sources.every((s) => !s.accessible)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.sm,
                        AppSpacing.screenH,
                        0,
                      ),
                      child: InfoBanner(
                        message: 'no_audio_permission'.tr,
                        actionLabel: 'action_grant'.tr,
                        onAction: () => Get.toNamed(RouteName.permissions),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SongsTab(scrollController: scrollController),
                  const _GroupsTab(kind: GroupKind.album),
                  const _GroupsTab(kind: GroupKind.artist),
                  const _GroupsTab(kind: GroupKind.folder),
                  const _PlaylistsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty();

  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    return Obx(() {
      if (lib.loading.value) return const LoadingState();
      return ListView(
        children: [
          EmptyState(
            illustration: true,
            title: 'library_empty_title'.tr,
            message: lib.hasPermission
                ? 'library_empty_desc'.tr
                : 'no_audio_permission_desc'.tr,
            actionLabel: 'action_scan_music'.tr,
            onAction: () async => Get.toNamed(RouteName.scanLibrary),
            secondaryLabel: lib.hasPermission ? null : 'action_grant'.tr,
            onSecondary: () async => Get.toNamed(RouteName.permissions),
          ),
        ],
      );
    });
  }
}

class _SongsTab extends StatelessWidget {
  const _SongsTab({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return Obx(() {
      final songs = lib.songs;
      if (songs.isEmpty) return const _LibraryEmpty();
      final currentId = pc.currentSong?.id;
      return ListView.builder(
        controller: scrollController,
        itemCount: songs.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) {
            return ListTile(
              minTileHeight: 56,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              leading: Icon(Icons.shuffle_rounded, color: c.primary),
              title: Text(
                'action_shuffle_all'.tr,
                style: AppTypography.label.copyWith(color: c.textPrimary),
              ),
              trailing: Text(
                'sort_label'.trParams({'args1': lib.sort.value.labelKey.tr}),
                style: AppTypography.caption.copyWith(color: c.textMuted),
              ),
              onTap: () => pc.playAll(songs, shuffle: true),
            );
          }
          if (i == songs.length + 1) return const MiniPlayerSpacer();
          final s = songs[i - 1];
          return SongTile(
            song: s,
            isCurrent: s.id == currentId,
            onTap: () => pc.playFrom(songs, s),
            onMore: () => showSongActions(s),
          );
        },
      );
    });
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.kind});
  final GroupKind kind;

  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    return Obx(() {
      final groups = switch (kind) {
        GroupKind.album => lib.albums,
        GroupKind.artist => lib.artists,
        GroupKind.folder => lib.folders,
      };
      if (groups.isEmpty) return const _LibraryEmpty();
      if (kind == GroupKind.album) {
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSizes.miniPlayer + 40 + MediaQuery.paddingOf(context).bottom,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.72,
          ),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final g = groups[i];
            return LayoutBuilder(
              builder: (context, box) => CoverCard(
                width: box.maxWidth,
                title: groupTitle(g),
                subtitle:
                    '${g.subtitle ?? 'various_artists'.tr} • ${'count_songs_n'.trParams({'args1': '${g.songs.length}'})}',
                coverSong: g.coverSong,
                placeholderIcon: Icons.album_rounded,
                onTap: () => openGroup(g),
              ),
            );
          },
        );
      }
      return ListView.builder(
        itemCount: groups.length + 1,
        itemBuilder: (context, i) {
          if (i == groups.length) return const MiniPlayerSpacer();
          final g = groups[i];
          return _GroupRow(group: g);
        },
      );
    });
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group});
  final SongGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final g = group;
    final isFolder = g.kind == GroupKind.folder;
    return InkWell(
      onTap: () => openGroup(g),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (isFolder)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.surfaceSelected,
                    borderRadius: BorderRadius.circular(AppRadius.imageSm),
                  ),
                  child: Icon(Icons.folder_rounded, color: c.primary),
                )
              else
                ClipOval(
                  child: SongArtwork(song: g.coverSong, size: 56, radius: 28),
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupTitle(g),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.songTitle.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      g.allUnavailable
                          ? 'source_unavailable'.tr
                          : (isFolder
                                ? '${g.subtitle} • ${'count_songs_n'.trParams({'args1': '${g.songs.length}'})}'
                                : 'count_songs_n'.trParams({
                                    'args1': '${g.songs.length}',
                                  })),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyM.copyWith(
                        color: g.allUnavailable ? c.warning : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return Obx(() {
      final List<Playlist> lists = lib.playlists;
      return GridView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSizes.miniPlayer + 40 + MediaQuery.paddingOf(context).bottom,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.72,
        ),
        children: [
          Material(
            color: c.surfaceSelected,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => Get.toNamed(
                RouteName.playlistForm,
                arguments: const PlaylistFormArgs(),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: c.primary),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: c.primary,
                      size: 44,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'playlist_create'.tr,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) => CoverCard(
              width: box.maxWidth,
              title: 'favorites'.tr,
              subtitle: 'count_songs_n'.trParams({
                'args1': '${lib.favorites.length}',
              }),
              coverSong: lib.favorites.firstOrNull,
              placeholderIcon: Icons.favorite_rounded,
              onTap: () => AppNav.openPlaylist(AppNav.favoritesPlaylistId),
            ),
          ),
          for (final p in lists)
            LayoutBuilder(
              builder: (context, box) => CoverCard(
                width: box.maxWidth,
                title: p.name,
                subtitle: 'count_songs_n'.trParams({'args1': '${p.songCount}'}),
                coverSong: p.firstSongId == null
                    ? null
                    : lib.songById(p.firstSongId!),
                onTap: () => AppNav.openPlaylist(p.id!),
                onMore: () => showPlaylistActions(
                  p,
                  onPlay: () async {
                    await pc.playAll(await lib.playlistSongs(p.id!));
                  },
                ),
              ),
            ),
        ],
      );
    });
  }
}
