import 'package:sqflite/sqflite.dart';

import '../models/data_models/playlist.dart';
import '../services/storage/database_helper.dart';
import '../services/storage/schema.dart';

class PlaylistRepository {
  final DatabaseHelper _db = DatabaseHelper();
  static const String _p = DbSchema.tablePlaylists;
  static const String _ps = DbSchema.tablePlaylistSongs;
  static const String _s = DbSchema.tableSongs;

  Future<DatabaseExecutor> _e(DatabaseExecutor? exec) async =>
      exec ?? await _db.database;

  static const String _aggregateSelect =
      '''
    SELECT p.*,
      (SELECT COUNT(*) FROM $_ps ps JOIN $_s s ON s.id = ps.song_id
        WHERE ps.playlist_id = p.id AND s.hidden = 0) AS song_count,
      (SELECT COALESCE(SUM(s.duration_ms), 0) FROM $_ps ps JOIN $_s s ON s.id = ps.song_id
        WHERE ps.playlist_id = p.id AND s.hidden = 0) AS duration_ms,
      (SELECT ps.song_id FROM $_ps ps JOIN $_s s ON s.id = ps.song_id
        WHERE ps.playlist_id = p.id AND s.hidden = 0
        ORDER BY ps.position ASC LIMIT 1) AS first_song_id
    FROM $_p p''';

  Future<List<Playlist>> getAll({DatabaseExecutor? exec}) async {
    final rows = await (await _e(
      exec,
    )).rawQuery('$_aggregateSelect ORDER BY p.updated_at DESC');
    return rows.map(Playlist.fromMap).toList();
  }

  Future<Playlist?> getById(int id, {DatabaseExecutor? exec}) async {
    final rows = await (await _e(
      exec,
    )).rawQuery('$_aggregateSelect WHERE p.id = ?', [id]);
    return rows.isEmpty ? null : Playlist.fromMap(rows.first);
  }

  Future<int> insert(Playlist p, {DatabaseExecutor? exec}) async =>
      (await _e(exec)).insert(_p, p.toMap()..remove('id'));

  Future<int> update(Playlist p, {DatabaseExecutor? exec}) async => (await _e(
    exec,
  )).update(_p, p.toMap(), where: 'id = ?', whereArgs: [p.id]);

  Future<int> touch(int id, {DatabaseExecutor? exec}) async =>
      (await _e(exec)).update(
        _p,
        {'updated_at': DateTime.now().toUtc().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Deletes the playlist row; memberships cascade. Songs/files untouched.
  Future<int> delete(int id, {DatabaseExecutor? exec}) async =>
      (await _e(exec)).delete(_p, where: 'id = ?', whereArgs: [id]);

  /// Ordered song ids of a playlist (hidden songs excluded).
  Future<List<int>> getSongIds(int playlistId, {DatabaseExecutor? exec}) async {
    final rows = await (await _e(exec)).rawQuery(
      '''
      SELECT ps.song_id FROM $_ps ps JOIN $_s s ON s.id = ps.song_id
      WHERE ps.playlist_id = ? AND s.hidden = 0
      ORDER BY ps.position ASC''',
      [playlistId],
    );
    return rows.map((r) => r['song_id'] as int).toList();
  }

  Future<Set<int>> getAllMemberIds(
    int playlistId, {
    DatabaseExecutor? exec,
  }) async {
    final rows = await (await _e(exec)).query(
      _ps,
      columns: ['song_id'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    return rows.map((r) => r['song_id'] as int).toSet();
  }

  Future<int> maxPosition(int playlistId, {DatabaseExecutor? exec}) async {
    final r = await (await _e(exec)).rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS m FROM $_ps WHERE playlist_id = ?',
      [playlistId],
    );
    return (r.first['m'] as int?) ?? -1;
  }

  /// Inserts a membership; returns 0 when it already exists (unique key).
  Future<int> addSong(
    int playlistId,
    int songId,
    int position, {
    DatabaseExecutor? exec,
  }) async => (await _e(exec)).insert(_ps, {
    'playlist_id': playlistId,
    'song_id': songId,
    'position': position,
    'added_at': DateTime.now().toUtc().toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<int> removeSong(
    int playlistId,
    int songId, {
    DatabaseExecutor? exec,
  }) async => (await _e(exec)).delete(
    _ps,
    where: 'playlist_id = ? AND song_id = ?',
    whereArgs: [playlistId, songId],
  );

  Future<void> setPosition(
    int playlistId,
    int songId,
    int position, {
    DatabaseExecutor? exec,
  }) async {
    await (await _e(exec)).update(
      _ps,
      {'position': position},
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }
}
