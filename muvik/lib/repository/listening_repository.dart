import 'package:sqflite/sqflite.dart';

import '../models/data_models/daily_summary.dart';
import '../models/data_models/playback_session.dart';
import '../services/storage/database_helper.dart';
import '../services/storage/schema.dart';

class SongPlayStat {
  const SongPlayStat(this.songId, this.plays, this.listenedMs);
  final int songId;
  final int plays;
  final int listenedMs;
}

class ArtistStat {
  const ArtistStat(this.artist, this.listenedMs, this.plays);

  /// Raw artist tag; null/unknown placeholders are merged by the service.
  final String? artist;
  final int listenedMs;
  final int plays;
}

class BucketStat {
  const BucketStat(this.key, this.listenedMs, this.plays);
  final String key;
  final int listenedMs;
  final int plays;
}

/// Sessions, segments and the daily summary cache. Date ranges are
/// [startKey, endKey) on local 'YYYY-MM-DD' keys.
class ListeningRepository {
  final DatabaseHelper _db = DatabaseHelper();
  static const String _ses = DbSchema.tableSessions;
  static const String _seg = DbSchema.tableSegments;
  static const String _sum = DbSchema.tableDailySummary;
  static const String _songs = DbSchema.tableSongs;

  Future<DatabaseExecutor> _e(DatabaseExecutor? exec) async =>
      exec ?? await _db.database;

  // ---------- writes ----------

  Future<int> insertSession(
    PlaybackSession s, {
    DatabaseExecutor? exec,
  }) async => (await _e(exec)).insert(_ses, s.toMap()..remove('id'));

  Future<void> updateSession(
    PlaybackSession s, {
    DatabaseExecutor? exec,
  }) async {
    await (await _e(
      exec,
    )).update(_ses, s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  /// Writes the absolute listened time of a session on a day (idempotent).
  Future<void> upsertSegment({
    required int sessionId,
    required int songId,
    required String dateKey,
    required int listenedMs,
    required int tzOffsetMinutes,
    DatabaseExecutor? exec,
  }) async {
    await (await _e(exec)).rawInsert(
      '''
      INSERT INTO $_seg (session_id, song_id, date_key, listened_ms, tz_offset_min, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(session_id, date_key) DO UPDATE SET
        listened_ms = excluded.listened_ms,
        tz_offset_min = excluded.tz_offset_min,
        updated_at = excluded.updated_at''',
      [
        sessionId,
        songId,
        dateKey,
        listenedMs,
        tzOffsetMinutes,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  /// Recomputes the cache row for each day from the source tables.
  Future<void> rebuildDailySummary(
    Iterable<String> dateKeys, {
    DatabaseExecutor? exec,
  }) async {
    final db = await _e(exec);
    for (final key in dateKeys.toSet()) {
      final t = await db.rawQuery(
        'SELECT COALESCE(SUM(listened_ms),0) AS ms FROM $_seg WHERE date_key = ?',
        [key],
      );
      final c = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_ses WHERE qualified = 1 AND qualified_date_key = ?',
        [key],
      );
      await db.insert(
        _sum,
        DailySummary(
          dateKey: key,
          listenedMs: (t.first['ms'] as int?) ?? 0,
          playCount: (c.first['c'] as int?) ?? 0,
          updatedAt: DateTime.now(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Closes sessions left open by a crash (recovery, P16-05).
  Future<void> closeDanglingSessions({DatabaseExecutor? exec}) async {
    await (await _e(exec)).update(_ses, {
      'ended_at': DateTime.now().toUtc().toIso8601String(),
      'end_reason': 'recovered',
    }, where: 'ended_at IS NULL');
  }

  // ---------- period queries ----------

  Future<int> totalListenedMs(
    String startKey,
    String endKey, {
    List<int>? songIds,
  }) async {
    final f = _songFilter('song_id', songIds);
    final r = await (await _e(null)).rawQuery(
      'SELECT COALESCE(SUM(listened_ms),0) AS ms FROM $_seg '
      'WHERE date_key >= ? AND date_key < ?${f.sql}',
      [startKey, endKey, ...f.args],
    );
    return (r.first['ms'] as int?) ?? 0;
  }

  Future<int> playCount(
    String startKey,
    String endKey, {
    List<int>? songIds,
  }) async {
    final f = _songFilter('song_id', songIds);
    final r = await (await _e(null)).rawQuery(
      'SELECT COUNT(*) AS c FROM $_ses WHERE qualified = 1 '
      'AND qualified_date_key >= ? AND qualified_date_key < ?${f.sql}',
      [startKey, endKey, ...f.args],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Distinct songs with a qualified play in the whole period (not a sum of
  /// per-day distinct counts).
  Future<int> distinctSongs(
    String startKey,
    String endKey, {
    List<int>? songIds,
  }) async {
    final f = _songFilter('song_id', songIds);
    final r = await (await _e(null)).rawQuery(
      'SELECT COUNT(DISTINCT song_id) AS c FROM $_ses WHERE qualified = 1 '
      'AND qualified_date_key >= ? AND qualified_date_key < ?${f.sql}',
      [startKey, endKey, ...f.args],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Per-day (or per-month when [byMonth]) listened time and plays.
  Future<List<BucketStat>> buckets(
    String startKey,
    String endKey, {
    bool byMonth = false,
    List<int>? songIds,
  }) async {
    final keyExpr = byMonth ? 'substr(date_key, 1, 7)' : 'date_key';
    final qKeyExpr = byMonth
        ? 'substr(qualified_date_key, 1, 7)'
        : 'qualified_date_key';
    final f = _songFilter('song_id', songIds);
    final db = await _e(null);
    final ms = await db.rawQuery(
      'SELECT $keyExpr AS k, SUM(listened_ms) AS ms FROM $_seg '
      'WHERE date_key >= ? AND date_key < ?${f.sql} GROUP BY k',
      [startKey, endKey, ...f.args],
    );
    final plays = await db.rawQuery(
      'SELECT $qKeyExpr AS k, COUNT(*) AS c FROM $_ses WHERE qualified = 1 '
      'AND qualified_date_key >= ? AND qualified_date_key < ?${f.sql} GROUP BY k',
      [startKey, endKey, ...f.args],
    );
    final playMap = {for (final r in plays) r['k'] as String: r['c'] as int};
    final keys = {...ms.map((r) => r['k'] as String), ...playMap.keys};
    final msMap = {
      for (final r in ms) r['k'] as String: (r['ms'] as int?) ?? 0,
    };
    return keys
        .map((k) => BucketStat(k, msMap[k] ?? 0, playMap[k] ?? 0))
        .toList();
  }

  /// Songs ranked by plays, then listened time (title tie-break in service).
  Future<List<SongPlayStat>> topSongs(
    String startKey,
    String endKey, {
    List<int>? songIds,
  }) async {
    final f = _songFilter('song_id', songIds);
    final db = await _e(null);
    final plays = await db.rawQuery(
      'SELECT song_id, COUNT(*) AS c FROM $_ses WHERE qualified = 1 '
      'AND qualified_date_key >= ? AND qualified_date_key < ?${f.sql} GROUP BY song_id',
      [startKey, endKey, ...f.args],
    );
    final ms = await db.rawQuery(
      'SELECT song_id, SUM(listened_ms) AS ms FROM $_seg '
      'WHERE date_key >= ? AND date_key < ?${f.sql} GROUP BY song_id',
      [startKey, endKey, ...f.args],
    );
    final playMap = {for (final r in plays) r['song_id'] as int: r['c'] as int};
    final msMap = {
      for (final r in ms) r['song_id'] as int: (r['ms'] as int?) ?? 0,
    };
    final ids = {...playMap.keys, ...msMap.keys};
    return ids
        .map((id) => SongPlayStat(id, playMap[id] ?? 0, msMap[id] ?? 0))
        .where((s) => s.plays > 0 || s.listenedMs > 0)
        .toList();
  }

  /// Listened time per raw artist tag in the period.
  Future<List<ArtistStat>> topArtists(String startKey, String endKey) async {
    final db = await _e(null);
    final ms = await db.rawQuery(
      '''
      SELECT s.artist AS artist, SUM(seg.listened_ms) AS ms
      FROM $_seg seg JOIN $_songs s ON s.id = seg.song_id
      WHERE seg.date_key >= ? AND seg.date_key < ?
      GROUP BY s.artist''',
      [startKey, endKey],
    );
    final plays = await db.rawQuery(
      '''
      SELECT s.artist AS artist, COUNT(*) AS c
      FROM $_ses ses JOIN $_songs s ON s.id = ses.song_id
      WHERE ses.qualified = 1 AND ses.qualified_date_key >= ? AND ses.qualified_date_key < ?
      GROUP BY s.artist''',
      [startKey, endKey],
    );
    final playMap = {
      for (final r in plays) r['artist'] as String?: r['c'] as int,
    };
    return ms
        .map(
          (r) => ArtistStat(
            r['artist'] as String?,
            (r['ms'] as int?) ?? 0,
            playMap[r['artist'] as String?] ?? 0,
          ),
        )
        .toList();
  }

  // ---------- history ----------

  /// Most recently played song ids (newest first).
  Future<List<int>> recentSongIds({int limit = 50}) async {
    final r = await (await _e(null)).rawQuery(
      'SELECT song_id, MAX(started_at) AS t FROM $_ses '
      'GROUP BY song_id ORDER BY t DESC LIMIT ?',
      [limit],
    );
    return r.map((e) => e['song_id'] as int).toList();
  }

  /// All-time qualified plays per song.
  Future<Map<int, int>> allTimePlayCounts() async {
    final r = await (await _e(null)).rawQuery(
      'SELECT song_id, COUNT(*) AS c FROM $_ses WHERE qualified = 1 GROUP BY song_id',
    );
    return {for (final e in r) e['song_id'] as int: e['c'] as int};
  }

  Future<bool> hasAnyHistory() async {
    final r = await (await _e(null)).rawQuery('SELECT 1 FROM $_ses LIMIT 1');
    return r.isNotEmpty;
  }

  _Filter _songFilter(String column, List<int>? ids) {
    if (ids == null) return const _Filter('', []);
    if (ids.isEmpty) return const _Filter(' AND 0', []);
    return _Filter(
      ' AND $column IN (${List.filled(ids.length, '?').join(',')})',
      ids,
    );
  }
}

class _Filter {
  const _Filter(this.sql, this.args);
  final String sql;
  final List<Object> args;
}
