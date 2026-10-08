import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../services/application/playlist_service.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/song_artwork.dart';
import '../dialogs/app_dialogs.dart';
import 'add_to_playlist_sheet.dart';
import 'song_info_sheet.dart';

/// Song "⋮" menu (spec §9.2): play next, add to queue, add to playlist,
/// favorite, file info, remove from library (+ remove from playlist).
Future<void> showSongActions(Song song, {int? playlistId}) {
  return showAppSheet<void>(
    builder: (context) {
      final c = context.colors;
      final lib = LibraryController.to;
      final pc = PlaybackController.to;
      final live = lib.songById(song.id!) ?? song;
      return SheetScaffold(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SongArtwork(song: live, size: 64, radius: AppRadius.imageSm),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        '${live.artistOrNull ?? 'unknown_artist'.tr} • ${DurationFormatter.clockMs(live.durationMs)}',
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: c.divider),
            if (live.available) ...[
              SheetActionTile(
                icon: Icons.queue_play_next_rounded,
                label: 'action_play_next'.tr,
                onTap: () {
                  Get.back<void>();
                  pc.addNext([live]);
                },
              ),
              SheetActionTile(
                icon: Icons.playlist_play_rounded,
                label: 'action_add_queue'.tr,
                onTap: () {
                  Get.back<void>();
                  pc.addToQueue([live]);
                },
              ),
            ],
            SheetActionTile(
              icon: Icons.playlist_add_rounded,
              label: 'action_add_playlist'.tr,
              onTap: () {
                Get.back<void>();
                showAddToPlaylist([live]);
              },
            ),
            SheetActionTile(
              icon: live.favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: live.favorite
                  ? 'action_unfavorite'.tr
                  : 'action_favorite'.tr,
              selected: live.favorite,
              onTap: () {
                Get.back<void>();
                lib.toggleFavorite(live);
              },
            ),
            SheetActionTile(
              icon: Icons.info_outline_rounded,
              label: 'action_file_info'.tr,
              onTap: () {
                Get.back<void>();
                showSongInfo(live);
              },
            ),
            if (playlistId != null && playlistId > 0)
              SheetActionTile(
                icon: Icons.playlist_remove_rounded,
                label: 'action_remove_from_playlist'.tr,
                onTap: () async {
                  Get.back<void>();
                  await Get.find<PlaylistService>().removeSong(
                    playlistId,
                    live.id!,
                  );
                  ToastUtils.success('toast_removed_from_playlist'.tr);
                },
              ),
            SheetActionTile(
              icon: Icons.visibility_off_rounded,
              label: 'action_remove_from_library'.tr,
              destructive: true,
              onTap: () {
                Get.back<void>();
                confirmRemoveFromLibrary(live);
              },
            ),
          ],
        ),
      );
    },
  );
}
