import '../../utils/metadata_fallback.dart';

/// A local audio file known to the library. `identity` is stable across scans:
/// volume + relative path + file name (or the SAF document URI), so the same
/// file reached from overlapping sources is stored once, while two files with
/// the same name in different folders stay separate (P05-07).
class Song {
  const Song({
    this.id,
    required this.sourceId,
    required this.identity,
    required this.uri,
    this.mediaId,
    required this.title,
    this.artist,
    this.album,
    this.albumId,
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.mimeType,
    required this.folderPath,
    required this.fileName,
    this.dateAddedMs = 0,
    required this.firstSeenAt,
    required this.updatedAt,
    this.available = true,
    this.hidden = false,
    this.favorite = false,
    this.favoriteAt,
  });

  final int? id;
  final int sourceId;
  final String identity;
  final String uri;
  final int? mediaId;
  final String title;
  final String? artist;
  final String? album;
  final int? albumId;
  final int durationMs;
  final int sizeBytes;
  final String? mimeType;
  final String folderPath;
  final String fileName;
  final int dateAddedMs;
  final DateTime firstSeenAt;
  final DateTime updatedAt;
  final bool available;
  final bool hidden;
  final bool favorite;
  final DateTime? favoriteAt;

  Duration get duration => Duration(milliseconds: durationMs);

  /// Title with file-name fallback (P05-08).
  String get displayTitle => MetadataFallback.title(title, fileName);

  /// Raw artist or null if unknown; UI shows a localized "Unknown" label.
  String? get artistOrNull => MetadataFallback.clean(artist);
  String? get albumOrNull => MetadataFallback.clean(album);

  String get folderName {
    final p = folderPath.endsWith('/')
        ? folderPath.substring(0, folderPath.length - 1)
        : folderPath;
    final i = p.lastIndexOf('/');
    return i >= 0 ? p.substring(i + 1) : p;
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'source_id': sourceId,
    'identity': identity,
    'uri': uri,
    'media_id': mediaId,
    'title': title,
    'artist': artist,
    'album': album,
    'album_id': albumId,
    'duration_ms': durationMs,
    'size_bytes': sizeBytes,
    'mime_type': mimeType,
    'folder_path': folderPath,
    'file_name': fileName,
    'date_added_ms': dateAddedMs,
    'first_seen_at': firstSeenAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'available': available ? 1 : 0,
    'hidden': hidden ? 1 : 0,
    'favorite': favorite ? 1 : 0,
    'favorite_at': favoriteAt?.toUtc().toIso8601String(),
    'search_key': MetadataFallback.searchKey([
      displayTitle,
      artist ?? '',
      album ?? '',
      fileName,
      folderName,
    ]),
  };

  factory Song.fromMap(Map<String, Object?> m) => Song(
    id: m['id'] as int?,
    sourceId: m['source_id'] as int,
    identity: m['identity'] as String,
    uri: m['uri'] as String,
    mediaId: m['media_id'] as int?,
    title: (m['title'] as String?) ?? '',
    artist: m['artist'] as String?,
    album: m['album'] as String?,
    albumId: m['album_id'] as int?,
    durationMs: (m['duration_ms'] as int?) ?? 0,
    sizeBytes: (m['size_bytes'] as int?) ?? 0,
    mimeType: m['mime_type'] as String?,
    folderPath: (m['folder_path'] as String?) ?? '',
    fileName: (m['file_name'] as String?) ?? '',
    dateAddedMs: (m['date_added_ms'] as int?) ?? 0,
    firstSeenAt: DateTime.parse(m['first_seen_at'] as String).toLocal(),
    updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
    available: (m['available'] as int?) == 1,
    hidden: (m['hidden'] as int?) == 1,
    favorite: (m['favorite'] as int?) == 1,
    favoriteAt: m['favorite_at'] == null
        ? null
        : DateTime.parse(m['favorite_at'] as String).toLocal(),
  );

  Song copyWith({
    int? id,
    int? sourceId,
    String? uri,
    int? mediaId,
    String? title,
    String? artist,
    String? album,
    int? albumId,
    int? durationMs,
    int? sizeBytes,
    String? mimeType,
    String? folderPath,
    String? fileName,
    int? dateAddedMs,
    DateTime? updatedAt,
    bool? available,
    bool? hidden,
    bool? favorite,
    DateTime? favoriteAt,
  }) => Song(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    identity: identity,
    uri: uri ?? this.uri,
    mediaId: mediaId ?? this.mediaId,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    albumId: albumId ?? this.albumId,
    durationMs: durationMs ?? this.durationMs,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mimeType: mimeType ?? this.mimeType,
    folderPath: folderPath ?? this.folderPath,
    fileName: fileName ?? this.fileName,
    dateAddedMs: dateAddedMs ?? this.dateAddedMs,
    firstSeenAt: firstSeenAt,
    updatedAt: updatedAt ?? this.updatedAt,
    available: available ?? this.available,
    hidden: hidden ?? this.hidden,
    favorite: favorite ?? this.favorite,
    favoriteAt: favoriteAt ?? this.favoriteAt,
  );

  /// True when scanned metadata differs from what is stored (used to count
  /// "updated" without rewriting identical rows).
  bool metadataDiffers(Song o) =>
      uri != o.uri ||
      mediaId != o.mediaId ||
      title != o.title ||
      artist != o.artist ||
      album != o.album ||
      albumId != o.albumId ||
      durationMs != o.durationMs ||
      sizeBytes != o.sizeBytes ||
      mimeType != o.mimeType ||
      folderPath != o.folderPath ||
      fileName != o.fileName;

  @override
  bool operator ==(Object other) =>
      other is Song &&
      other.id == id &&
      other.identity == identity &&
      other.favorite == favorite &&
      other.available == available &&
      other.hidden == hidden &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, identity, favorite, available, hidden);
}
