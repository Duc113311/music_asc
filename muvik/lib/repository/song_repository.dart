import 'package:sqflite/sqflite.dart';

import '../models/data_models/song.dart';
import '../services/storage/database_helper.dart';
import '../services/storage/schema.dart';
import '../utils/app_log.dart';

/// CRUD/query for songs. No business rules; callers pass [exec] when the
/// operation is part of a service-level transaction.
class SongRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<DatabaseExecutor> _e(DatabaseExecutor? exec) async =>
      exec ?? await _db.database;

  static const String _t = DbSchema.tableSongs;

  /// All songs not hidden by the user, including unavailable ones (shown dimmed).
  Future<List<Song>> getVisible({DatabaseExecutor? exec}) async {
    try {
      final rows = await (await _e(exec)).query(_t, where: 'hidden = 0');
      return rows.map(Song.fromMap).toList();
    } catch (e, st) {
      AppLog.error('SongRepository.getVisible', e, st);
      rethrow;
    }
  }

  Future<Song?> getById(int id, {DatabaseExecutor? exec}) async {
    final rows = await (await _e(
      exec,
    )).query(_t, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Song.fromMap(rows.first);
  }

  Future<Map<int, Song>> getByIds(
    Iterable<int> ids, {
    DatabaseExecutor? exec,
  }) async {
    final list = ids.toSet().toList();
    final out = <int, Song>{};
    final db = await _e(exec);
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(
        i,
        i + 500 > list.length ? list.length : i + 500,
      );
      final rows = await db.query(
        _t,
        where: 'id IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      );
      for (final r in rows) {
        final s = Song.fromMap(r);
        out[s.id!] = s;
      }
    }
    return out;
  }

  Future<Map<String, Song>> getByIdentities(
    Iterable<String> identities, {
    DatabaseExecutor? exec,
  }) async {
    final list = identities.toSet().toList();
    final out = <String, Song>{};
    final db = await _e(exec);
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(
        i,
        i + 500 > list.length ? list.length : i + 500,
      );
      final rows = await db.query(
        _t,
        where: 'identity IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      );
      for (final r in rows) {
        final s = Song.fromMap(r);
        out[s.identity] = s;
      }
    }
    return out;
  }

  /// Ids + identities of available songs belonging to a source.
  Future<Map<String, int>> availableIdentitiesForSource(
    int sourceId, {
    DatabaseExecutor? exec,
  }) async {
    final rows = await (await _e(exec)).query(
      _t,
      columns: ['id', 'identity'],
      where: 'source_id = ? AND available = 1',
      whereArgs: [sourceId],
    );
    return {for (final r in rows) r['identity'] as String: r['id'] as int};
  }

  Future<int> insert(Song s, {DatabaseExecutor? exec}) async =>
      (await _e(exec)).insert(_t, s.toMap()..remove('id'));

  Future<int> update(Song s, {DatabaseExecutor? exec}) async => (await _e(
    exec,
  )).update(_t, s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  Future<int> setAvailability(
    List<int> ids,
    bool available, {
    DatabaseExecutor? exec,
  }) async {
    if (ids.isEmpty) return 0;
    var n = 0;
    final db = await _e(exec);
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      n += await db.update(
        _t,
        {
          'available': available ? 1 : 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      );
    }
    return n;
  }

  Future<int> setAvailabilityForSource(
    int sourceId,
    bool available, {
    DatabaseExecutor? exec,
  }) async => (await _e(exec)).update(
    _t,
    {'available': available ? 1 : 0},
    where: 'source_id = ?',
    whereArgs: [sourceId],
  );

  Future<int> setFavorite(
    int id,
    bool favorite, {
    DatabaseExecutor? exec,
  }) async => (await _e(exec)).update(
    _t,
    {
      'favorite': favorite ? 1 : 0,
      'favorite_at': favorite ? DateTime.now().toUtc().toIso8601String() : null,
    },
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<int> setHiddenById(
    int id,
    bool hidden, {
    DatabaseExecutor? exec,
  }) async => (await _e(
    exec,
  )).update(_t, {'hidden': hidden ? 1 : 0}, where: 'id = ?', whereArgs: [id]);

  /// Hides every song whose identity starts with [prefix] (folder exclusion).
  Future<int> setHiddenByIdentityPrefix(
    String prefix,
    bool hidden, {
    DatabaseExecutor? exec,
  }) async {
    final escaped = prefix
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return (await _e(exec)).update(
      _t,
      {'hidden': hidden ? 1 : 0},
      where: r"identity LIKE ? ESCAPE '\'",
      whereArgs: ['$escaped%'],
    );
  }

  Future<int> countVisibleAvailable({DatabaseExecutor? exec}) async {
    final r = await (await _e(exec)).rawQuery(
      'SELECT COUNT(*) AS c FROM $_t WHERE hidden = 0 AND available = 1',
    );
    return (r.first['c'] as int?) ?? 0;
  }
}
