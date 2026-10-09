import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/mood_rules.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_nav.dart';
import '../common_components/cards.dart';
import '../common_components/melo_logo.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/state_views.dart';

/// sc_kham_pha — suggestions from the device library only (P11). Mood chips
/// filter by the songs' genre tag with explicit keyword rules (P11-04, see
/// mood_rules.dart). The wave icon at the top right opens "Thống kê"
/// (P11-06).
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
          final header = [const _BrandHeader(), const _Title()];
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
                    const SizedBox(height: 13),
                    const _MoodChips(),
                    const SizedBox(height: 13),
                    SizedBox(
                      height: 190,
                      child: Row(
                        children: [
                          const SizedBox(width: 11),
                          Expanded(
                            flex: 125,
                            child: _SuggestionCard(
                              art: AppAssets.exploreReplay,
                              title: 'explore_replay'.tr,
                              desc: 'explore_replay_desc'.tr,
                              songs: most.isNotEmpty ? most : random,
                              titleMaxWidth: 72,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            flex: 118,
                            child: _SuggestionCard(
                              art: AppAssets.exploreLeast,
                              title: 'explore_least'.tr,
                              desc: 'explore_least_desc'.tr,
                              songs: least,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            flex: 114,
                            child: _SuggestionCard(
                              art: AppAssets.exploreRandom,
                              title: 'explore_random'.tr,
                              desc: 'explore_random_desc'.tr,
                              songs: random,
                              shuffle: true,
                            ),
                          ),
                          const SizedBox(width: 9),
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

/// "Melo" wordmark with tagline, and the wave button to Statistics.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MeloLogo(
                  bars: [
                    MeloBar(2.2, 13, [Color(0xFF8E6BFA), Color(0xFF6D5CF6)]),
                    MeloBar(2.2, 25, [
                      Color(0xFFA77CFB),
                      Color(0xFF6B6CF7),
                    ], gap: 5.4),
                    MeloBar(2.2, 18, [
                      Color(0xFF9C7BFA),
                      Color(0xFF6C78F6),
                    ], gap: 4.2),
                    MeloBar(2.2, 9, [
                      Color(0xFF7F86F8),
                      Color(0xFF6E8CF7),
                    ], gap: 4.4),
                  ],
                  fontSize: 31,
                  textGap: 9,
                  textColors: [
                    Color(0xFFB57BFF),
                    Color(0xFF8C93FF),
                    Color(0xFF52B8FF),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 35, top: 1),
                  child: Text(
                    'splash_tagline'.tr.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTypography.caption.copyWith(
                      fontSize: 7.5,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.6,
                      color: const Color(0xFF8A86C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'stats_title'.tr,
            child: Semantics(
              button: true,
              label: 'stats_title'.tr,
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => Get.toNamed(RouteName.statistics),
                radius: 26,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(child: _WaveIcon(color: c.primary)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small multicolor wave (top-right of the mockup).
class _WaveIcon extends StatelessWidget {
  const _WaveIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    const heights = <double>[7, 13, 9, 22, 27, 11, 17];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < heights.length; i++)
          Container(
            width: 2.1,
            height: heights[i],
            margin: const EdgeInsets.symmetric(horizontal: 1.3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: i.isEven
                    ? const [Color(0xFF6FD6F6), Color(0xFF7C6CF8)]
                    : [color, const Color(0xFF6A5CF6)],
              ),
            ),
          ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.5, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'explore_title'.tr,
              style: AppTypography.display.copyWith(
                fontSize: 26.5,
                height: 1.25,
                color: c.textPrimary,
              ),
            ),
          ),
          Text(
            'explore_subtitle'.tr,
            style: AppTypography.bodyL.copyWith(
              fontSize: 15.5,
              color: c.textSecondary,
            ),
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
  };

  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 15.6, 0),
      child: Row(
        children: [
          for (final (i, m) in Mood.values.indexed) ...[
            if (i > 0) const SizedBox(width: 7.2),
            Expanded(
              flex: const [114, 117, 109][i],
              child: _MoodChip(
                label: m.labelKey.tr,
                style: _style[m]!,
                onTap: () => AppNav.openSongs(
                  SongListArgs(
                    title: m.labelKey.tr,
                    songs: () => lib.songsByMood(m),
                    emptyMessage: 'mood_empty'.tr,
                  ),
                ),
              ),
            ),
          ],
        ],
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
            height: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
              ],
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
    this.titleMaxWidth = double.infinity,
  });

  /// Narrows the title so it breaks like the mockup ("Nghe lại / hôm nay").
  final double titleMaxWidth;
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
    return Material(
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
              height: 116,
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
              top: 85.5,
              child: _PlayButton(
                onTap: songs.isEmpty
                    ? null
                    : () => pc.playAll(songs, shuffle: shuffle),
              ),
            ),
            Positioned(
              left: 11,
              right: 8,
              top: 113,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: titleMaxWidth),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingS.copyWith(
                        fontSize: 12.3,
                        height: 1.3,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10.5,
                      height: 1.45,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 18.6),
              SongArtwork(song: song, size: 47, radius: 6),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: current ? c.primary : c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$artist  •  ${DurationFormatter.clock(song.duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyM.copyWith(
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'song_menu'.tr,
                onPressed: onMore,
                icon: Icon(Icons.more_horiz_rounded, color: c.textSecondary),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
