import 'package:flutter/foundation.dart';

import '../../models/data_models/excluded_item.dart';
import '../../models/data_models/song.dart';
import '../../repository/exclusion_repository.dart';
import '../../repository/song_repository.dart';
import '../storage/database_helper.dart';

/// In-memory index of visible songs plus library-level mutations
/// (favorite, exclusion). Every change bumps [revision] so all screens,
/// the player and Home update together (P10-08, P18-01).
class LibraryDataService {
  LibraryDataService({SongRepository? songs, ExclusionRepository? exclusions})
    : _songs = songs ?? SongRepository(),
      _exclusions = exclusions ?? ExclusionRepository();

  final SongRepository _songs;
  final ExclusionRepository _exclusions;
  final DatabaseHelper _db = DatabaseHelper();

  final Map<int, Song> _cache = {};
  final ValueNotifier<int> revision = ValueNotifier(0);

  List<Song> get visibleSongs => _cache.values.where((s) => !s.hidden).toList();

  Song? cached(int id) => _cache[id];

  Future<void> reload() async {
    final list = await _songs.getVisible();
    _cache
      ..clear()
      ..addEntries(list.map((s) => MapEntry(s.id!, s)));
    revision.value++;
  }

  /// Resolves ids, falling back to the DB for songs not in the visible cache
  /// (e.g. a hidden song still referenced by the queue or history).
  Future<Map<int, Song>> resolve(Iterable<int> ids) async {
    final out = <int, Song>{};
    final missing = <int>[];
    for (final id in ids) {
      final s = _cache[id];
      if (s != null) {
        out[id] = s;
      } else {
        missing.add(id);
      }
    }
    if (missing.isNotEmpty) out.addAll(await _songs.getByIds(missing));
    return out;
  }

  Future<Song?> get(int id) async => _cache[id] ?? await _songs.getById(id);

  Future<Song?> setFavorite(int songId, bool favorite) async {
    await _songs.setFavorite(songId, favorite);
    final fresh = await _songs.getById(songId);
    if (fresh != null && !fresh.hidden) _cache[songId] = fresh;
    revision.value++;
    return fresh;
  }

  /// "Bỏ khỏi thư viện": remembers the exclusion and hides the song; the file
  /// stays on the device.
  Future<void> excludeSong(Song song) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _exclusions.insert(
        ExcludedItem(
          type: ExcludedType.song,
          identity: song.identity,
          createdAt: DateTime.now(),
        ),
        exec: txn,
      );
      await _songs.setHiddenById(song.id!, true, exec: txn);
    });
    _cache.remove(song.id);
    revision.value++;
  }

  /// Excludes a whole folder (identity prefix) from the library.
  Future<void> excludeFolder(String identityPrefix) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _exclusions.insert(
        ExcludedItem(
          type: ExcludedType.folder,
          identity: identityPrefix,
          createdAt: DateTime.now(),
        ),
        exec: txn,
      );
      await _songs.setHiddenByIdentityPrefix(identityPrefix, true, exec: txn);
    });
    await reload();
  }

  void dispose() => revision.dispose();
}
