/// Rebuildable per-day cache of listening time and qualified plays. Distinct
/// songs are never summed from this table (P04-08) — they are queried from
/// sessions over the whole period.
class DailySummary {
  const DailySummary({
    required this.dateKey,
    this.listenedMs = 0,
    this.playCount = 0,
    required this.updatedAt,
  });

  final String dateKey;
  final int listenedMs;
  final int playCount;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'date_key': dateKey,
    'listened_ms': listenedMs,
    'play_count': playCount,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory DailySummary.fromMap(Map<String, Object?> m) => DailySummary(
    dateKey: m['date_key'] as String,
    listenedMs: (m['listened_ms'] as int?) ?? 0,
    playCount: (m['play_count'] as int?) ?? 0,
    updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
  );
}
