import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../utils/mood_rules.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../bottom_sheets/song_actions_sheet.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_nav.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/mini_player.dart';
import '../common_components/song_artwork.dart';
import '../common_components/song_tile.dart';
import '../common_components/state_views.dart';
import '../../tour/tour_anchor.dart';
import '../../tour/tour_steps.dart';

/// Greeting by device hour (spec §4.2): morning 05–10, noon 11–13,
/// afternoon 14–17, evening 18–04.
String greetingKey(int hour) {
  if (hour >= 5 && hour <= 10) return 'greeting_morning';
  if (hour >= 11 && hour <= 13) return 'greeting_noon';
  if (hour >= 14 && hour <= 17) return 'greeting_afternoon';
  return 'greeting_evening';
}

/// sc_home — every block uses real local data; nothing is filled with demo
/// content (P08-05..P08-10).
class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    required this.scrollController,
    required this.onOpenLibrary,
  });
  final ScrollController scrollController;
  final VoidCallback onOpenLibrary;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with WidgetsBindingObserver {
  late int _hour = DateTime.now().hour;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleHourTick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshHour();
  }

  void _scheduleHourTick() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    _timer?.cancel();
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      _refreshHour();
      _scheduleHourTick();
    });
  }

  void _refreshHour() {
    final h = DateTime.now().hour;
    if (h != _hour && mounted) setState(() => _hour = h);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final recent = lib.recent.take(5).toList();
          return CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.xs,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                '${greetingKey(_hour).tr} 👋',
                                style: AppTypography.headingL.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'home_subtitle'.tr,
                              style: AppTypography.bodyL.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'action_search'.tr,
                        filled: true,
                        onPressed: () => Get.toNamed(RouteName.search),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: lib.isEmpty
                    ? _YourMusicCard(onOpenLibrary: widget.onOpenLibrary)
                    : const _HomeBanners(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.sm,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppChip(
                        label: 'home_recent'.tr,
                        icon: Icons.history_rounded,
                        onTap: () => AppNav.openSongs(
                          SongListArgs(
                            title: 'home_recent_title'.tr,
                            songs: () => lib.recent,
                            emptyMessage: 'home_recent_empty'.tr,
                          ),
                        ),
                      ),
                      AppChip(
                        label: 'favorites'.tr,
                        icon: Icons.favorite_border_rounded,
                        onTap: () =>
                            AppNav.openPlaylist(AppNav.favoritesPlaylistId),
                      ),
                    ],
                  ),
                ),
              ),
              if (!lib.isEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'home_for_you'.tr,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      14,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _ForYouRow()),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(
                  padding: _headerPad,
                  title: 'home_recent_title'.tr,
                  onMore: recent.isEmpty
                      ? null
                      : () => AppNav.openSongs(
                            SongListArgs(
                              title: 'home_recent_title'.tr,
                              songs: () => lib.recent,
                            ),
                          ),
                ),
              ),
              if (recent.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    compact: true,
                    icon: Icons.history_rounded,
                    title: 'home_recent_empty'.tr,
                    message: 'home_recent_empty_desc'.tr,
                    actionLabel: 'home_open_library'.tr,
                    onAction: () async => widget.onOpenLibrary(),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: recent.length,
                  itemBuilder: (context, i) {
                    final Song s = recent[i];
                    return SongTile(
                      song: s,
                      isCurrent: pc.currentSong?.id == s.id,
                      onTap: () => pc.playFrom(lib.recent, s),
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

const _headerPad = EdgeInsets.fromLTRB(
  AppSpacing.screenH,
  AppSpacing.sm,
  AppSpacing.xs,
  0,
);

/// One hero slide of Home: artwork + copy + one action, in the colors of its
/// accent (purple Daily Mix, cyan "not played in a while", coral energy).
class _SlideData {
  const _SlideData({
    required this.image,
    required this.accent,
    required this.badge,
    required this.titleSpans,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.buttonFill,
    required this.buttonText,
    required this.onTap,
    this.tourAnchor,
  });

  final String image;

  /// Eyebrow, card border and the active page dot.
  final Color accent;
  final String badge;
  final List<TextSpan> titleSpans;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final Color buttonFill;
  final Color buttonText;
  final VoidCallback onTap;

  /// Set on the slide whose button the first-run tour spotlights.
  final String? tourAnchor;

  String get title => titleSpans.map((s) => s.text).join();
}

/// Swipeable hero slides on Home (one at a time, dots under the card).
class _HomeBanners extends StatefulWidget {
  const _HomeBanners();

  @override
  State<_HomeBanners> createState() => _HomeBannersState();
}

class _HomeBannersState extends State<_HomeBanners> {
  final _controller = PageController();
  int _page = 0;

  /// Slide artwork size (1706x922): the card keeps that ratio, nothing is
  /// cropped.
  static const double _ratio = 1706 / 922;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// "Daily Mix" -> white "Daily " + lavender "Mix".
  List<TextSpan> _twoTone(String t, Color first, Color rest) {
    final i = t.indexOf(' ');
    if (i <= 0) return [TextSpan(text: t, style: TextStyle(color: rest))];
    return [
      TextSpan(text: t.substring(0, i + 1), style: TextStyle(color: first)),
      TextSpan(text: t.substring(i + 1), style: TextStyle(color: rest)),
    ];
  }

  /// First line white, the other lines in [rest].
  List<TextSpan> _lines(String t, Color first, Color rest) {
    final i = t.indexOf('\n');
    if (i <= 0) return [TextSpan(text: t, style: TextStyle(color: rest))];
    return [
      TextSpan(text: t.substring(0, i + 1), style: TextStyle(color: first)),
      TextSpan(text: t.substring(i + 1), style: TextStyle(color: rest)),
    ];
  }

  // Looked up when a button is tapped, not while building the slides.
  LibraryController get _lib => LibraryController.to;
  PlaybackController get _pc => PlaybackController.to;

  List<_SlideData> _slides() {
    const purple = Color(0xFF8E6BFF);
    const cyan = Color(0xFF7FDCFB);
    const coral = Color(0xFFF0746E);
    return [
      _SlideData(
        image: AppAssets.homeSlide1,
        accent: purple,
        badge: 'home_s1_badge'.tr,
        titleSpans: _twoTone(
          'home_s1_title'.tr,
          Colors.white,
          const Color(0xFFB9A3FF),
        ),
        subtitle: 'home_s1_sub'.tr,
        buttonLabel: 'home_s1_cta'.tr,
        buttonIcon: Icons.shuffle_rounded,
        buttonFill: const Color(0xFF7C5CF4),
        buttonText: Colors.white,
        onTap: () => _pc.playAll(_lib.songs.toList(), shuffle: true),
        tourAnchor: TourAnchors.homeShuffle,
      ),
      _SlideData(
        image: AppAssets.homeSlide2,
        accent: cyan,
        badge: 'home_s2_badge'.tr,
        titleSpans: [
          TextSpan(
            text: 'home_s2_title'.tr,
            style: const TextStyle(color: Color(0xFF8FE3FF)),
          ),
        ],
        subtitle: 'home_s2_sub'.tr,
        buttonLabel: 'home_s2_cta'.tr,
        buttonIcon: Icons.explore_outlined,
        buttonFill: cyan,
        buttonText: const Color(0xFF08233A),
        // "Rediscover": the list of the least played songs.
        onTap: () {
          final least = _lib.leastPlayed();
          AppNav.openSongs(
            SongListArgs(
              title: 'explore_least'.tr,
              subtitle: 'explore_least_desc'.tr,
              songs: () => least,
              emptyMessage: 'home_recent_empty'.tr,
            ),
          );
        },
      ),
      _SlideData(
        image: AppAssets.homeSlide3,
        accent: coral,
        badge: 'home_s3_badge'.tr,
        titleSpans: _lines('home_s3_title'.tr, Colors.white, coral),
        subtitle: 'home_s3_sub'.tr,
        buttonLabel: 'home_listen_now'.tr,
        buttonIcon: Icons.play_arrow_rounded,
        buttonFill: const Color(0xFFEF7A74),
        buttonText: Colors.white,
        // Upbeat genres first, else what is played most, else a mix.
        onTap: () {
          var songs = _lib.songsByMood(Mood.energetic);
          if (songs.isEmpty) songs = _lib.mostPlayed();
          if (songs.isEmpty) songs = _lib.randomMix();
          _pc.playAll(songs, shuffle: true);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides();
    final page = _page.clamp(0, slides.length - 1);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final cardW = box.maxWidth - 2 * AppSpacing.screenH;
              return SizedBox(
                height: cardW / _ratio,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                    ),
                    child: _SlideCard(data: slides[i]),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < slides.length; i++)
                Semantics(
                  button: true,
                  selected: i == page,
                  label: '${i + 1} / ${slides.length}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: AppMotion.overlay,
                      curve: AppMotion.curve,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: AnimatedContainer(
                        duration: AppMotion.state,
                        curve: AppMotion.curve,
                        width: i == page ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i == page
                              ? slides[i].accent
                              : const Color(0xFF3A4160),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;
    return Semantics(
      container: true,
      label: '${data.badge}. ${data.title.replaceAll('\n', ' ')}. '
          '${data.subtitle.replaceAll('\n', ' ')}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: data.accent.withValues(alpha: 0.35)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final titleSize = (w * 0.078).clamp(22.0, 30.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    data.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.medium,
                  ),
                  Padding(
                    padding: EdgeInsets.all((w * 0.05).clamp(14.0, 20.0)),
                    child: SizedBox(
                      width: w * 0.56,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The copy shrinks to fit the space above the button,
                          // so a long translation or a large system font scales
                          // the text down instead of overflowing the card.
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: w * 0.56,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.badge.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: data.accent,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text.rich(
                                      TextSpan(children: data.titleSpans),
                                      style: AppTypography.headingL.copyWith(
                                        fontSize: titleSize,
                                        height: 1.08,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      data.subtitle,
                                      style: AppTypography.bodyM.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          data.tourAnchor == null
                              ? _SlideButton(data: data)
                              : TourAnchor(
                                  id: data.tourAnchor!,
                                  child: _SlideButton(data: data),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlideButton extends StatelessWidget {
  const _SlideButton({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.buttonLabel,
      excludeSemantics: true,
      child: Material(
        color: data.buttonFill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: data.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.buttonIcon, size: 20, color: data.buttonText),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      data.buttonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: data.buttonText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
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

class _YourMusicCard extends StatelessWidget {
  const _YourMusicCard({required this.onOpenLibrary});
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    final lib = LibraryController.to;
    return Obx(() {
      final s = pc.state.value;
      final song = s.currentSong;
      if (song == null) {
        // Never played: invite to pick music, no demo song (P08-07).
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            child: lib.isEmpty
                ? EmptyState(
                    compact: true,
                    illustration: true,
                    title: 'library_empty_title'.tr,
                    message: lib.hasPermission
                        ? 'library_empty_desc'.tr
                        : 'no_audio_permission'.tr,
                    actionLabel: 'action_scan_music'.tr,
                    onAction: () async => Get.toNamed(RouteName.scanLibrary),
                  )
                : EmptyState(
                    compact: true,
                    icon: Icons.queue_music_rounded,
                    title: 'home_pick_music'.tr,
                    message: 'home_pick_music_desc'.tr,
                    actionLabel: 'home_open_library'.tr,
                    onAction: () async => onOpenLibrary(),
                  ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: AppCard(
          onTap: pc.openNowPlaying,
          child: Row(
            children: [
              SongArtwork(song: song, size: 120, radius: AppRadius.input),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.playing
                          ? 'home_now_playing'.tr.toUpperCase()
                          : 'home_continue'.tr.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: c.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingS.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      song.artistOrNull ?? 'unknown_artist'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyM.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        PlayPauseButton(
                          playing: s.playing,
                          loading: s.loading,
                          onPressed: pc.togglePlay,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            s.playing ? 'action_pause'.tr : 'home_continue'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.more_vert_rounded,
                          tooltip: 'song_menu'.tr,
                          onPressed: () => showSongActions(song),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// "Playlist dành cho bạn": user playlists first, then local rule-based
/// groups (favorites, most played, recently added). No online content.
class _ForYouRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lib = LibraryController.to;
    final pc = PlaybackController.to;
    return Obx(() {
      final cards = <Widget>[];
      if (lib.favorites.isNotEmpty) {
        cards.add(
          CoverCard(
            width: _cardWidth,
            title: 'favorites'.tr,
            subtitle: 'count_songs_n'.trParams({
              'args1': '${lib.favorites.length}',
            }),
            coverSong: lib.favorites.first,
            placeholderIcon: Icons.favorite_rounded,
            onTap: () => AppNav.openPlaylist(AppNav.favoritesPlaylistId),
            onPlay: () => pc.playAll(lib.favorites),
          ),
        );
      }
      for (final p in lib.playlists.take(6)) {
        cards.add(
          CoverCard(
            width: _cardWidth,
            title: p.name,
            subtitle: 'count_songs_n'.trParams({'args1': '${p.songCount}'}),
            coverSong:
                p.firstSongId == null ? null : lib.songById(p.firstSongId!),
            onTap: () => AppNav.openPlaylist(p.id!),
            onPlay: p.songCount == 0
                ? null
                : () async {
                    final songs = await lib.playlistSongs(p.id!);
                    await pc.playAll(songs);
                  },
          ),
        );
      }
      final most = lib.mostPlayed(limit: 50);
      if (most.isNotEmpty) {
        cards.add(_auto('explore_replay'.tr, most, Icons.replay_rounded));
      }
      final added = lib.recentlyAdded(limit: 50);
      if (added.isNotEmpty) {
        cards.add(
          _auto('explore_recently_added'.tr, added, Icons.new_releases_rounded),
        );
      }
      // Compact cards (bug fix notes: the covers were too large).
      return SizedBox(
        height: _cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) => cards[i],
        ),
      );
    });
  }

  static const double _cardWidth = 170;
  static const double _cardHeight = 172;

  Widget _auto(String title, List<Song> songs, IconData icon) {
    final pc = PlaybackController.to;
    return CoverCard(
      width: _cardWidth,
      title: title,
      subtitle: 'count_songs_n'.trParams({'args1': '${songs.length}'}),
      coverSong: songs.first,
      placeholderIcon: icon,
      onTap: () =>
          AppNav.openSongs(SongListArgs(title: title, songs: () => songs)),
      onPlay: () => pc.playAll(songs),
    );
  }
}

/// The hero slides alone, for render tests (they need no controllers).
@visibleForTesting
Widget homeBannersForTest() => const _HomeBanners();
