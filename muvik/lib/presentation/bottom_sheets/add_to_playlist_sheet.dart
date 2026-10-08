import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/data_models/playlist.dart';
import '../../models/data_models/song.dart';
import '../../services/application/playlist_service.dart';
import '../../utils/metadata_fallback.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_inputs.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';
import '../common_components/song_artwork.dart';
import '../screens_playlist/playlist_form_screen.dart';

/// "Thêm vào playlist": pick one or more playlists or create a new one.
/// Duplicates are reported, never inserted twice (P10-03).
Future<void> showAddToPlaylist(List<Song> songs) {
  if (songs.isEmpty) return Future.value();
  return showAppSheet<void>(builder: (_) => _AddToPlaylistSheet(songs: songs));
}

class _AddToPlaylistSheet extends StatefulWidget {
  const _AddToPlaylistSheet({required this.songs});
  final List<Song> songs;

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  final _query = TextEditingController();
  final Set<int> _selected = {};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final service = Get.find<PlaylistService>();
    final ids = widget.songs.map((s) => s.id!).toList();
    var added = 0;
    var dup = 0;
    for (final p in _selected) {
      final r = await service.addSongs(p, ids);
      added += r.added;
      dup += r.duplicates;
    }
    Get.back<void>();
    if (added > 0) {
      ToastUtils.success('toast_added_playlist'.tr);
    } else if (dup > 0) {
      ToastUtils.show('toast_already_in_playlist'.tr, type: ToastType.warning);
    }
  }

  Future<void> _createNew() async {
    Get.back<void>();
    await Get.toNamed(
      RouteName.playlistForm,
      arguments: PlaylistFormArgs(
        addSongIds: widget.songs.map((s) => s.id!).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    return SheetScaffold(
      title: 'add_to_playlist_title'.tr,
      footer: PrimaryButton(
        label: 'action_done'.tr,
        onPressed: _selected.isEmpty ? null : _done,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSearchField(
            controller: _query,
            hint: 'search_playlist_hint'.tr,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: c.surfaceSelected,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.input),
              onTap: _createNew,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, color: c.primary),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'playlist_create_new'.tr,
                      style: AppTypography.label.copyWith(color: c.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(() {
            final q = MetadataFallback.normalize(_query.text);
            final List<Playlist> list = lib.playlists
                .where(
                  (p) =>
                      q.isEmpty ||
                      MetadataFallback.normalize(p.name).contains(q),
                )
                .toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  lib.playlists.isEmpty
                      ? 'playlist_none_yet'.tr
                      : 'search_no_results'.tr,
                  style: AppTypography.bodyM.copyWith(color: c.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                for (final p in list)
                  SelectableOptionTile(
                    multi: true,
                    title: p.name,
                    subtitle: 'count_songs_n'.trParams({
                      'args1': '${p.songCount}',
                    }),
                    selected: _selected.contains(p.id),
                    leading: p.firstSongId == null
                        ? const ArtworkPlaceholder(
                            size: 48,
                            icon: Icons.queue_music_rounded,
                          )
                        : SongArtwork(
                            song: lib.songById(p.firstSongId!),
                            size: 48,
                          ),
                    onTap: () => setState(() {
                      if (!_selected.remove(p.id)) _selected.add(p.id!);
                    }),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
