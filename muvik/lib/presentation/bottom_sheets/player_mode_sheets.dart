import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/data_models/song.dart';
import '../common_components/primary_bottom_sheet.dart';

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
