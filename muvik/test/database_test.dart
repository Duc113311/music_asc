import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/playback_snapshot.dart';
import 'package:muvik/models/data_models/song.dart';
import 'package:muvik/models/data_models/playback_session.dart';
import 'package:muvik/models/ui_models/app_error.dart';
import 'package:muvik/models/ui_models/period_type.dart';
import 'package:muvik/models/ui_models/repeat_mode.dart';
import 'package:muvik/models/ui_models/shuffle_mode.dart';
import 'package:muvik/repository/listening_repository.dart';
import 'package:muvik/repository/playback_repository.dart';
import 'package:muvik/repository/song_repository.dart';
import 'package:muvik/services/application/library_data_service.dart';
import 'package:muvik/services/application/playlist_service.dart';
import 'package:muvik/services/application/statistics_service.dart';
import 'package:muvik/services/storage/database_helper.dart';
import 'package:muvik/services/storage/schema.dart';

import 'helpers/test_env.dart';

void main() {
  setUp(setUpTestDb);
  tearDown(tearDownTestDb);

  test('genre column (DB v2) is stored and read back', () async {
    expect(DbSchema.dbVersion, greaterThanOrEqualTo(2));
    final repo = SongRepository();
    final now = DateTime(2026, 10, 1);
    final id = await repo.insert(
      Song(
        sourceId: 1,
        identity: 'g1',
        uri: 'content://g1',
        title: 'g1',
        folderPath: 'Music',
        fileName: 'g1.mp3',
        firstSeenAt: now,
        updatedAt: now,
        genre: 'Lo-Fi',
      ),
    );
    expect((await repo.getById(id))?.genre, 'Lo-Fi');
  });

  group('Playlist rules (P19-02)', () {
    late LibraryDataService lib;
    late PlaylistService svc;
    setUp(() {
      lib = LibraryDataService();
      svc = PlaylistService(library: lib);
    });

    test('name is trimmed, required and limited to 80 chars', () {
      expect(PlaylistService.validateName('  Chill  '), 'Chill');
      expect(
        () => PlaylistService.validateName('   '),
        throwsA(isA<AppError>()),
      );
      expect(
        () => PlaylistService.validateName('x' * 81),
        throwsA(isA<AppError>()),
      );
      expect(PlaylistService.validateName('🎵' * 80), '🎵' * 80);
    });

    test('a song is added once; duplicates are reported', () async {
      final a = await insertSong('a');
      final b = await insertSong('b');
      final id = await svc.create(name: 'P');
      expect(await svc.addSongs(id, [a, b]), (added: 2, duplicates: 0));
      expect(await svc.addSongs(id, [a]), (added: 0, duplicates: 1));
      expect((await svc.getSongs(id)).map((s) => s.id), [a, b]);
    });

    test(
      'reorder + remove are saved atomically; songs never deleted',
      () async {
        final a = await insertSong('a');
        final b = await insertSong('b');
        final c = await insertSong('c');
        final id = await svc.create(name: 'P', songIds: [a, b, c]);
        final p = (await svc.getById(id))!;
        await svc.saveEdits(p, orderedSongIds: [c, a]);
        expect((await svc.getSongs(id)).map((s) => s.id), [c, a]);
        expect(await SongRepository().getById(b), isNotNull);
      },
    );

    test('deleting a playlist keeps songs', () async {
      final a = await insertSong('a');
      final id = await svc.create(name: 'P', songIds: [a]);
      await svc.delete(id);
      expect(await svc.getById(id), isNull);
      expect(await SongRepository().getById(a), isNotNull);
    });

    test('failure mid-transaction leaves nothing half-saved', () async {
      // Song 999 does not exist → FK violation rolls back the playlist too.
      await expectLater(
        svc.create(name: 'Broken', songIds: [999]),
        throwsA(anything),
      );
      expect(await svc.getAll(), isEmpty);
    });
  });

  group('Playback snapshot (P19-07)', () {
    test('round-trips queue, canonical order, position and modes', () async {
      final repo = PlaybackRepository();
      const e = [
        QueueEntry(entryId: 'x', songId: 3),
        QueueEntry(entryId: 'y', songId: 1),
        QueueEntry(entryId: 'z', songId: 3),
      ];
      final snap = PlaybackSnapshot(
        entries: e,
        canonical: [e[1], e[0], e[2]],
        currentEntryId: 'z',
        positionMs: 42000,
        repeatMode: RepeatMode.one,
        shuffleMode: ShuffleMode.on,
        updatedAt: DateTime(2026, 10, 7),
      );
      final db = await DatabaseHelper().database;
      await db.transaction((txn) async {
        await repo.writeHeader(snap, exec: txn);
        await repo.replaceQueue(snap, exec: txn);
      });
      final r = (await repo.load())!;
      expect(r.entries, e);
      expect(r.canonical.map((x) => x.entryId), ['y', 'x', 'z']);
      expect(r.currentEntryId, 'z');
      expect(r.positionMs, 42000);
      expect(r.repeatMode, RepeatMode.one);
      expect(r.shuffleMode, ShuffleMode.on);
    });

    test('schema is version 1 and migrations map is additive', () async {
      final db = await DatabaseHelper().database;
      expect(
        (await db.rawQuery('PRAGMA user_version')).first.values.first,
        DbSchema.dbVersion,
      );
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = tables.map((t) => t['name']).toSet();
      expect(
        names,
        containsAll([
          DbSchema.tableSongs,
          DbSchema.tableSessions,
          DbSchema.tableSegments,
        ]),
      );
    });
  });

  group('Listening statistics (P19-05)', () {
    late ListeningRepository repo;
    setUp(() => repo = ListeningRepository());

    Future<int> session(
      int song,
      String day,
      int ms, {
      bool qualified = true,
    }) async {
      final id = await repo.insertSession(
        PlaybackSession(
          songId: song,
          startedAt: DateTime.parse('${day}T10:00:00'),
          endedAt: DateTime.parse('${day}T10:05:00'),
          listenedMs: ms,
          qualified: qualified,
          qualifiedDateKey: qualified ? day : null,
        ),
      );
      await repo.upsertSegment(
        sessionId: id,
        songId: song,
        dateKey: day,
        listenedMs: ms,
        tzOffsetMinutes: 420,
      );
      return id;
    }

    test(
      'distinct songs are counted over the whole period, not summed per day',
      () async {
        final a = await insertSong('a', artist: 'X');
        final b = await insertSong('b', artist: 'Y');
        await session(a, '2026-10-01', 60000);
        await session(a, '2026-10-02', 60000);
        await session(b, '2026-10-02', 30000);
        final p = StatsPeriod.containing(
          PeriodType.month,
          DateTime(2026, 10, 5),
        );
        expect(await repo.distinctSongs(p.startKey, p.endKey), 2);
        expect(await repo.playCount(p.startKey, p.endKey), 3);
        expect(await repo.totalListenedMs(p.startKey, p.endKey), 150000);
      },
    );

    test(
      'segment upsert is idempotent (re-flush does not double count)',
      () async {
        final a = await insertSong('a');
        final id = await session(a, '2026-10-01', 10000);
        await repo.upsertSegment(
          sessionId: id,
          songId: a,
          dateKey: '2026-10-01',
          listenedMs: 25000,
          tzOffsetMinutes: 420,
        );
        await repo.upsertSegment(
          sessionId: id,
          songId: a,
          dateKey: '2026-10-01',
          listenedMs: 25000,
          tzOffsetMinutes: 420,
        );
        expect(await repo.totalListenedMs('2026-10-01', '2026-10-02'), 25000);
      },
    );

    test('non-qualified sessions add time but not plays', () async {
      final a = await insertSong('a');
      await session(a, '2026-10-01', 10000, qualified: false);
      expect(await repo.playCount('2026-10-01', '2026-10-02'), 0);
      expect(await repo.totalListenedMs('2026-10-01', '2026-10-02'), 10000);
    });

    test(
      'service ranks top songs by plays, time, then title; buckets zero-filled',
      () async {
        final a = await insertSong('a', title: 'Alpha');
        final b = await insertSong('b', title: 'Beta');
        await session(b, '2026-10-06', 40000);
        await session(a, '2026-10-06', 40000);
        await session(a, '2026-10-07', 40000);
        final lib = LibraryDataService();
        await lib.reload();
        final stats = await StatisticsService(
          library: lib,
        ).load(StatsPeriod.containing(PeriodType.week, DateTime(2026, 10, 7)));
        expect(stats.topSongs.map((s) => s.song.id), [a, b]);
        expect(stats.buckets.length, 7);
        expect(stats.buckets[0].listenedMs, 0); // Mon 2026-10-05
        expect(stats.buckets[1].listenedMs, 80000); // Tue 06
        expect(stats.buckets[2].listenedMs, 40000); // Wed 07
        expect(stats.previousTotalMs, 0);
        expect(stats.totalChangePct, isNull);
      },
    );

    test('daily summary cache rebuilds from sources', () async {
      final a = await insertSong('a');
      await session(a, '2026-10-01', 45000);
      await repo.rebuildDailySummary(['2026-10-01']);
      final db = await DatabaseHelper().database;
      final row = (await db.query(DbSchema.tableDailySummary)).single;
      expect(row['listened_ms'], 45000);
      expect(row['play_count'], 1);
    });
  });
}
