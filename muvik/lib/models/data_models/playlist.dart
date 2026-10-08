class Playlist {
  const Playlist({
    this.id,
    required this.name,
    this.description = '',
    this.coverUri,
    required this.createdAt,
    required this.updatedAt,
    this.songCount = 0,
    this.durationMs = 0,
    this.firstSongId,
  });

  final int? id;
  final String name;
  final String description;
  final String? coverUri;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Aggregates filled by queries (not stored columns).
  final int songCount;
  final int durationMs;
  final int? firstSongId;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'cover_uri': coverUri,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory Playlist.fromMap(Map<String, Object?> m) => Playlist(
    id: m['id'] as int?,
    name: (m['name'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    coverUri: m['cover_uri'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
    songCount: (m['song_count'] as int?) ?? 0,
    durationMs: (m['duration_ms'] as int?) ?? 0,
    firstSongId: m['first_song_id'] as int?,
  );

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    String? coverUri,
    bool clearCover = false,
    DateTime? updatedAt,
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    coverUri: clearCover ? null : (coverUri ?? this.coverUri),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    songCount: songCount,
    durationMs: durationMs,
    firstSongId: firstSongId,
  );
}
