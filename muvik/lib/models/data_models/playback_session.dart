/// One continuous play of a song. Counts as a "play" once (`qualified`) when
/// >= 30 s of real listening, or a shorter song ends naturally (P16-02).
class PlaybackSession {
  const PlaybackSession({
    this.id,
    required this.songId,
    required this.startedAt,
    this.endedAt,
    this.listenedMs = 0,
    this.qualified = false,
    this.qualifiedDateKey,
    this.endReason,
  });

  final int? id;
  final int songId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int listenedMs;
  final bool qualified;

  /// Local date on which the session became qualified (period attribution).
  final String? qualifiedDateKey;
  final String? endReason;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'song_id': songId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt?.toUtc().toIso8601String(),
    'listened_ms': listenedMs,
    'qualified': qualified ? 1 : 0,
    'qualified_date_key': qualifiedDateKey,
    'end_reason': endReason,
  };

  factory PlaybackSession.fromMap(Map<String, Object?> m) => PlaybackSession(
    id: m['id'] as int?,
    songId: m['song_id'] as int,
    startedAt: DateTime.parse(m['started_at'] as String).toLocal(),
    endedAt: m['ended_at'] == null
        ? null
        : DateTime.parse(m['ended_at'] as String).toLocal(),
    listenedMs: (m['listened_ms'] as int?) ?? 0,
    qualified: (m['qualified'] as int?) == 1,
    qualifiedDateKey: m['qualified_date_key'] as String?,
    endReason: m['end_reason'] as String?,
  );
}
