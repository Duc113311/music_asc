import '../models/data_models/song.dart';
import 'metadata_fallback.dart';
import 'mood_rules.dart';

enum ExploreKind {
  tiktok,
  morning,
  evening,
  quick,
  long,
  genre,
  artist,
}

/// One suggestion card of Explore, built only from the songs on the device
/// (no catalog, no network). [param] is the genre or artist name for the
/// kinds that have one.
class ExploreCollection {
  const ExploreCollection(this.kind, this.songs, {this.param});
  final ExploreKind kind;
  final String? param;
  final List<Song> songs;
}

/// Rules for the extra Explore collections. A collection is returned only when
/// it has enough songs to be worth a card.
class ExploreCollections {
  ExploreCollections._();

  static const int minSongs = 5;
  static const int topGroups = 3;
  static const int limit = 100;
  static const Duration quickMax = Duration(minutes: 3);
  static const Duration longMin = Duration(minutes: 6);

  /// File or folder names left by apps that save TikTok sounds/videos.
  static const _tiktokMarkers = [
    'tiktok',
    'tik tok',
    'snaptik',
    'ssstik',
    'musicaldown',
    'tikmate',
    'tikdown',
    'musical.ly',
  ];

  static bool isTikTok(Song s) {
    final hay = '${s.folderPath}/${s.fileName}'.toLowerCase();
    return _tiktokMarkers.any(hay.contains);
  }

  static List<ExploreCollection> build(List<Song> all) {
    final songs = all.where((s) => s.available).toList();
    final out = <ExploreCollection>[];

    final tiktok = songs.where(isTikTok).toList()..sort(_byNewest);
    if (tiktok.isNotEmpty) {
      out.add(ExploreCollection(ExploreKind.tiktok, _cap(tiktok)));
    }

    final morning = songs
        .where((s) => Mood.energetic.matches(s) || Mood.focus.matches(s))
        .toList();
    if (morning.length >= minSongs) {
      out.add(ExploreCollection(ExploreKind.morning, _cap(morning)));
    }
    final evening = songs
        .where((s) => Mood.calm.matches(s) || Mood.romantic.matches(s))
        .toList();
    if (evening.length >= minSongs) {
      out.add(ExploreCollection(ExploreKind.evening, _cap(evening)));
    }

    final quick = songs
        .where((s) => s.durationMs > 0 && s.duration <= quickMax)
        .toList();
    if (quick.length >= minSongs) {
      out.add(ExploreCollection(ExploreKind.quick, _cap(quick)));
    }
    final long = songs.where((s) => s.duration >= longMin).toList();
    if (long.length >= 3) {
      out.add(ExploreCollection(ExploreKind.long, _cap(long)));
    }

    out.addAll(_top(songs, ExploreKind.genre, (s) => s.genre));
    out.addAll(_top(songs, ExploreKind.artist, (s) => s.artistOrNull));
    return out;
  }

  /// The [topGroups] biggest groups (by the song count) of [keyOf].
  static List<ExploreCollection> _top(
    List<Song> songs,
    ExploreKind kind,
    String? Function(Song) keyOf,
  ) {
    final groups = <String, List<Song>>{};
    final names = <String, String>{};
    for (final s in songs) {
      final raw = MetadataFallback.clean(keyOf(s));
      if (raw == null) continue;
      final key = MetadataFallback.normalize(raw);
      if (key.isEmpty) continue;
      (groups[key] ??= []).add(s);
      names.putIfAbsent(key, () => raw);
    }
    final ranked = groups.entries.where((e) => e.value.length >= minSongs).toList()
      ..sort((a, b) {
        final c = b.value.length.compareTo(a.value.length);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return [
      for (final e in ranked.take(topGroups))
        ExploreCollection(kind, _cap(e.value), param: names[e.key]),
    ];
  }

  static List<Song> _cap(List<Song> list) =>
      list.length <= limit ? list : list.sublist(0, limit);

  static int _byNewest(Song a, Song b) => b.dateAddedMs.compareTo(a.dateAddedMs);
}
