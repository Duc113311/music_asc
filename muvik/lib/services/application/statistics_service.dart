import '../../models/data_models/song.dart';
import '../../models/ui_models/period_type.dart';
import '../../repository/listening_repository.dart';
import '../../utils/metadata_fallback.dart';
import 'library_data_service.dart';

class RankedSong {
  const RankedSong(this.song, this.plays, this.listenedMs);
  final Song song;
  final int plays;
  final int listenedMs;
}

class RankedArtist {
  const RankedArtist(this.artist, this.listenedMs, this.plays);

  /// Null = "Không rõ" group.
  final String? artist;
  final int listenedMs;
  final int plays;
}

class PeriodStats {
  const PeriodStats({
    required this.period,
    required this.totalMs,
    required this.plays,
    required this.distinctSongs,
    required this.buckets,
    required this.topSongs,
    required this.topArtists,
    required this.previousTotalMs,
    required this.previousDistinctSongs,
  });

  final StatsPeriod period;
  final int totalMs;
  final int plays;
  final int distinctSongs;

  /// One entry per chart bucket, in order, zero-filled.
  final List<BucketStat> buckets;
  final List<RankedSong> topSongs;
  final List<RankedArtist> topArtists;
  final int previousTotalMs;
  final int previousDistinctSongs;

  bool get isEmpty => totalMs == 0 && plays == 0;

  /// Percent change vs. previous period, or null when the previous period has
  /// no data (never divide by zero — P16-08).
  static double? change(int current, int previous) =>
      previous == 0 ? null : (current - previous) * 100 / previous;

  double? get totalChangePct => change(totalMs, previousTotalMs);
  double? get distinctChangePct => change(distinctSongs, previousDistinctSongs);

  int? get peakBucket {
    var best = -1;
    var bestMs = 0;
    for (var i = 0; i < buckets.length; i++) {
      if (buckets[i].listenedMs > bestMs) {
        bestMs = buckets[i].listenedMs;
        best = i;
      }
    }
    return best < 0 ? null : best;
  }
}

/// Read-side statistics built only from recorded sessions/segments.
class StatisticsService {
  StatisticsService({required this.library, ListeningRepository? repository})
      : _repo = repository ?? ListeningRepository();

  final LibraryDataService library;
  final ListeningRepository _repo;

  Future<PeriodStats> load(StatsPeriod p, {List<int>? songIds}) async {
    final prev = p.previous();
    final byMonth = p.type == PeriodType.year;
    final results = await Future.wait([
      _repo.totalListenedMs(p.startKey, p.endKey, songIds: songIds),
      _repo.playCount(p.startKey, p.endKey, songIds: songIds),
      _repo.distinctSongs(p.startKey, p.endKey, songIds: songIds),
      _repo.totalListenedMs(prev.startKey, prev.endKey, songIds: songIds),
      _repo.distinctSongs(prev.startKey, prev.endKey, songIds: songIds),
    ]);
    final raw = await _repo.buckets(
      p.startKey,
      p.endKey,
      byMonth: byMonth,
      songIds: songIds,
    );
    final byKey = {for (final b in raw) b.key: b};
    final buckets = [
      for (var i = 0; i < p.bucketCount; i++)
        byKey[p.bucketKey(i)] ?? BucketStat(p.bucketKey(i), 0, 0),
    ];
    final top = await topSongs(p, songIds: songIds);
    final artists = songIds == null
        ? mergeArtists(await _repo.topArtists(p.startKey, p.endKey))
        : const <RankedArtist>[];
    return PeriodStats(
      period: p,
      totalMs: results[0],
      plays: results[1],
      distinctSongs: results[2],
      previousTotalMs: results[3],
      previousDistinctSongs: results[4],
      buckets: buckets,
      topSongs: top,
      topArtists: artists,
    );
  }

  Future<List<RankedSong>> topSongs(StatsPeriod p, {List<int>? songIds}) async {
    final raw = await _repo.topSongs(p.startKey, p.endKey, songIds: songIds);
    final songs = await library.resolve(raw.map((r) => r.songId));
    return rankSongs(raw, songs);
  }

  /// Songs listened in an arbitrary [startKey, endKey) range (a chart bar).
  Future<List<RankedSong>> songsInRange(String startKey, String endKey) async {
    final raw = await _repo.topSongs(startKey, endKey);
    final songs = await library.resolve(raw.map((r) => r.songId));
    return rankSongs(raw, songs);
  }

  /// Plays desc, then listened time desc, then title (spec §7.2).
  static List<RankedSong> rankSongs(
    List<SongPlayStat> raw,
    Map<int, Song> songs,
  ) {
    final list = [
      for (final r in raw)
        if (songs[r.songId] != null)
          RankedSong(songs[r.songId]!, r.plays, r.listenedMs),
    ];
    list.sort((a, b) {
      final c = b.plays.compareTo(a.plays);
      if (c != 0) return c;
      final d = b.listenedMs.compareTo(a.listenedMs);
      if (d != 0) return d;
      return a.song.displayTitle.toLowerCase().compareTo(
            b.song.displayTitle.toLowerCase(),
          );
    });
    return list;
  }

  /// Merges missing/placeholder artist tags into one "unknown" group and
  /// ranks by listened time.
  static List<RankedArtist> mergeArtists(List<ArtistStat> raw) {
    final ms = <String?, int>{};
    final plays = <String?, int>{};
    final display = <String?, String?>{};
    for (final a in raw) {
      final clean = MetadataFallback.clean(a.artist);
      final key = clean?.toLowerCase();
      ms[key] = (ms[key] ?? 0) + a.listenedMs;
      plays[key] = (plays[key] ?? 0) + a.plays;
      display[key] ??= clean;
    }
    final list = [
      for (final k in ms.keys) RankedArtist(display[k], ms[k]!, plays[k]!),
    ]..sort((a, b) => b.listenedMs.compareTo(a.listenedMs));
    return list.where((a) => a.listenedMs > 0 || a.plays > 0).toList();
  }
}
