import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../models/ui_models/period_type.dart';
import '../../services/application/statistics_service.dart';
import '../../values/app_dimensions.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_controls.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import 'statistics_tab.dart';

class StatisticsSongsArgs {
  const StatisticsSongsArgs({required this.period, required this.songs});
  final StatsPeriod period;
  final List<RankedSong> songs;
}

/// "Xem tất cả" top songs, sortable by plays or listening time (spec §7.3).
class StatisticsSongsScreen extends StatefulWidget {
  const StatisticsSongsScreen({super.key});

  @override
  State<StatisticsSongsScreen> createState() => _StatisticsSongsScreenState();
}

class _StatisticsSongsScreenState extends State<StatisticsSongsScreen> {
  final args = Get.arguments as StatisticsSongsArgs;
  bool _byTime = false;

  @override
  Widget build(BuildContext context) {
    final pc = PlaybackController.to;
    final list = [...args.songs];
    if (_byTime) {
      list.sort((a, b) {
        final c = b.listenedMs.compareTo(a.listenedMs);
        return c != 0 ? c : b.plays.compareTo(a.plays);
      });
    }
    final songs = list.map((e) => e.song).toList();
    return ScaffoldWithMiniPlayer(
      appBar: DetailAppBar(
        title: '${'stats_top_songs'.tr} • ${periodLabel(args.period)}',
      ),
      body: ListView.builder(
        itemCount: list.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                0,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: SegmentedTabs(
                labels: ['stats_sort_plays'.tr, 'stats_sort_time'.tr],
                index: _byTime ? 1 : 0,
                onChanged: (v) => setState(() => _byTime = v == 1),
              ),
            );
          }
          if (i == list.length + 1) return const MiniPlayerSpacer();
          final item = list[i - 1];
          return RankedSongRow(
            rank: i,
            item: item,
            showTime: _byTime,
            onTap: () => pc.playFrom(songs, item.song),
            onMore: () => showSongActions(item.song),
          );
        },
      ),
    );
  }
}
