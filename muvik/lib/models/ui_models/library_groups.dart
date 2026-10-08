import '../../utils/metadata_fallback.dart';
import '../data_models/song.dart';

enum SongSort {
  titleAsc('title_asc', 'sort_title_asc'),
  titleDesc('title_desc', 'sort_title_desc'),
  recentlyAdded('recently_added', 'sort_recently_added'),
  artist('artist', 'sort_artist'),
  duration('duration', 'sort_duration');

  const SongSort(this.key, this.labelKey);
  final String key;
  final String labelKey;

  static SongSort fromKey(String? k) => SongSort.values.firstWhere(
    (s) => s.key == k,
    orElse: () => SongSort.titleAsc,
  );

  /// Stable ordering with title + id tie-breaks (P09-06).
  int compare(Song a, Song b) {
    int byTitle() {
      final c = MetadataFallback.normalize(
        a.displayTitle,
      ).compareTo(MetadataFallback.normalize(b.displayTitle));
      return c != 0 ? c : (a.id ?? 0).compareTo(b.id ?? 0);
    }

    switch (this) {
      case SongSort.titleAsc:
        return byTitle();
      case SongSort.titleDesc:
        return -byTitle();
      case SongSort.recentlyAdded:
        final c = b.firstSeenAt.compareTo(a.firstSeenAt);
        if (c != 0) return c;
        final d = b.dateAddedMs.compareTo(a.dateAddedMs);
        return d != 0 ? d : byTitle();
      case SongSort.artist:
        final aa = a.artistOrNull;
        final bb = b.artistOrNull;
        if (aa == null && bb != null) return 1;
        if (bb == null && aa != null) return -1;
        final c = MetadataFallback.normalize(
          aa ?? '',
        ).compareTo(MetadataFallback.normalize(bb ?? ''));
        return c != 0 ? c : byTitle();
      case SongSort.duration:
        final c = a.durationMs.compareTo(b.durationMs);
        return c != 0 ? c : byTitle();
    }
  }
}

enum GroupKind { album, artist, folder }

/// Album / artist / folder derived from song metadata (no separate tables).
class SongGroup {
  SongGroup({
    required this.kind,
    required this.key,
    required this.title,
    this.subtitle,
    required this.songs,
  });

  final GroupKind kind;

  /// Stable key: lower-cased album+artist, artist name, or folder path.
  /// Unknown album/artist use the empty key and a localized label in the UI.
  final String key;

  /// Null title means "unknown" (rendered with a localized fallback).
  final String? title;
  final String? subtitle;
  final List<Song> songs;

  int get durationMs => songs.fold(0, (a, s) => a + s.durationMs);
  Song? get coverSong => songs.isEmpty ? null : songs.first;
  bool get isUnknown => title == null;
  bool get allUnavailable =>
      songs.isNotEmpty && songs.every((s) => !s.available);
}

class LibraryGrouping {
  LibraryGrouping._();

  static List<SongGroup> albums(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      final album = s.albumOrNull;
      final key = album == null ? '' : MetadataFallback.normalize(album);
      map.putIfAbsent(key, () => []).add(s);
    }
    final out = map.entries.map((e) {
      final list = e.value..sort(SongSort.titleAsc.compare);
      final first = list.first;
      final artists = list
          .map((s) => s.artistOrNull)
          .whereType<String>()
          .toSet();
      return SongGroup(
        kind: GroupKind.album,
        key: e.key,
        title: e.key.isEmpty ? null : first.albumOrNull,
        subtitle: artists.length == 1 ? artists.first : null,
        songs: list,
      );
    }).toList();
    return _sortGroups(out);
  }

  /// Unknown artists form one "Không rõ" group — never a fake artist (P09-04).
  static List<SongGroup> artists(List<Song> songs) {
    final map = <String, List<Song>>{};
    final display = <String, String>{};
    for (final s in songs) {
      final a = s.artistOrNull;
      final key = a == null ? '' : MetadataFallback.normalize(a);
      map.putIfAbsent(key, () => []).add(s);
      if (a != null) display.putIfAbsent(key, () => a);
    }
    final out = map.entries
        .map(
          (e) => SongGroup(
            kind: GroupKind.artist,
            key: e.key,
            title: e.key.isEmpty ? null : display[e.key],
            songs: e.value..sort(SongSort.titleAsc.compare),
          ),
        )
        .toList();
    return _sortGroups(out);
  }

  static List<SongGroup> folders(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      map.putIfAbsent(s.folderPath, () => []).add(s);
    }
    final out = map.entries.map((e) {
      final path = e.key;
      final i = path.lastIndexOf('/');
      return SongGroup(
        kind: GroupKind.folder,
        key: path,
        title: i >= 0 ? path.substring(i + 1) : path,
        subtitle: path,
        songs: e.value..sort(SongSort.titleAsc.compare),
      );
    }).toList();
    return _sortGroups(out);
  }

  static List<SongGroup> _sortGroups(List<SongGroup> g) => g
    ..sort((a, b) {
      if (a.isUnknown != b.isUnknown) return a.isUnknown ? 1 : -1;
      return MetadataFallback.normalize(
        a.title ?? '',
      ).compareTo(MetadataFallback.normalize(b.title ?? ''));
    });
}
