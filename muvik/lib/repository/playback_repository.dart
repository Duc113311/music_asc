import 'package:sqflite/sqflite.dart';

import '../models/data_models/playback_snapshot.dart';
import '../models/ui_models/repeat_mode.dart';
import '../models/ui_models/shuffle_mode.dart';
import '../services/storage/database_helper.dart';
import '../services/storage/schema.dart';

class PlaybackRepository {
  final DatabaseHelper _db = DatabaseHelper();
  static const String _snap = DbSchema.tableSnapshot;
  static const String _q = DbSchema.tableQueue;

  Future<DatabaseExecutor> _e(DatabaseExecutor? exec) async =>
      exec ?? await _db.database;

  Future<PlaybackSnapshot?> load({DatabaseExecutor? exec}) async {
    final db = await _e(exec);
    final head = await db.query(_snap, where: 'id = 1');
    if (head.isEmpty) return null;
    final h = head.first;
    final rows = await db.query(_q, orderBy: 'order_index ASC');
    final entries = rows
        .map(
          (r) => QueueEntry(
            entryId: r['entry_id'] as String,
            songId: r['song_id'] as int,
          ),
        )
        .toList();
    final canonicalRows = [...rows]
      ..sort(
        (a, b) => (a['canonical_index'] as int).compareTo(
          b['canonical_index'] as int,
        ),
      );
    final canonical = canonicalRows
        .map(
          (r) => QueueEntry(
            entryId: r['entry_id'] as String,
            songId: r['song_id'] as int,
          ),
        )
        .toList();
    return PlaybackSnapshot(
      entries: entries,
      canonical: canonical,
      currentEntryId: h['current_entry_id'] as String?,
      positionMs: (h['position_ms'] as int?) ?? 0,
      repeatMode: RepeatMode.fromKey(h['repeat_mode'] as String?),
      shuffleMode: ShuffleMode.fromKey(h['shuffle_mode'] as String?),
      updatedAt: DateTime.parse(h['updated_at'] as String).toLocal(),
    );
  }

  Future<void> writeHeader(PlaybackSnapshot s, {DatabaseExecutor? exec}) async {
    await (await _e(exec)).insert(
      _snap,
      s.headerMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceQueue(
    PlaybackSnapshot s, {
    required DatabaseExecutor exec,
  }) async {
    await exec.delete(_q);
    final canonicalIndex = {
      for (var i = 0; i < s.canonical.length; i++) s.canonical[i].entryId: i,
    };
    final batch = exec is Transaction ? exec.batch() : null;
    for (var i = 0; i < s.entries.length; i++) {
      final e = s.entries[i];
      final row = {
        'entry_id': e.entryId,
        'song_id': e.songId,
        'order_index': i,
        'canonical_index': canonicalIndex[e.entryId] ?? i,
      };
      if (batch != null) {
        batch.insert(_q, row);
      } else {
        await exec.insert(_q, row);
      }
    }
    await batch?.commit(noResult: true);
  }
}
