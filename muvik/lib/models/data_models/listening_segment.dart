/// Real listening time of a session on one local day. A session crossing
/// midnight has several segments (P16-04). Unique (session_id, date_key);
/// `listened_ms` is written as an absolute value so re-flushing is idempotent.
class ListeningSegment {
  const ListeningSegment({
    this.id,
    required this.sessionId,
    required this.songId,
    required this.dateKey,
    required this.listenedMs,
    required this.tzOffsetMinutes,
    required this.updatedAt,
  });

  final int? id;
  final int sessionId;
  final int songId;
  final String dateKey;
  final int listenedMs;
  final int tzOffsetMinutes;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'song_id': songId,
    'date_key': dateKey,
    'listened_ms': listenedMs,
    'tz_offset_min': tzOffsetMinutes,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory ListeningSegment.fromMap(Map<String, Object?> m) => ListeningSegment(
    id: m['id'] as int?,
    sessionId: m['session_id'] as int,
    songId: m['song_id'] as int,
    dateKey: m['date_key'] as String,
    listenedMs: (m['listened_ms'] as int?) ?? 0,
    tzOffsetMinutes: (m['tz_offset_min'] as int?) ?? 0,
    updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
  );
}
