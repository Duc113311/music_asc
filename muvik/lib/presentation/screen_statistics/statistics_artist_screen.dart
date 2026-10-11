import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/period_type.dart';
import '../../services/application/statistics_service.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/metadata_fallback.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/primary_button.dart';
import '../common_components/state_views.dart';
import 'statistics_screen.dart';

class StatisticsArtistArgs {
  const StatisticsArtistArgs({required this.artist, required this.period});

  /// Null = "Không rõ" group.
  final String? artist;
  final StatsPeriod period;
}

/// Artist statistics for the selected period; Back returns to the same
/// period (spec §7.3).
class StatisticsArtistScreen extends StatefulWidget {
  const StatisticsArtistScreen({super.key});

  @override
  State<StatisticsArtistScreen> createState() => _StatisticsArtistScreenState();
}

class _StatisticsArtistScreenState extends State<StatisticsArtistScreen> {
  final args = Get.arguments as StatisticsArtistArgs;
  late final List<Song> songs = _artistSongs();
  late Future<PeriodStats> _stats = _load();

  List<Song> _artistSongs() {
    final key = args.artist == null
        ? null
        : MetadataFallback.normalize(args.artist!);
    return LibraryController.to.songs
        .where(
          (s) => key == null
              ? s.artistOrNull == null
              : (s.artistOrNull != null &&
                    MetadataFallback.normalize(s.artistOrNull!) == key),
        )
        .toList();
  }

  Future<PeriodStats> _load() => Get.find<StatisticsService>().load(
    args.period,
    songIds: songs.map((s) => s.id!).toList(),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final name = args.artist ?? 'unknown_artist'.tr;
    return ScaffoldWithMiniPlayer(
      appBar: DetailAppBar(title: name),
      body: FutureBuilder<PeriodStats>(
        future: _stats,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(
              message: 'stats_load_failed'.tr,
              onRetry: () async => setState(() => _stats = _load()),
            );
          }
          final s = snap.data;
          if (s == null) return const LoadingState();
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(
                  periodLabel(args.period),
                  style: AppTypography.bodyL.copyWith(color: c.textSecondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                child: Row(
                  children: [
                    _Stat(
                      label: 'stats_listen_time'.tr,
                      value: DurationFormatter.listening(s.totalMs),
                    ),
                    _Stat(label: 'stats_plays'.tr, value: '${s.plays}'),
                    _Stat(
                      label: 'stats_songs_listened'.tr,
                      value: '${s.distinctSongs}',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: PrimaryButton(
                  label: 'stats_play_artist'.tr,
                  icon: Icons.play_arrow_rounded,
                  onPressed: songs.any((x) => x.available)
                      ? () => pc.playAll(songs)
                      : null,
                ),
              ),
              SectionHeader(title: 'stats_top_songs'.tr),
              if (s.topSongs.isEmpty)
                EmptyState(
                  compact: true,
                  title: 'stats_no_data'.tr,
                  icon: Icons.insights_rounded,
                )
              else
                for (var i = 0; i < s.topSongs.length; i++)
                  RankedSongRow(
                    rank: i + 1,
                    item: s.topSongs[i],
                    onTap: () => pc.playFrom(
                      s.topSongs.map((e) => e.song).toList(),
                      s.topSongs[i].song,
                    ),
                    onMore: () => showSongActions(s.topSongs[i].song),
                  ),
              const MiniPlayerSpacer(),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.headingS.copyWith(color: c.textPrimary),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
