import 'package:get/get.dart';

import '../../models/data_models/song.dart';
import '../../models/ui_models/library_groups.dart';
import '../../values/route_name.dart';

/// Arguments of the generic song list screen. [songs] is re-evaluated inside
/// Obx so favorites/exclusions update the open list live.
class SongListArgs {
  const SongListArgs({
    required this.title,
    required this.songs,
    this.subtitle,
    this.group,
    this.showSort = false,
    this.emptyMessage,
  });

  final String title;
  final String? subtitle;
  final List<Song> Function() songs;
  final SongGroup? group;
  final bool showSort;
  final String? emptyMessage;
}

class AppNav {
  AppNav._();

  static Future<void>? openSongs(SongListArgs args) =>
      Get.toNamed(RouteName.songList, arguments: args);

  static Future<void>? openPlaylist(int id) =>
      Get.toNamed(RouteName.playlistDetail, arguments: id);

  /// Favorites is a system list built from the favorite flag (P10-08).
  static const int favoritesPlaylistId = -1;
}
