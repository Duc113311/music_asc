import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../models/data_models/playback_snapshot.dart';
import '../../models/data_models/song.dart';
import '../../services/application/library_data_service.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/song_artwork.dart';
import '../dialogs/app_dialogs.dart';
import '../screens_playlist/playlist_form_screen.dart';

/// Sc_bthSheet_phattiep: current song, upcoming entries, drag to reorder,
/// remove (with undo) and clear upcoming (P12-06, P12-07).
Future<void> showQueueSheet() =>
    showAppSheet<void>(builder: (_) => const _QueueSheet());

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final library = Get.find<LibraryDataService>();
    return Obx(() {
      final s = pc.state.value;
      final upcoming = s.upcoming;
      final cached = <int, Song>{
        for (final e in s.entries)
          if (library.cached(e.songId) != null)
            e.songId: library.cached(e.songId)!,
      };
      return FutureBuilder<Map<int, Song>>(
        initialData: cached,
        future: library.resolve(s.entries.map((e) => e.songId)),
        builder: (context, snap) {
          final songs = snap.data ?? const <int, Song>{};
          return SheetScaffold(
            title: 'queue_title'.tr,
            subtitle: 'count_songs_n'.trParams({
              'args1': '${s.entries.length}',
            }),
            scrollable: false,
            padding: EdgeInsets.zero,
            trailing: TextButton.icon(
              onPressed: () => pc.setShuffle(!s.shuffle),
              icon: Icon(
                Icons.shuffle_rounded,
                color: s.shuffle ? c.primary : c.iconDefault,
              ),
              label: Text(
                s.shuffle ? 'shuffle_on'.tr : 'shuffle_off'.tr,
                style: AppTypography.label.copyWith(
                  color: s.shuffle ? c.primary : c.textSecondary,
                ),
              ),
            ),
            footer: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: s.entries.isEmpty
                        ? null
                        : () {
                            Get.back<void>();
                            Get.toNamed(
                              RouteName.playlistForm,
                              arguments: PlaylistFormArgs(
                                addSongIds: s.entries
                                    .map((e) => e.songId)
                                    .toSet()
                                    .toList(),
                              ),
                            );
                          },
                    icon: Icon(Icons.playlist_add_rounded, color: c.primary),
                    label: Text(
                      'queue_save_playlist'.tr,
                      style: AppTypography.label.copyWith(color: c.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: upcoming.isEmpty ? null : confirmClearQueue,
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: upcoming.isEmpty ? c.textDisabled : c.error,
                    ),
                    label: Text(
                      'queue_clear'.tr,
                      style: AppTypography.label.copyWith(
                        color: upcoming.isEmpty ? c.textDisabled : c.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                if (s.current != null)
                  SliverToBoxAdapter(
                    child: _QueueRow(
                      song: songs[s.current!.songId],
                      current: true,
                      onTap: () => Get.back<void>(),
                    ),
                  ),
                if (upcoming.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Text(
                        'queue_up_next'.tr,
                        style: AppTypography.label.copyWith(color: c.textMuted),
                      ),
                    ),
                  ),
                SliverReorderableList(
                  itemCount: upcoming.length,
                  onReorder: (from, to) {
                    if (to > from) to -= 1;
                    pc.handler.reorderUpcoming(from, to);
                  },
                  itemBuilder: (context, i) {
                    final QueueEntry e = upcoming[i];
                    return Material(
                      key: ValueKey(e.entryId),
                      color: Colors.transparent,
                      child: _QueueRow(
                        song: songs[e.songId],
                        index: i,
                        onTap: () => pc.handler.playEntry(e.entryId),
                        onRemove: () => _remove(e, i),
                      ),
                    );
                  },
                ),
                if (upcoming.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'queue_empty'.tr,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> _remove(QueueEntry e, int index) async {
    final pc = PlaybackController.to;
    final removed = await pc.handler.removeEntry(e.entryId);
    if (!removed) return;
    final currentAtRemoval = pc.state.value.current?.entryId;
    ToastUtils.show(
      'toast_removed_from_queue'.tr,
      actionLabel: 'action_undo'.tr,
      onAction: () {
        // Undo only while the session hasn't moved on (spec §9.3).
        if (pc.state.value.current?.entryId == currentAtRemoval) {
          pc.handler.reinsertAfterCurrent(e.songId, index);
        }
      },
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.song,
    this.current = false,
    this.index,
    this.onTap,
    this.onRemove,
  });

  final Song? song;
  final bool current;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = song;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 6,
          ),
          child: Row(
            children: [
              SongArtwork(song: s, size: 48),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s?.displayTitle ?? '…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.songTitle.copyWith(
                        color: current ? c.primary : c.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        if (current) ...[
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: c.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'queue_now_playing'.tr,
                            style: AppTypography.caption.copyWith(
                              color: c.primary,
                            ),
                          ),
                        ] else
                          Text(
                            s == null
                                ? ''
                                : DurationFormatter.clockMs(s.durationMs),
                            style: AppTypography.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'queue_remove'.tr,
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: c.iconDefault,
                  ),
                ),
              if (index != null)
                ReorderableDragStartListener(
                  index: index!,
                  child: Semantics(
                    label: 'queue_reorder'.tr,
                    child: SizedBox.square(
                      dimension: AppSizes.touch,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: c.iconDefault,
                      ),
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
