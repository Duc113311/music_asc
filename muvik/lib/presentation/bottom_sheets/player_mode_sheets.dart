import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/repeat_mode.dart';
import '../common_components/primary_bottom_sheet.dart';

/// Shuffle: "Theo thứ tự / Ngẫu nhiên" — applies immediately and closes.
Future<void> showShuffleSheet() => showAppSheet<void>(
  builder: (context) {
    final pc = PlaybackController.to;
    final on = pc.state.value.shuffle;
    return SheetScaffold(
      title: 'shuffle_title'.tr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionTile(
            icon: Icons.format_list_numbered_rounded,
            label: 'shuffle_off'.tr,
            selected: !on,
            trailing: !on ? const Icon(Icons.check_rounded) : null,
            onTap: () {
              Get.back<void>();
              pc.setShuffle(false);
            },
          ),
          SheetActionTile(
            icon: Icons.shuffle_rounded,
            label: 'shuffle_on'.tr,
            selected: on,
            trailing: on ? const Icon(Icons.check_rounded) : null,
            onTap: () {
              Get.back<void>();
              pc.setShuffle(true);
            },
          ),
        ],
      ),
    );
  },
);

/// Repeat: Off / All / One — applies immediately.
Future<void> showRepeatSheet() => showAppSheet<void>(
  builder: (context) {
    final pc = PlaybackController.to;
    final cur = pc.state.value.repeat;
    Widget tile(RepeatMode m, IconData icon, String key) => SheetActionTile(
      icon: icon,
      label: key.tr,
      selected: cur == m,
      trailing: cur == m ? const Icon(Icons.check_rounded) : null,
      onTap: () {
        Get.back<void>();
        pc.setRepeat(m);
      },
    );
    return SheetScaffold(
      title: 'repeat_title'.tr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile(RepeatMode.off, Icons.arrow_right_alt_rounded, 'repeat_off'),
          tile(RepeatMode.all, Icons.repeat_rounded, 'repeat_all'),
          tile(RepeatMode.one, Icons.repeat_one_rounded, 'repeat_one'),
        ],
      ),
    );
  },
);

/// Favorite sheet for the current song; the change is saved to the DB and
/// reflected on every screen (P12-05).
Future<void> showFavoriteSheet(Song song) => showAppSheet<void>(
  builder: (context) {
    final lib = LibraryController.to;
    final live = lib.songById(song.id!) ?? song;
    return SheetScaffold(
      title: live.displayTitle,
      child: SheetActionTile(
        icon: live.favorite
            ? Icons.heart_broken_rounded
            : Icons.favorite_rounded,
        label: live.favorite ? 'action_unfavorite'.tr : 'action_favorite'.tr,
        onTap: () {
          Get.back<void>();
          lib.toggleFavorite(live);
        },
      ),
    );
  },
);
