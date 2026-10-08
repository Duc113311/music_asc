enum ExcludedType {
  song('song'),
  folder('folder');

  const ExcludedType(this.key);
  final String key;

  static ExcludedType fromKey(String? k) => ExcludedType.values.firstWhere(
    (t) => t.key == k,
    orElse: () => ExcludedType.song,
  );
}

/// Something the user removed from the library ("Bỏ khỏi thư viện"). Scans
/// skip it; the file itself is never deleted (P04-05, P05-12).
class ExcludedItem {
  const ExcludedItem({
    this.id,
    required this.type,
    required this.identity,
    required this.createdAt,
  });

  final int? id;
  final ExcludedType type;

  /// Song identity, or folder identity prefix (volume/relative path).
  final String identity;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.key,
    'identity': identity,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory ExcludedItem.fromMap(Map<String, Object?> m) => ExcludedItem(
    id: m['id'] as int?,
    type: ExcludedType.fromKey(m['type'] as String?),
    identity: m['identity'] as String,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
  );

  /// Whether this exclusion covers a song with [songIdentity].
  bool covers(String songIdentity) => type == ExcludedType.song
      ? songIdentity == identity
      : songIdentity.startsWith(
          identity.endsWith('/') ? identity : '$identity/',
        );
}
