import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../utils/metadata_fallback.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_inputs.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';
import '../common_components/song_tile.dart';

/// Multi-select picker for "Thêm bài". Filtering never drops the current
/// selection (spec §5). Returns the chosen song ids, or null if dismissed.
Future<List<int>?> showSongPicker({required Set<int> exclude}) =>
    showAppSheet<List<int>>(builder: (_) => _SongPicker(exclude: exclude));

class _SongPicker extends StatefulWidget {
  const _SongPicker({required this.exclude});
  final Set<int> exclude;

  @override
  State<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends State<_SongPicker> {
  final _query = TextEditingController();
  final List<int> _selected = [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final q = MetadataFallback.normalize(_query.text);
    final songs = lib.songs
        .where((s) => s.available && !widget.exclude.contains(s.id))
        .where(
          (s) =>
              q.isEmpty ||
              MetadataFallback.normalize(
                '${s.displayTitle} ${s.artist ?? ''} ${s.album ?? ''}',
              ).contains(q),
        )
        .toList();
    final screenH = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SizedBox(
      // The sheet is capped at 0.9 of the screen and also pads for the
      // keyboard, so a fixed 0.85 overflowed while typing a search.
      height: (screenH * 0.9 - keyboard).clamp(0.0, screenH * 0.85),
      child: SheetScaffold(
        title: 'playlist_add_songs'.tr,
        subtitle: 'selected_n'.trParams({'args1': '${_selected.length}'}),
        scrollable: false,
        padding: EdgeInsets.zero,
        footer: PrimaryButton(
          label: 'action_confirm'.tr,
          onPressed: _selected.isEmpty
              ? null
              : () async => Get.back(result: List<int>.of(_selected)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSearchField(
                controller: _query,
                hint: 'search_hint'.tr,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: songs.isEmpty
                  ? Center(
                      child: Text(
                        'search_no_results'.tr,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, i) {
                        final s = songs[i];
                        final on = _selected.contains(s.id);
                        return SongTile(
                          song: s,
                          dense: true,
                          onTap: () => setState(
                            () => on
                                ? _selected.remove(s.id)
                                : _selected.add(s.id!),
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.md,
                            ),
                            child: AppCheckbox(value: on),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
