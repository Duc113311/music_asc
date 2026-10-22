import 'package:flutter/material.dart';
import '../common_components/app_touchable.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../controller/search_controller.dart';
import '../../models/ui_models/library_groups.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_inputs.dart';
import '../common_components/app_nav.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';
import '../screen_library/library_tab.dart';

class SearchScreen extends GetView<MusicSearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    return ScaffoldWithMiniPlayer(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxs,
                AppSpacing.xs,
                AppSpacing.screenH,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'action_back'.tr,
                    color: c.textPrimary,
                    onPressed: () => Get.back<void>(),
                  ),
                  Expanded(
                    child: AppSearchField(
                      controller: controller.text,
                      focusNode: controller.focus,
                      autofocus: true,
                      hint: 'search_hint'.tr,
                      onChanged: controller.onChanged,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final q = controller.query.value.trim();
                if (q.isEmpty) return _History(controller: controller);
                if (controller.searching.value &&
                    controller.results.value.isEmpty) {
                  return const LoadingState();
                }
                final r = controller.results.value;
                if (r.isEmpty) {
                  return ListView(
                    children: [
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'search_no_results'.tr,
                        message: 'search_no_results_desc'.tr,
                        actionLabel: 'action_clear_query'.tr,
                        onAction: () async => controller.clear(),
                      ),
                    ],
                  );
                }
                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (r.songs.isNotEmpty) _Header('lib_songs'.tr),
                    for (final s in r.songs)
                      SongTile(
                        song: s,
                        isCurrent: pc.currentSong?.id == s.id,
                        onTap: () {
                          controller.remember();
                          pc.playFrom(r.songs, s);
                        },
                        onMore: () => showSongActions(s),
                      ),
                    if (r.playlists.isNotEmpty) _Header('lib_playlists'.tr),
                    for (final p in r.playlists)
                      _GroupResult(
                        icon: Icons.queue_music_rounded,
                        title: p.name,
                        subtitle: 'count_songs_n'.trParams({
                          'args1': '${p.songCount}',
                        }),
                        onTap: () {
                          controller.remember();
                          AppNav.openPlaylist(p.id!);
                        },
                      ),
                    for (final (key, list) in [
                      ('lib_albums', r.albums),
                      ('lib_artists', r.artists),
                      ('lib_folders', r.folders),
                    ]) ...[
                      if (list.isNotEmpty) _Header(key.tr),
                      for (final SongGroup g in list)
                        _GroupResult(
                          icon: switch (g.kind) {
                            GroupKind.album => Icons.album_rounded,
                            GroupKind.artist => Icons.person_rounded,
                            GroupKind.folder => Icons.folder_rounded,
                          },
                          title: groupTitle(g),
                          subtitle: 'count_songs_n'.trParams({
                            'args1': '${g.songs.length}',
                          }),
                          coverSongGroup: g,
                          onTap: () {
                            controller.remember();
                            openGroup(g);
                          },
                        ),
                    ],
                    const MiniPlayerSpacer(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppTypography.headingS.copyWith(color: c.textPrimary),
        ),
      ),
    );
  }
}

class _GroupResult extends StatelessWidget {
  const _GroupResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.coverSongGroup,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final SongGroup? coverSongGroup;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cover = coverSongGroup?.coverSong;
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
      ),
      leading: cover != null && coverSongGroup!.kind != GroupKind.folder
          ? SongArtwork(song: cover, size: 48)
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.surfaceSelected,
                borderRadius: BorderRadius.circular(AppRadius.imageSm),
              ),
              child: Icon(icon, color: c.primary),
            ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.songTitle.copyWith(color: c.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyM.copyWith(color: c.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.iconDefault),
      onTap: onTap,
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.controller});
  final MusicSearchController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Obx(() {
      if (controller.history.isEmpty) {
        return ListView(
          children: [
            EmptyState(
              icon: Icons.manage_search_rounded,
              title: 'search_start'.tr,
              message: 'search_start_desc'.tr,
            ),
          ],
        );
      }
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.xs,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'search_recent'.tr,
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.clearHistory,
                  child: Text(
                    'search_clear_all'.tr,
                    style: AppTypography.label.copyWith(color: c.primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              0,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final h in controller.history)
                  _HistoryChip(
                    label: h,
                    onTap: () => controller.useHistory(h),
                    onRemove: () => controller.removeHistory(h),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Recent query as a pill: tap to search again, x to forget it.
class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppRadius.full);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 18, color: c.iconDefault),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                ),
              ),
              InkResponse(
                onTap: onRemove,
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: c.iconDefault,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
