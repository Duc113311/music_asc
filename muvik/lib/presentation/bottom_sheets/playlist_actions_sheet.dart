import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/data_models/playlist.dart';
import '../../values/route_name.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../dialogs/app_dialogs.dart';
import '../screens_playlist/playlist_form_screen.dart';

/// Playlist menu. The system Favorites list has no rename/delete (spec §5).
Future<void> showPlaylistActions(
  Playlist p, {
  Future<void> Function()? onPlay,
  VoidCallback? onDeleted,
}) {
  return showAppSheet<void>(
    builder: (context) {
      return SheetScaffold(
        title: p.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPlay != null && p.songCount > 0)
              SheetActionTile(
                icon: Icons.play_arrow_rounded,
                label: 'action_play_all'.tr,
                onTap: () {
                  Get.back<void>();
                  onPlay();
                },
              ),
            SheetActionTile(
              icon: Icons.edit_rounded,
              label: 'playlist_edit'.tr,
              onTap: () {
                Get.back<void>();
                Get.toNamed(
                  RouteName.playlistForm,
                  arguments: PlaylistFormArgs(editing: p),
                );
              },
            ),
            SheetActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'playlist_delete'.tr,
              destructive: true,
              onTap: () async {
                Get.back<void>();
                if (await confirmDeletePlaylist(p)) onDeleted?.call();
              },
            ),
          ],
        ),
      );
    },
  );
}
