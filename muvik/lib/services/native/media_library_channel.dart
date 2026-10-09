import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../utils/app_log.dart';

class StorageVolumeInfo {
  const StorageVolumeInfo({
    required this.name,
    required this.description,
    required this.isPrimary,
    required this.isRemovable,
    required this.mounted,
    this.freeBytes,
  });

  /// MediaStore volume name, e.g. `external_primary` or `1234-abcd`.
  final String name;
  final String description;
  final bool isPrimary;
  final bool isRemovable;
  final bool mounted;
  final int? freeBytes;

  factory StorageVolumeInfo.fromMap(Map m) => StorageVolumeInfo(
    name: m['name'] as String,
    description: (m['description'] as String?) ?? '',
    isPrimary: (m['isPrimary'] as bool?) ?? false,
    isRemovable: (m['isRemovable'] as bool?) ?? false,
    mounted: (m['mounted'] as bool?) ?? true,
    freeBytes: (m['freeBytes'] as num?)?.toInt(),
  );
}

/// A raw audio row from MediaStore or a SAF tree.
class RawAudioFile {
  const RawAudioFile({
    required this.uri,
    this.mediaId,
    this.title,
    this.artist,
    this.album,
    this.albumId,
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.mimeType,
    required this.relativePath,
    required this.fileName,
    this.dateAddedMs = 0,
    this.genre,
  });

  final String uri;
  final int? mediaId;
  final String? title;
  final String? artist;
  final String? album;
  final int? albumId;
  final int durationMs;
  final int sizeBytes;
  final String? mimeType;

  /// Folder path relative to the volume/tree root, with trailing '/'.
  final String relativePath;
  final String fileName;
  final int dateAddedMs;

  /// Genre tag as stored in the file (may be null or free text).
  final String? genre;

  factory RawAudioFile.fromMap(Map m) => RawAudioFile(
    uri: m['uri'] as String,
    mediaId: (m['mediaId'] as num?)?.toInt(),
    title: m['title'] as String?,
    artist: m['artist'] as String?,
    album: m['album'] as String?,
    albumId: (m['albumId'] as num?)?.toInt(),
    durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
    sizeBytes: (m['size'] as num?)?.toInt() ?? 0,
    mimeType: m['mime'] as String?,
    relativePath: (m['relativePath'] as String?) ?? '',
    fileName: (m['displayName'] as String?) ?? '',
    dateAddedMs: (m['dateAddedMs'] as num?)?.toInt() ?? 0,
    genre: m['genre'] as String?,
  );
}

class AudioFormatInfo {
  const AudioFormatInfo({
    this.mimeType,
    this.bitrate,
    this.sampleRate,
    this.channels,
  });
  final String? mimeType;
  final int? bitrate;
  final int? sampleRate;
  final int? channels;
}

/// Dart side of the native media library (Android MediaStore + SAF).
class MediaLibraryChannel {
  MediaLibraryChannel._();
  static const MethodChannel _ch = MethodChannel(
    'com.asctechsoft.muvik/media_library',
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static int? _sdkInt;

  /// Android API level (0 on other platforms).
  static Future<int> sdkInt() async {
    if (!isSupported) return 0;
    return _sdkInt ??= (await _ch.invokeMethod<int>('sdkInt')) ?? 0;
  }

  static Future<List<StorageVolumeInfo>> getVolumes() async {
    if (!isSupported) return const [];
    final r = await _ch.invokeListMethod<Map>('getVolumes');
    return (r ?? const []).map(StorageVolumeInfo.fromMap).toList();
  }

  static Future<int> countVolume(String volume) async {
    final r = await _ch.invokeMethod<int>('countVolume', {'volume': volume});
    return r ?? 0;
  }

  static Future<List<RawAudioFile>> queryVolume(
    String volume, {
    required int offset,
    required int limit,
  }) async {
    final r = await _ch.invokeListMethod<Map>('queryVolume', {
      'volume': volume,
      'offset': offset,
      'limit': limit,
    });
    return (r ?? const []).map(RawAudioFile.fromMap).toList();
  }

  /// Opens the system folder picker; returns {uri, name} or null if cancelled.
  static Future<({String uri, String name})?> pickFolder() async {
    final r = await _ch.invokeMapMethod<String, dynamic>('pickFolder');
    if (r == null) return null;
    return (uri: r['uri'] as String, name: (r['name'] as String?) ?? '');
  }

  static Future<bool> hasTreePermission(String uri) async =>
      (await _ch.invokeMethod<bool>('hasTreePermission', {'uri': uri})) ??
      false;

  static Future<void> releaseTree(String uri) async {
    try {
      await _ch.invokeMethod('releaseTree', {'uri': uri});
    } on PlatformException catch (e) {
      AppLog.info('MediaLibraryChannel.releaseTree: $e');
    }
  }

  /// Lists audio documents under a SAF tree (no metadata yet).
  static Future<List<RawAudioFile>> listTree(String uri) async {
    final r = await _ch.invokeListMethod<Map>('listTree', {'uri': uri});
    return (r ?? const []).map(RawAudioFile.fromMap).toList();
  }

  /// Reads tags for document URIs; missing/unreadable entries are omitted.
  static Future<Map<String, Map>> readMetadata(List<String> uris) async {
    final r = await _ch.invokeMapMethod<String, Map>('readMetadata', {
      'uris': uris,
    });
    return r ?? const {};
  }

  static Future<Uint8List?> getArtwork(String uri, {int size = 256}) async {
    if (!isSupported) return null;
    try {
      return await _ch.invokeMethod<Uint8List>('getArtwork', {
        'uri': uri,
        'size': size,
      });
    } on PlatformException {
      return null;
    }
  }

  static Future<AudioFormatInfo?> getAudioFormat(String uri) async {
    if (!isSupported) return null;
    final r = await _ch.invokeMapMethod<String, dynamic>('getAudioFormat', {
      'uri': uri,
    });
    if (r == null) return null;
    return AudioFormatInfo(
      mimeType: r['mime'] as String?,
      bitrate: (r['bitrate'] as num?)?.toInt(),
      sampleRate: (r['sampleRate'] as num?)?.toInt(),
      channels: (r['channels'] as num?)?.toInt(),
    );
  }

  /// Checks whether content URIs are still readable.
  static Future<Set<String>> existing(List<String> uris) async {
    if (!isSupported || uris.isEmpty) return uris.toSet();
    final r = await _ch.invokeListMethod<String>('existing', {'uris': uris});
    return (r ?? const []).toSet();
  }
}
