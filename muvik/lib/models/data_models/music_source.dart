enum SourceType {
  /// A MediaStore volume (internal storage or SD card) read via audio permission.
  volume('volume'),

  /// A folder picked with the Storage Access Framework (persisted tree URI).
  tree('tree');

  const SourceType(this.key);
  final String key;

  static SourceType fromKey(String? k) => SourceType.values.firstWhere(
    (t) => t.key == k,
    orElse: () => SourceType.volume,
  );
}

class MusicSource {
  const MusicSource({
    this.id,
    required this.type,
    required this.uri,
    required this.displayName,
    this.removable = false,
    this.enabled = true,
    this.accessible = true,
    this.lastScanAt,
    this.lastScanStatus,
    this.songCount = 0,
  });

  final int? id;
  final SourceType type;

  /// Volume name (e.g. `external_primary`) or SAF tree URI.
  final String uri;
  final String displayName;
  final bool removable;
  final bool enabled;
  final bool accessible;
  final DateTime? lastScanAt;
  final String? lastScanStatus;
  final int songCount;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.key,
    'uri': uri,
    'display_name': displayName,
    'removable': removable ? 1 : 0,
    'enabled': enabled ? 1 : 0,
    'accessible': accessible ? 1 : 0,
    'last_scan_at': lastScanAt?.toUtc().toIso8601String(),
    'last_scan_status': lastScanStatus,
    'song_count': songCount,
  };

  factory MusicSource.fromMap(Map<String, Object?> m) => MusicSource(
    id: m['id'] as int?,
    type: SourceType.fromKey(m['type'] as String?),
    uri: m['uri'] as String,
    displayName: (m['display_name'] as String?) ?? '',
    removable: (m['removable'] as int?) == 1,
    enabled: (m['enabled'] as int?) == 1,
    accessible: (m['accessible'] as int?) == 1,
    lastScanAt: m['last_scan_at'] == null
        ? null
        : DateTime.parse(m['last_scan_at'] as String).toLocal(),
    lastScanStatus: m['last_scan_status'] as String?,
    songCount: (m['song_count'] as int?) ?? 0,
  );

  MusicSource copyWith({
    int? id,
    String? displayName,
    bool? removable,
    bool? enabled,
    bool? accessible,
    DateTime? lastScanAt,
    String? lastScanStatus,
    int? songCount,
  }) => MusicSource(
    id: id ?? this.id,
    type: type,
    uri: uri,
    displayName: displayName ?? this.displayName,
    removable: removable ?? this.removable,
    enabled: enabled ?? this.enabled,
    accessible: accessible ?? this.accessible,
    lastScanAt: lastScanAt ?? this.lastScanAt,
    lastScanStatus: lastScanStatus ?? this.lastScanStatus,
    songCount: songCount ?? this.songCount,
  );
}
