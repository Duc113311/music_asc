import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../controller/playlist_detail_controller.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../bottom_sheets/song_picker_sheet.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/primary_button.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';
import '../dialogs/app_dialogs.dart';
import 'playlist_form_screen.dart';

class PlaylistDetailScreen extends GetView<PlaylistDetailController> {
  const PlaylistDetailScreen({super.key});

  Future<void> _handleBack() async {
    if (controller.dirty) {
      if (await confirmDiscardChanges()) {
        controller.cancelEdit();
        Get.back<void>();
      }
      return;
    }
    if (controller.editing.value) {
      controller.cancelEdit();
      return;
    }
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final lib = LibraryController.to;
    return Obx(() {
      final p = controller.playlist.value;
      final editing = controller.editing.value;
      final title = controller.isFavorites ? 'favorites'.tr : (p?.name ?? '');
      return PopScope(
        canPop: !editing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: ScaffoldWithMiniPlayer(
          appBar: DetailAppBar(
            title: editing ? 'playlist_edit_songs'.tr : title,
            onBack: _handleBack,
            actions: editing
                ? [
                    TextButton(
                      onPressed: controller.saveEdit,
                      child: Text(
                        'action_save'.tr,
                        style: AppTypography.label.copyWith(color: c.primary),
                      ),
                    ),
                  ]
                : [
                    PopupMenuButton<String>(
                      tooltip: 'more_options'.tr,
                      icon: Icon(Icons.more_vert_rounded, color: c.iconDefault),
                      color: c.surfaceElevated,
                      onSelected: (v) async {
                        switch (v) {
                          case 'add':
                            final ids = await showSongPicker(
                              exclude: controller.songs
                                  .map((s) => s.id!)
                                  .toSet(),
                            );
                            if (ids != null && ids.isNotEmpty) {
                              await controller.addSongs(ids);
                            }
                          case 'reorder':
                            controller.startEdit();
                          case 'info':
                            await Get.toNamed(
                              RouteName.playlistForm,
                              arguments: PlaylistFormArgs(editing: p),
                            );
                          case 'delete':
                            if (p != null && await confirmDeletePlaylist(p)) {
                              Get.back<void>();
                            }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'add',
                          child: Text('playlist_add_songs'.tr),
                        ),
                        if (controller.songs.isNotEmpty)
                          PopupMenuItem(
                            value: 'reorder',
                            child: Text('playlist_edit_songs'.tr),
                          ),
                        if (!controller.isFavorites) ...[
                          PopupMenuItem(
                            value: 'info',
                            child: Text('playlist_edit'.tr),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('playlist_delete'.tr),
                          ),
                        ],
                      ],
                    ),
                  ],
          ),
          body: _body(context, pc, lib),
        ),
      );
    });
  }

  Widget _body(
    BuildContext context,
    PlaybackController pc,
    LibraryController lib,
  ) {
    final c = context.colors;
    if (controller.loading.value) return const LoadingState();
    if (controller.missing.value) {
      return EmptyState(
        icon: Icons.playlist_remove_rounded,
        title: 'playlist_missing'.tr,
        actionLabel: 'action_back'.tr,
        onAction: () async => Get.back<void>(),
      );
    }
    if (controller.editing.value) {
      final draft = controller.draft;
      return ReorderableListView.builder(
        padding: EdgeInsets.only(
          bottom:
              AppSizes.miniPlayer + 40 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: draft.length,
        onReorder: controller.reorder,
        itemBuilder: (context, i) {
          final s = draft[i];
          return SongTile(
            key: ValueKey('edit-${s.id}'),
            song: s,
            dense: true,
            trailing: IconButton(
              tooltip: controller.isFavorites
                  ? 'action_unfavorite'.tr
                  : 'action_remove_from_playlist'.tr,
              icon: Icon(Icons.remove_circle_outline_rounded, color: c.error),
              onPressed: () => controller.removeFromDraft(s),
            ),
          );
        },
      );
    }
    final songs = controller.songs;
    final p = controller.playlist.value;
    final cover = p?.coverUri != null
        ? songs.firstWhereOrNull((s) => s.uri == p!.coverUri) ??
              songs.firstOrNull
        : songs.firstOrNull;
    final currentId = pc.currentSong?.id;
    return ListView.builder(
      itemCount: songs.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    cover == null
                        ? ArtworkPlaceholder(
                            size: 112,
                            icon: controller.isFavorites
                                ? Icons.favorite_rounded
                                : Icons.queue_music_rounded,
                          )
                        : SongArtwork(
                            song: cover,
                            size: 112,
                            radius: AppRadius.input,
                          ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.isFavorites
                                ? 'favorites'.tr
                                : (p?.name ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingM.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            '${'count_songs_n'.trParams({'args1': '${songs.length}'})} • ${DurationFormatter.total(controller.totalMs)}',
                            style: AppTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          if ((p?.description ?? '').isNotEmpty)
                            Text(
                              p!.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'action_play_all'.tr,
                        icon: Icons.play_arrow_rounded,
                        height: AppSizes.buttonSecondary,
                        onPressed: songs.isEmpty
                            ? null
                            : () => pc.playAll(songs),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'action_shuffle'.tr,
                        icon: Icons.shuffle_rounded,
                        variant: ButtonVariant.secondary,
                        onPressed: songs.isEmpty
                            ? null
                            : () => pc.playAll(songs, shuffle: true),
                      ),
                    ),
                  ],
                ),
                if (songs.isEmpty) ...[
                  EmptyState(
                    compact: true,
                    icon: Icons.library_add_rounded,
                    title: 'playlist_empty'.tr,
                    message: controller.isFavorites
                        ? 'favorites_empty_desc'.tr
                        : 'playlist_empty_desc'.tr,
                    actionLabel: 'playlist_add_songs'.tr,
                    onAction: () async {
                      final ids = await showSongPicker(exclude: const {});
                      if (ids != null && ids.isNotEmpty) {
                        await controller.addSongs(ids);
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        }
        if (i == songs.length + 1) return const MiniPlayerSpacer();
        final s = songs[i - 1];
        return SongTile(
          song: s,
          isCurrent: s.id == currentId,
          onTap: () => pc.playFrom(songs, s),
          onMore: () => showSongActions(
            s,
            playlistId: controller.isFavorites ? null : controller.playlistId,
          ),
        );
      },
    );
  }
}
