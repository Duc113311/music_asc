/// Anchor ids the first-run tour highlights. Each screen wraps the widget it
/// wants spotlighted in a `TourAnchor` with one of these ids.
class TourAnchors {
  TourAnchors._();

  static const String homeShuffle = 'home_shuffle';
  static const String librarySong = 'library_song';
  static const String statsPeriod = 'stats_period';
}

class TourStep {
  const TourStep({
    required this.tab,
    required this.anchorId,
    required this.titleKey,
    required this.textKey,
    this.radius = 20,
  });

  /// Bottom-nav tab the anchor lives on; the tour opens it before measuring.
  final int tab;
  final String anchorId;
  final String titleKey;
  final String textKey;

  /// Corner radius of the spotlight cutout.
  final double radius;
}

/// The tour: shuffle button on Home, a song in the Library, the period
/// switch on Statistics.
const List<TourStep> tourSteps = [
  TourStep(
    tab: 0,
    anchorId: TourAnchors.homeShuffle,
    titleKey: 'tour_home_t',
    textKey: 'tour_home',
    radius: 24,
  ),
  TourStep(
    tab: 1,
    anchorId: TourAnchors.librarySong,
    titleKey: 'tour_library_t',
    textKey: 'tour_library',
  ),
  TourStep(
    tab: 2,
    anchorId: TourAnchors.statsPeriod,
    titleKey: 'tour_stats_t',
    textKey: 'tour_stats',
  ),
];
