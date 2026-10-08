import '../../utils/date_utils.dart';

/// In-memory state of the session being listened to.
class ActiveSession {
  ActiveSession({
    required this.songId,
    required this.startedAt,
    required this.durationMs,
  });

  final int songId;
  final DateTime startedAt;
  final int durationMs;

  /// Database id once the session row has been inserted.
  int? dbId;
  final Map<String, int> perDayMs = {};
  final Map<String, int> tzOffsetMin = {};
  bool qualified = false;
  String? qualifiedDateKey;

  /// Qualification already announced to listeners.
  bool qualifiedReported = false;
  DateTime? endedAt;
  String? endReason;

  int get listenedMs => perDayMs.values.fold(0, (a, b) => a + b);
  bool get ended => endedAt != null;
}

/// Counts real audible time per local day and decides when a session becomes
/// one "play" (P16-01..P16-06). Elapsed time comes from a monotonic clock, so
/// seeking, pausing, buffering or wall-clock changes never add listening time;
/// the wall clock is used only to attribute time to days.
class ListeningTracker {
  ListeningTracker({required this.qualifyMs});

  final int qualifyMs;
  ActiveSession? _active;
  final Set<String> _dirtyDays = {};

  ActiveSession? get active => _active;

  /// Days touched since the last [takeDirtyDays].
  Set<String> takeDirtyDays() {
    final d = Set.of(_dirtyDays);
    _dirtyDays.clear();
    return d;
  }

  /// Starts a new session; any previous one is ended first and returned.
  ActiveSession? start(
    int songId,
    int durationMs,
    DateTime now, {
    String previousEndReason = 'switched',
  }) {
    final ended = end(now, previousEndReason);
    _active = ActiveSession(
      songId: songId,
      startedAt: now,
      durationMs: durationMs,
    );
    return ended;
  }

  /// Adds [elapsedMs] of audible playback that finished at wall time [now].
  /// Time is split across local midnights.
  void addListened(int elapsedMs, DateTime now) {
    final s = _active;
    if (s == null || s.ended || elapsedMs <= 0) return;
    var cursor = now.subtract(Duration(milliseconds: elapsedMs));
    while (cursor.isBefore(now)) {
      final midnight = AppDateUtils.nextMidnight(cursor);
      final segEnd = midnight.isBefore(now) ? midnight : now;
      final ms = segEnd.difference(cursor).inMilliseconds;
      if (ms <= 0) break;
      final key = AppDateUtils.formatDateKey(cursor);
      s.perDayMs[key] = (s.perDayMs[key] ?? 0) + ms;
      s.tzOffsetMin[key] = cursor.timeZoneOffset.inMinutes;
      _dirtyDays.add(key);
      cursor = segEnd;
    }
    if (!s.qualified && s.listenedMs >= qualifyMs) {
      _qualify(s, now);
    }
  }

  /// Track reached its natural end. A track shorter than the threshold counts
  /// only in this case (P16-02).
  ActiveSession? completeNaturally(DateTime now) {
    final s = _active;
    if (s == null || s.ended) return null;
    if (!s.qualified && s.durationMs > 0 && s.durationMs < qualifyMs) {
      _qualify(s, now);
    }
    return end(now, 'completed');
  }

  ActiveSession? end(DateTime now, String reason) {
    final s = _active;
    if (s == null || s.ended) return null;
    s.endedAt = now;
    s.endReason = reason;
    _active = null;
    return s;
  }

  void _qualify(ActiveSession s, DateTime now) {
    s.qualified = true;
    s.qualifiedDateKey = AppDateUtils.formatDateKey(now);
    _dirtyDays.add(s.qualifiedDateKey!);
  }
}
