import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/data_models/song.dart';
import '../../utils/metadata_fallback.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/cards.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';

/// "Cắt nhạc chuông", step 1: choose the song to cut. Only songs that are on
/// the phone and playable are listed.
class RingtonePickScreen extends StatefulWidget {
  const RingtonePickScreen({super.key});

  @override
  State<RingtonePickScreen> createState() => _RingtonePickScreenState();
}

class _RingtonePickScreenState extends State<RingtonePickScreen> {
  final TextEditingController _query = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Song> _filtered(List<Song> all) {
    final q = MetadataFallback.normalize(_q.trim());
    final list = all.where((s) => s.available).toList();
    if (q.isEmpty) return list;
    return list
        .where(
          (s) =>
              MetadataFallback.normalize(s.displayTitle).contains(q) ||
              MetadataFallback.normalize(s.artistOrNull ?? '').contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'ringtone_pick_title'.tr),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.xs,
                  AppSpacing.screenH,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ringtone_pick_hint'.tr,
                      style: AppTypography.bodyM.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _query,
                      onChanged: (v) => setState(() => _q = v),
                      textInputAction: TextInputAction.search,
                      style: AppTypography.bodyL.copyWith(
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ringtone_search'.tr,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: c.iconDefault,
                        ),
                        suffixIcon: _q.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: c.iconDefault,
                                ),
                                onPressed: () {
                                  _query.clear();
                                  setState(() => _q = '');
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final songs = _filtered(lib.songs.toList());
                  if (songs.isEmpty) {
                    return EmptyState(
                      compact: true,
                      icon: Icons.music_off_rounded,
                      title: _q.isEmpty
                          ? 'library_empty_title'.tr
                          : 'search_no_results'.tr,
                      message: '',
                    );
                  }
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, i) {
                      final s = songs[i];
                      return SongTile(
                        song: s,
                        trailing: Icon(
                          Icons.content_cut_rounded,
                          color: c.primary,
                        ),
                        onTap: () =>
                            Get.toNamed(RouteName.ringtoneEdit, arguments: s),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
