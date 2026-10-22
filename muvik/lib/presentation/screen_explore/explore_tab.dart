import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/period_type.dart';
import '../../services/application/statistics_service.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/explore_collections.dart';
import '../../utils/mood_rules.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_nav.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/state_views.dart';

/// sc_kham_pha — suggestions from the device library only (P11). Mood chips
/// filter by the songs' genre tag with explicit keyword rules (P11-04, see
/// mood_rules.dart). The brand header was removed (bug fix notes); the
/// icon beside the title opens "Thống kê" (P11-06).
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final header = [const _Title()];
          if (lib.isEmpty) {
            return ListView(
              controller: scrollController,
              children: [
                ...header,
                EmptyState(
                  illustration: true,
                  title: 'library_empty_title'.tr,
                  message: 'explore_empty_desc'.tr,
                  actionLabel: 'action_scan_music'.tr,
                  onAction: () async => Get.toNamed(RouteName.scanLibrary),
                ),
              ],
            );
          }
          final most = lib.mostPlayed();
          final least = lib.leastPlayed();
          final random = lib.randomMix();
          final added = lib.recentlyAdded(limit: 50);
          final collections = ExploreCollections.build(lib.songs.toList());
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...header,
                    const SizedBox(height: 14),
                    const _SearchBox(),
                    const SizedBox(height: 20),
                    const _MoodChips(),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 170,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        children: [
                          _SuggestionCard(
                            art: AppAssets.exploreReplay,
                            title: 'explore_replay'.tr,
                            desc: 'explore_replay_desc'.tr,
                            songs: most.isNotEmpty ? most : random,
                          ),
                          const SizedBox(width: 10),
                          _SuggestionCard(
                            art: AppAssets.exploreLeast,
                            title: 'explore_least'.tr,
                            desc: 'explore_least_desc'.tr,
                            songs: least,
                          ),
                          const SizedBox(width: 10),
                          _SuggestionCard(
                            art: AppAssets.exploreRandom,
                            title: 'explore_random'.tr,
                            desc: 'explore_random_desc'.tr,
                            songs: random,
                            shuffle: true,
                          ),
                          const SizedBox(width: 10),
                          _SuggestionCard(
                            art: AppAssets.exploreReplay,
                            title: 'home_recent_title'.tr,
                            desc: 'home_recent'.tr,
                            songs: lib.recent.toList(),
                          ),
                          const SizedBox(width: 10),
                          _SuggestionCard(
                            art: AppAssets.exploreLeast,
                            title: 'explore_recently_added'.tr,
                            desc: 'home_for_you'.tr,
                            songs: added,
                          ),
                          const _MonthTop(),
                          if (lib.favorites.length >= 3) ...[
                            const SizedBox(width: 10),
                            _SuggestionCard(
                              art: AppAssets.exploreReplay,
                              title: 'explore_favorites'.tr,
                              desc: 'explore_favorites_desc'.tr,
                              songs: lib.favorites.toList(),
                            ),
                          ],
                          for (var i = 0; i < collections.length; i++) ...[
                            const SizedBox(width: 10),
                            _collectionCard(collections[i], i),
                          ],
                        ],
                      ),
                    ),
                    _SectionTitle(
                      onMore: () => AppNav.openSongs(
                        SongListArgs(
                          title: 'explore_recently_added'.tr,
                          songs: () => lib.recentlyAdded(limit: 200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverList.builder(
                itemCount: added.length.clamp(0, 6),
                itemBuilder: (context, i) {
                  final s = added[i];
                  return _SongRow(
                    song: s,
                    current: pc.currentSong?.id == s.id,
                    onTap: () => pc.playFrom(added, s),
                    onMore: () => showSongActions(s),
                  );
                },
              ),
              const SliverToBoxAdapter(child: MiniPlayerSpacer()),
            ],
          );
        }),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.5, 14, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'explore_title'.tr,
                    style: AppTypography.display.copyWith(
                      fontSize: 28,
                      height: 1.25,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'explore_subtitle'.tr,
                  style: AppTypography.bodyL.copyWith(
                    fontSize: 16,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.insights_rounded,
            tooltip: 'stats_title'.tr,
            color: c.primary,
            onPressed: () => Get.toNamed(RouteName.statistics),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Semantics(
        button: true,
        label: 'search_hint'.tr,
        excludeSemantics: true,
        child: Material(
          color: dark ? const Color(0xFF151E39) : c.surfaceInput,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: dark ? const Color(0xFF2B3661) : c.border),
          ),
          child: InkWell(
            onTap: () => Get.toNamed(RouteName.search),
            borderRadius: radius,
            child: SizedBox(
              height: 41,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, size: 24, color: c.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'search_hint'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Êm dịu / Tập trung / Sôi động, each with its own tint.
class _MoodChips extends StatelessWidget {
  const _MoodChips();

  static const _style = {
    Mood.calm: (
      Icons.eco_rounded,
      Color(0xFF6CC2C4),
      Color(0xFF182E42),
      Color(0xFF589AA7),
    ),
    Mood.focus: (
      Icons.psychology_outlined,
      Color(0xFFA996FA),
      Color(0xFF1A1753),
      Color(0xFF4A3D96),
    ),
    Mood.energetic: (
      Icons.bolt_rounded,
      Color(0xFFF78A79),
      Color(0xFF2E1A2A),
      Color(0xFFB65A58),
    ),
    Mood.romantic: (
      Icons.favorite_border_rounded,
      Color(0xFFF58AB8),
      Color(0xFF2E1A33),
      Color(0xFFA9558A),
    ),
    Mood.workout: (
      Icons.fitness_center_rounded,
      Color(0xFF7BD88F),
      Color(0xFF14301F),
      Color(0xFF3E8F57),
    ),
    Mood.party: (
      Icons.celebration_outlined,
      Color(0xFFF6C85F),
      Color(0xFF30260F),
      Color(0xFF9A7A2A),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: Mood.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = Mood.values[i];
          return _MoodChip(
            label: m.labelKey.tr,
            style: _style[m]!,
            onTap: () => AppNav.openSongs(
              SongListArgs(
                title: m.labelKey.tr,
                songs: () => lib.songsByMood(m),
                emptyMessage: 'mood_empty'.tr,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final (IconData, Color, Color, Color) style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg, border) = style;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: dark ? bg : fg.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border, width: 1.2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 19, color: fg),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.label.copyWith(
                      fontSize: 14,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.art,
    required this.title,
    required this.desc,
    required this.songs,
    this.shuffle = false,
  });

  final String art;
  final String title;
  final String desc;
  final List<Song> songs;
  final bool shuffle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF0C152A) : c.surface;
    final radius = BorderRadius.circular(14);
    return SizedBox(
      width: 168,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: dark ? const Color(0xFF1B2161) : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => AppNav.openSongs(
            SongListArgs(title: title, subtitle: desc, songs: () => songs),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 100,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF000000), Color(0x00000000)],
                    stops: [0.6, 1],
                  ).createShader(r),
                  child: Image.asset(
                    art,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                right: 6.5,
                top: 70,
                child: _PlayButton(
                  onTap: songs.isEmpty
                      ? null
                      : () => pc.playAll(songs, shuffle: shuffle),
                ),
              ),
              Positioned(
                left: 11,
                right: 8,
                top: 106,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingS.copyWith(
                          fontSize: 15,
                          height: 1.3,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent round play button on the suggestion cards.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'action_play'.tr,
      excludeSemantics: true,
      child: Material(
        color: const Color(0x99191B3A),
        shape: const CircleBorder(side: BorderSide(color: Color(0x66FFFFFF))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox.square(
            dimension: 34,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.onMore});
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(999);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.5, 18, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'explore_recently_added'.tr,
                style: AppTypography.headingM.copyWith(
                  fontSize: 20,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          Material(
            color: dark ? const Color(0xFF0F1B39) : c.surfaceSelected,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: dark ? const Color(0xFF1E2A55) : c.border,
              ),
            ),
            child: InkWell(
              onTap: onMore,
              borderRadius: radius,
              child: SizedBox(
                height: 28,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'see_all'.tr,
                        style: AppTypography.label.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: c.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.current,
    required this.onTap,
    required this.onMore,
  });

  final Song song;
  final bool current;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final artist = song.artistOrNull ?? 'unknown_artist'.tr;
    return Semantics(
      button: true,
      selected: current,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              const SizedBox(width: 18.6),
              SongArtwork(song: song, size: 52, radius: 8),
              const SizedBox(width: 14.7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.songTitle.copyWith(
                        color: current ? c.primary : c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$artist  •  ${DurationFormatter.clock(song.duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyM.copyWith(
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.more_horiz_rounded,
                tooltip: 'song_menu'.tr,
                color: c.textSecondary,
                onPressed: onMore,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title/description of an extra Explore collection (all from device songs).
(String, String) _collectionText(ExploreCollection c) => switch (c.kind) {
  ExploreKind.tiktok => ('explore_tiktok'.tr, 'explore_tiktok_desc'.tr),
  ExploreKind.morning => ('explore_morning'.tr, 'explore_morning_desc'.tr),
  ExploreKind.evening => ('explore_evening'.tr, 'explore_evening_desc'.tr),
  ExploreKind.quick => ('explore_quick'.tr, 'explore_quick_desc'.tr),
  ExploreKind.long => ('explore_long'.tr, 'explore_long_desc'.tr),
  ExploreKind.genre => (
    'explore_genre_n'.trParams({'args1': c.param ?? ''}),
    'explore_genre_desc'.tr,
  ),
  ExploreKind.artist => (
    'explore_artist_n'.trParams({'args1': c.param ?? ''}),
    'explore_artist_desc'.tr,
  ),
};

Widget _collectionCard(ExploreCollection c, int index) {
  final (title, desc) = _collectionText(c);
  const arts = [
    AppAssets.exploreLeast,
    AppAssets.exploreRandom,
    AppAssets.exploreReplay,
  ];
  return _SuggestionCard(
    art: arts[index % arts.length],
    title: title,
    desc: desc,
    songs: c.songs,
  );
}

/// "Nghe nhiều tháng này": most played songs of the current month, from the
/// listening statistics. Hidden until there is something to show.
class _MonthTop extends StatefulWidget {
  const _MonthTop();

  @override
  State<_MonthTop> createState() => _MonthTopState();
}

class _MonthTopState extends State<_MonthTop> {
  late final Future<List<Song>> _future = _load();

  Future<List<Song>> _load() async {
    try {
      final ranked = await Get.find<StatisticsService>().topSongs(
        StatsPeriod.containing(PeriodType.month, DateTime.now()),
      );
      return [
        for (final r in ranked.take(50))
          if (r.song.available) r.song,
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Song>>(
      future: _future,
      builder: (context, snap) {
        final songs = snap.data;
        if (songs == null || songs.length < 3) return const SizedBox.shrink();
        return Row(
          children: [
            const SizedBox(width: 10),
            _SuggestionCard(
              art: AppAssets.exploreReplay,
              title: 'explore_month'.tr,
              desc: 'explore_month_desc'.tr,
              songs: songs,
            ),
          ],
        );
      },
    );
  }
}
