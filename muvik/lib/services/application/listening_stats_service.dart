import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../configs/app_config.dart';
import '../../models/data_models/playback_session.dart';
import '../../repository/listening_repository.dart';
import '../storage/database_helper.dart';
import 'audio_handler.dart';
import 'listening_tracker.dart';
import '../../utils/app_log.dart';

/// Observes the single player and records real listening (P16-01..06).
/// Writes are serialized and idempotent (absolute values per session/day),
/// flushed every [AppConfig.statsCheckpoint] while audible and on every
/// pause/stop/track change, so a crash loses at most one checkpoint.
class ListeningStatsService {
  ListeningStatsService({
    required this.handler,
    ListeningRepository? repository,
  }) : _repo = repository ?? ListeningRepository();

  final MuvikAudioHandler handler;
  final ListeningRepository _repo;
  final ListeningTracker _tracker = ListeningTracker(
    qualifyMs: AppConfig.qualifyingListen.inMilliseconds,
  );
  final Stopwatch _sw = Stopwatch();
  final DatabaseHelper _db = DatabaseHelper();

  /// Bumped whenever a session ends or qualifies — screens reload history.
  final ValueNotifier<int> revision = ValueNotifier(0);

  int _generation = -1;
  Timer? _checkpoint;
  Future<void> _chain = Future.value();
  StreamSubscription<PlayerEvent>? _sub;

  Future<void> init() async {
    try {
      await _repo.closeDanglingSessions();
    } catch (e) {
      AppLog.error('ListeningStatsService.recover', e);
    }
    _sub = handler.events.listen(_onEvent);
    handler.audible.addListener(_onAudibleChanged);
  }

  void _onEvent(PlayerEvent e) {
    final now = DateTime.now();
    switch (e.type) {
      case PlayerEventType.trackStarted:
        if (e.songId == null) return;
        // Guard against duplicate callbacks for the same start (P16-03).
        if (e.generation == _generation && _tracker.active != null) return;
        _accumulate(now);
        final ended = _tracker.start(e.songId!, e.durationMs, now);
        _generation = e.generation;
        _persist(ended, ended: true);
      case PlayerEventType.trackCompleted:
        if (e.generation != _generation) return;
        _accumulate(now);
        _persist(_tracker.completeNaturally(now), ended: true);
      case PlayerEventType.trackLeft:
        _accumulate(now);
        _persist(_tracker.end(now, 'skipped'), ended: true);
      case PlayerEventType.stopped:
        _accumulate(now);
        _persist(_tracker.end(now, 'stopped'), ended: true);
      case PlayerEventType.error:
        break;
    }
  }

  void _onAudibleChanged() {
    final now = DateTime.now();
    if (handler.audible.value) {
      if (!_sw.isRunning) _sw.start();
      _checkpoint ??= Timer.periodic(AppConfig.statsCheckpoint, (_) {
        _accumulate(DateTime.now());
        _persist(_tracker.active, ended: false);
      });
    } else {
      _accumulate(now);
      _sw.stop();
      _checkpoint?.cancel();
      _checkpoint = null;
      _persist(_tracker.active, ended: false);
    }
  }

  void _accumulate(DateTime now) {
    final ms = _sw.elapsedMilliseconds;
    _sw.reset();
    if (ms > 0) _tracker.addListened(ms, now);
  }

  void _persist(ActiveSession? s, {required bool ended}) {
    if (s == null) return;
    final days = _tracker.takeDirtyDays();
    final wasQualified = s.qualified;
    _chain = _chain.then((_) async {
      // Sessions with no audible time and no qualification are not history.
      if (s.dbId == null && s.listenedMs == 0 && !s.qualified) return;
      try {
        final db = await _db.database;
        await db.transaction((txn) async {
          final row = PlaybackSession(
            id: s.dbId,
            songId: s.songId,
            startedAt: s.startedAt,
            endedAt: s.endedAt,
            listenedMs: s.listenedMs,
            qualified: s.qualified,
            qualifiedDateKey: s.qualifiedDateKey,
            endReason: s.endReason,
          );
          if (s.dbId == null) {
            s.dbId = await _repo.insertSession(row, exec: txn);
          } else {
            await _repo.updateSession(row, exec: txn);
          }
          for (final entry in s.perDayMs.entries) {
            await _repo.upsertSegment(
              sessionId: s.dbId!,
              songId: s.songId,
              dateKey: entry.key,
              listenedMs: entry.value,
              tzOffsetMinutes: s.tzOffsetMin[entry.key] ?? 0,
              exec: txn,
            );
          }
          await _repo.rebuildDailySummary({
            ...days,
            ...s.perDayMs.keys,
            ?s.qualifiedDateKey,
          }, exec: txn);
        });
        if (ended || (wasQualified && !s.qualifiedReported)) {
          s.qualifiedReported = wasQualified;
          revision.value++;
        }
      } catch (e, st) {
        AppLog.error('ListeningStatsService.persist', e, st);
      }
    });
  }

  /// Flushes pending time (app going to background / shutting down).
  Future<void> flush() async {
    _accumulate(DateTime.now());
    _persist(_tracker.active, ended: false);
    await _chain;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    handler.audible.removeListener(_onAudibleChanged);
    _checkpoint?.cancel();
  }
}
