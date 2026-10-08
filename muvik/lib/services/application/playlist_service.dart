import 'package:flutter/widgets.dart';

import '../../configs/app_config.dart';
import '../../models/data_models/playlist.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/app_error.dart';
import '../../repository/playlist_repository.dart';
import '../storage/database_helper.dart';
import 'library_data_service.dart';

/// Playlist business rules (P10). Membership changes never touch song rows or
/// files; the play queue is a snapshot and is not affected either.
class PlaylistService {
  PlaylistService({required this.library, PlaylistRepository? repository})
    : _repo = repository ?? PlaylistRepository();

  final LibraryDataService library;
  final PlaylistRepository _repo;
  final DatabaseHelper _db = DatabaseHelper();

  final ValueNotifier<int> revision = ValueNotifier(0);

  /// Trimmed, non-empty, at most [AppConfig.playlistNameMaxLength] chars.
  static String validateName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const AppError(AppErrorCode.validation, 'playlist_name_required');
    }
    if (name.characters.length > AppConfig.playlistNameMaxLength) {
      throw const AppError(AppErrorCode.validation, 'playlist_name_too_long');
    }
    return name;
  }

  Future<List<Playlist>> getAll() => _repo.getAll();

  Future<Playlist?> getById(int id) => _repo.getById(id);

  Future<List<Song>> getSongs(int playlistId) async {
    final ids = await _repo.getSongIds(playlistId);
    final map = await library.resolve(ids);
    return [for (final id in ids) ?map[id]];
  }

  Future<Set<int>> memberIds(int playlistId) =>
      _repo.getAllMemberIds(playlistId);

  Future<int> create({
    required String name,
    String description = '',
    String? coverUri,
    List<int> songIds = const [],
  }) async {
    final valid = validateName(name);
    final now = DateTime.now();
    final db = await _db.database;
    late int id;
    await db.transaction((txn) async {
      id = await _repo.insert(
        Playlist(
          name: valid,
          description: description.trim(),
          coverUri: coverUri,
          createdAt: now,
          updatedAt: now,
        ),
        exec: txn,
      );
      for (var i = 0; i < songIds.length; i++) {
        await _repo.addSong(id, songIds[i], i, exec: txn);
      }
    });
    revision.value++;
    return id;
  }

  /// Saves name/description/cover and the full song order atomically.
  Future<void> saveEdits(Playlist playlist, {List<int>? orderedSongIds}) async {
    final valid = validateName(playlist.name);
    final db = await _db.database;
    await db.transaction((txn) async {
      await _repo.update(
        playlist.copyWith(name: valid, updatedAt: DateTime.now()),
        exec: txn,
      );
      if (orderedSongIds != null) {
        final current = await _repo.getAllMemberIds(playlist.id!, exec: txn);
        for (final removed in current.difference(orderedSongIds.toSet())) {
          await _repo.removeSong(playlist.id!, removed, exec: txn);
        }
        for (var i = 0; i < orderedSongIds.length; i++) {
          await _repo.setPosition(
            playlist.id!,
            orderedSongIds[i],
            i,
            exec: txn,
          );
        }
      }
    });
    revision.value++;
  }

  /// Adds songs in order; returns how many were new vs. already present.
  Future<({int added, int duplicates})> addSongs(
    int playlistId,
    List<int> songIds,
  ) async {
    var added = 0;
    var duplicates = 0;
    final db = await _db.database;
    await db.transaction((txn) async {
      final existing = await _repo.getAllMemberIds(playlistId, exec: txn);
      var pos = await _repo.maxPosition(playlistId, exec: txn);
      for (final id in songIds.toSet()) {
        if (existing.contains(id)) {
          duplicates++;
          continue;
        }
        pos++;
        added += await _repo.addSong(playlistId, id, pos, exec: txn) > 0
            ? 1
            : 0;
      }
      if (added > 0) await _repo.touch(playlistId, exec: txn);
    });
    revision.value++;
    return (added: added, duplicates: duplicates);
  }

  /// Removes membership only — never the song or file.
  Future<void> removeSong(int playlistId, int songId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _repo.removeSong(playlistId, songId, exec: txn);
      await _repo.touch(playlistId, exec: txn);
    });
    revision.value++;
  }

  Future<void> delete(int playlistId) async {
    await _repo.delete(playlistId);
    revision.value++;
  }
}
