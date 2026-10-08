import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/library_groups.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../bottom_sheets/add_to_playlist_sheet.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_nav.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/primary_button.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';
import '../dialogs/app_dialogs.dart';

/// Album / artist / folder / generated list detail with Play and Shuffle
/// (P09-02..P09-05, P09-11).
class SongListScreen extends StatelessWidget {
  const SongListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as SongListArgs;
    final c = context.colors;
    final pc = PlaybackController.to;
    final group = args.group;
    return ScaffoldWithMiniPlayer(
      appBar: DetailAppBar(
        title: args.title,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'more_options'.tr,
            icon: Icon(Icons.more_vert_rounded, color: c.iconDefault),
            color: c.surfaceElevated,
            onSelected: (v) {
              final songs = args.songs();
              if (v == 'add') {
                showAddToPlaylist(songs.where((s) => s.available).toList());
              }
              if (v == 'queue') pc.addToQueue(songs);
              if (v == 'exclude' && group != null) {
                confirmRemoveFolderFromLibrary(group).then((_) {
                  if (LibraryController.to.group(group.kind, group.key) ==
                      null) {
                    Get.back<void>();
                  }
                });
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'queue', child: Text('action_add_queue'.tr)),
              PopupMenuItem(
                value: 'add',
                child: Text('action_add_playlist'.tr),
              ),
              if (group?.kind == GroupKind.folder)
                PopupMenuItem(
                  value: 'exclude',
                  child: Text('action_remove_folder'.tr),
                ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        // Touch reactive lists so favorites/exclusions refresh this screen.
        LibraryController.to.songs.length;
        LibraryController.to.recent.length;
        final List<Song> songs = args.songs();
        final total = songs.fold<int>(0, (a, s) => a + s.durationMs);
        final currentId = pc.currentSong?.id;
        if (songs.isEmpty) {
          return EmptyState(
            title: args.emptyMessage ?? 'list_empty'.tr,
            icon: Icons.music_off_rounded,
          );
        }
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
                        SongArtwork(
                          song: songs.first,
                          size: 112,
                          radius: AppRadius.input,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                args.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headingM.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                              if (args.subtitle != null)
                                Text(
                                  args.subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyM.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              Text(
                                '${'count_songs_n'.trParams({'args1': '${songs.length}'})} • ${DurationFormatter.total(total)}',
                                style: AppTypography.caption.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (group != null && group.allUnavailable) ...[
                      const SizedBox(height: AppSpacing.sm),
                      InfoBanner(message: 'source_unavailable_desc'.tr),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'action_play_all'.tr,
                            icon: Icons.play_arrow_rounded,
                            height: AppSizes.buttonSecondary,
                            onPressed: () => pc.playAll(songs),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: PrimaryButton(
                            label: 'action_shuffle'.tr,
                            icon: Icons.shuffle_rounded,
                            variant: ButtonVariant.secondary,
                            onPressed: () => pc.playAll(songs, shuffle: true),
                          ),
                        ),
                      ],
                    ),
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
              onMore: () => showSongActions(s),
            );
          },
        );
      }),
    );
  }
}
