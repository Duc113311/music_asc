import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../configs/app_config.dart';
import '../../models/data_models/excluded_item.dart';
import '../../models/data_models/music_source.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/scan_state.dart';
import '../../repository/exclusion_repository.dart';
import '../../repository/song_repository.dart';
import '../../repository/source_repository.dart';
import '../native/media_library_channel.dart';
import '../storage/database_helper.dart';
import 'library_data_service.dart';
import 'song_identity.dart';
import '../../utils/app_log.dart';

enum AudioPermissionStatus { granted, denied, permanentlyDenied }

/// Permission, sources and scanning (P05). One scan at a time; a second
/// request while running just observes the current [state] (P05-06).
class LibraryScanService {
  LibraryScanService({
    required this.library,
    SongRepository? songs,
    SourceRepository? sources,
    ExclusionRepository? exclusions,
  }) : _songs = songs ?? SongRepository(),
       _sources = sources ?? SourceRepository(),
       _exclusions = exclusions ?? ExclusionRepository();

  final LibraryDataService library;
  final SongRepository _songs;
  final SourceRepository _sources;
  final ExclusionRepository _exclusions;
  final DatabaseHelper _db = DatabaseHelper();

  final ValueNotifier<ScanState> state = ValueNotifier(const ScanState());
  final ValueNotifier<List<MusicSource>> sources = ValueNotifier(const []);
  final ValueNotifier<AudioPermissionStatus> permission = ValueNotifier(
    AudioPermissionStatus.denied,
  );

  Future<ScanState>? _running;
  bool _cancelRequested = false;

  // ------------------------------------------------------------ permission

  Future<Permission> _audioPermission() async {
    final sdk = await MediaLibraryChannel.sdkInt();
    return sdk >= 33 ? Permission.audio : Permission.storage;
  }

  Future<AudioPermissionStatus> checkPermission() async {
    if (!MediaLibraryChannel.isSupported) {
      return permission.value = AudioPermissionStatus.denied;
    }
    final s = await (await _audioPermission()).status;
    return permission.value = _map(s);
  }

  /// Shows the system dialog. Never asks again if permanently denied — the
  /// UI offers "Mở cài đặt" instead (P06-10).
  Future<AudioPermissionStatus> requestPermission() async {
    if (!MediaLibraryChannel.isSupported) return permission.value;
    final s = await (await _audioPermission()).request();
    return permission.value = _map(s);
  }

  Future<bool> openSystemSettings() => openAppSettings();

  AudioPermissionStatus _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return AudioPermissionStatus.granted;
    if (s.isPermanentlyDenied || s.isRestricted) {
      return AudioPermissionStatus.permanentlyDenied;
    }
    return AudioPermissionStatus.denied;
  }

  // ------------------------------------------------------------ sources

  /// Syncs MediaStore volumes and SAF grants into music_sources.
  Future<List<MusicSource>> refreshSources() async {
    try {
      final granted = permission.value == AudioPermissionStatus.granted;
      if (granted && MediaLibraryChannel.isSupported) {
        final volumes = await MediaLibraryChannel.getVolumes();
        final known = await _sources.getAll();
        for (final v in volumes) {
          final existing = known
              .where((s) => s.type == SourceType.volume && s.uri == v.name)
              .firstOrNull;
          if (existing == null) {
            await _sources.insert(
              MusicSource(
                type: SourceType.volume,
                uri: v.name,
                displayName: v.description,
                removable: v.isRemovable,
                // SD cards are opt-in; internal storage is preselected.
                enabled: !v.isRemovable,
                accessible: v.mounted,
              ),
            );
          } else if (existing.accessible != v.mounted ||
              existing.displayName != v.description) {
            await _sources.update(
              existing.copyWith(
                accessible: v.mounted,
                displayName: v.description,
              ),
            );
          }
        }
        // Volumes that disappeared (SD removed) become inaccessible.
        for (final s in known.where((s) => s.type == SourceType.volume)) {
          if (!volumes.any((v) => v.name == s.uri) && s.accessible) {
            await _markInaccessible(s);
          }
        }
      }
      for (final s in (await _sources.getAll()).where(
        (s) => s.type == SourceType.tree,
      )) {
        final ok =
            MediaLibraryChannel.isSupported &&
            await MediaLibraryChannel.hasTreePermission(s.uri);
        if (ok != s.accessible) {
          if (ok) {
            await _sources.update(s.copyWith(accessible: true));
          } else {
            await _markInaccessible(s);
          }
        }
      }
      if (!granted) {
        for (final s in (await _sources.getAll()).where(
          (s) => s.type == SourceType.volume && s.accessible,
        )) {
          await _markInaccessible(s);
        }
      }
    } catch (e, st) {
      AppLog.error('LibraryScanService.refreshSources', e, st);
    }
    final all = await _sources.getAll();
    sources.value = all;
    return all;
  }

  /// Source lost (permission revoked / card removed): keep rows, playlists
  /// and history; only flag them unavailable (P05-10, P05-11).
  Future<void> _markInaccessible(MusicSource s) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _sources.update(s.copyWith(accessible: false), exec: txn);
      await _songs.setAvailabilityForSource(s.id!, false, exec: txn);
    });
  }

  Future<MusicSource?> addFolderSource() async {
    final picked = await MediaLibraryChannel.pickFolder();
    if (picked == null) return null;
    final existing = await _sources.getByUri(picked.uri);
    if (existing != null) {
      await _sources.update(existing.copyWith(enabled: true, accessible: true));
    } else {
      await _sources.insert(
        MusicSource(
          type: SourceType.tree,
          uri: picked.uri,
          displayName: picked.name,
          enabled: true,
        ),
      );
    }
    await refreshSources();
    return _sources.getByUri(picked.uri);
  }

  Future<void> setSourceEnabled(MusicSource s, bool enabled) async {
    await _sources.update(s.copyWith(enabled: enabled));
    await refreshSources();
  }

  /// Removes a picked folder from the scan scope: songs are hidden in Muvik
  /// via exclusion of the folder, files are untouched.
  Future<void> setSourcesEnabled(Set<int> enabledIds) async {
    for (final s in await _sources.getAll()) {
      final want = enabledIds.contains(s.id);
      if (s.enabled != want) await _sources.update(s.copyWith(enabled: want));
    }
    await refreshSources();
  }

  // ------------------------------------------------------------ scanning

  void cancel() {
    if (state.value.isRunning) _cancelRequested = true;
  }

  /// Scans enabled, accessible sources (or [onlySourceIds]).
  Future<ScanState> scan({Set<int>? onlySourceIds}) {
    final running = _running;
    if (running != null) return running;
    final f = _scan(onlySourceIds).whenComplete(() => _running = null);
    _running = f;
    return f;
  }

  Future<ScanState> _scan(Set<int>? onlySourceIds) async {
    _cancelRequested = false;
    var s = const ScanState(status: ScanStatus.scanning);
    state.value = s;
    var anyFailed = false;
    try {
      final all = await refreshSources();
      final targets = all
          .where(
            (x) => x.accessible && (onlySourceIds?.contains(x.id) ?? x.enabled),
          )
          .toList();
      final exclusions = await _exclusions.getAll();

      // Total is known up front only for MediaStore volumes.
      int? total = 0;
      for (final src in targets) {
        if (src.type == SourceType.volume) {
          total = total! + await MediaLibraryChannel.countVolume(src.uri);
        } else {
          total = null;
          break;
        }
      }
      s = s.copyWith(total: total);
      state.value = s;

      for (final src in targets) {
        if (_cancelRequested) break;
        s = s.copyWith(currentSource: src.displayName);
        state.value = s;
        try {
          final result = await _scanSource(src, exclusions, s);
          s = result.state;
          if (result.completed) {
            final missing = result.missingIds;
            if (missing.isNotEmpty) {
              await _songs.setAvailability(missing, false);
              s = s.copyWith(markedMissing: s.markedMissing + missing.length);
            }
            await _sources.update(
              src.copyWith(
                lastScanAt: DateTime.now(),
                lastScanStatus: 'success',
                songCount: result.seenCount,
              ),
            );
          }
        } catch (e) {
          AppLog.info('LibraryScanService.scanSource ${src.uri}: $e');
          anyFailed = true;
          await _sources.update(
            src.copyWith(lastScanAt: DateTime.now(), lastScanStatus: 'error'),
          );
        }
      }

      s = s.copyWith(phase: ScanPhase.albums);
      state.value = s;
      await library.reload();
      s = s.copyWith(phase: ScanPhase.updating);
      state.value = s;
      await refreshSources();
      final status = _cancelRequested
          ? ScanStatus.cancelled
          : (anyFailed
                ? (s.processed > 0 ? ScanStatus.partial : ScanStatus.error)
                : (s.skipped > 0 ? ScanStatus.partial : ScanStatus.success));
      s = s.copyWith(status: status);
    } catch (e, st) {
      AppLog.error('LibraryScanService.scan', e, st);
      s = s.copyWith(status: ScanStatus.error, errorCode: e.toString());
      await library.reload();
    }
    state.value = s;
    return s;
  }

  Future<_SourceResult> _scanSource(
    MusicSource src,
    List<ExcludedItem> exclusions,
    ScanState start,
  ) async {
    var s = start;
    final seen = <String>{};
    final previouslyAvailable = await _songs.availableIdentitiesForSource(
      src.id!,
    );

    Future<void> handleBatch(
      List<RawAudioFile> files,
      String Function(RawAudioFile) identityOf,
    ) async {
      final candidates = <String, RawAudioFile>{};
      for (final f in files) {
        if (f.mimeType != null &&
            f.mimeType!.isNotEmpty &&
            !f.mimeType!.startsWith('audio/') &&
            !f.mimeType!.contains('ogg')) {
          s = s.copyWith(skipped: s.skipped + 1);
          continue;
        }
        final id = identityOf(f);
        seen.add(id);
        if (exclusions.any((e) => e.covers(id))) continue;
        candidates[id] = f;
      }
      final r = await _upsert(src, candidates);
      s = s.copyWith(
        processed: s.processed + files.length,
        added: s.added + r.added,
        updated: s.updated + r.updated,
      );
      state.value = s;
    }

    if (src.type == SourceType.volume) {
      var offset = 0;
      while (!_cancelRequested) {
        final batch = await MediaLibraryChannel.queryVolume(
          src.uri,
          offset: offset,
          limit: AppConfig.scanBatchSize,
        );
        if (batch.isEmpty) break;
        await handleBatch(
          batch,
          (f) => SongIdentity.fromVolume(src.uri, f.relativePath, f.fileName),
        );
        offset += batch.length;
        if (batch.length < AppConfig.scanBatchSize) break;
      }
    } else {
      final listed = await MediaLibraryChannel.listTree(src.uri);
      if (s.total == null) state.value = s;
      const metaBatch = 25;
      for (var i = 0; i < listed.length && !_cancelRequested; i += metaBatch) {
        final chunk = listed.sublist(
          i,
          i + metaBatch > listed.length ? listed.length : i + metaBatch,
        );
        final meta = await MediaLibraryChannel.readMetadata(
          chunk.map((f) => f.uri).toList(),
        );
        final readable = <RawAudioFile>[];
        for (final f in chunk) {
          final m = meta[f.uri];
          if (m == null) {
            // Unreadable or unsupported: reported, not added (P05-09).
            seen.add(SongIdentity.fromDocumentUri(f.uri));
            s = s.copyWith(skipped: s.skipped + 1, processed: s.processed + 1);
            continue;
          }
          readable.add(
            RawAudioFile(
              uri: f.uri,
              title: m['title'] as String?,
              artist: m['artist'] as String?,
              album: m['album'] as String?,
              genre: m['genre'] as String?,
              durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
              sizeBytes: f.sizeBytes,
              mimeType: f.mimeType,
              relativePath: f.relativePath,
              fileName: f.fileName,
              dateAddedMs: f.dateAddedMs,
            ),
          );
        }
        await handleBatch(readable, (f) => SongIdentity.fromDocumentUri(f.uri));
      }
    }

    final completed = !_cancelRequested;
    final missing = completed
        ? previouslyAvailable.entries
              .where((e) => !seen.contains(e.key))
              .map((e) => e.value)
              .toList()
        : <int>[];
    return _SourceResult(s, completed, missing, seen.length);
  }

  /// Inserts new identities, updates changed ones; favorites, playlists and
  /// history are preserved because rows are never deleted (P05-11).
  Future<({int added, int updated})> _upsert(
    MusicSource src,
    Map<String, RawAudioFile> files,
  ) async {
    if (files.isEmpty) return (added: 0, updated: 0);
    var added = 0;
    var updated = 0;
    final db = await _db.database;
    await db.transaction((txn) async {
      final existing = await _songs.getByIdentities(files.keys, exec: txn);
      final now = DateTime.now();
      for (final entry in files.entries) {
        final f = entry.value;
        final folder = _folderPath(src, f.relativePath);
        final old = existing[entry.key];
        if (old == null) {
          await _songs.insert(
            Song(
              sourceId: src.id!,
              identity: entry.key,
              uri: f.uri,
              mediaId: f.mediaId,
              title: f.title ?? '',
              artist: f.artist,
              album: f.album,
              albumId: f.albumId,
              durationMs: f.durationMs,
              sizeBytes: f.sizeBytes,
              mimeType: f.mimeType,
              folderPath: folder,
              fileName: f.fileName,
              dateAddedMs: f.dateAddedMs,
              genre: _cleanGenre(f.genre),
              firstSeenAt: now,
              updatedAt: now,
            ),
            exec: txn,
          );
          added++;
          continue;
        }
        final fresh = old.copyWith(
          sourceId: src.id,
          uri: f.uri,
          mediaId: f.mediaId,
          title: f.title ?? '',
          artist: f.artist,
          album: f.album,
          albumId: f.albumId,
          durationMs: f.durationMs,
          sizeBytes: f.sizeBytes,
          mimeType: f.mimeType,
          folderPath: folder,
          fileName: f.fileName,
          dateAddedMs: f.dateAddedMs,
          genre: _cleanGenre(f.genre),
          available: true,
          updatedAt: now,
        );
        final changed = old.metadataDiffers(fresh);
        // A newly read genre is saved but not reported as an "update".
        final genreChanged = old.genre != fresh.genre;
        if (changed ||
            genreChanged ||
            !old.available ||
            old.sourceId != src.id) {
          await _songs.update(fresh, exec: txn);
          if (changed) updated++;
        }
      }
    });
    return (added: added, updated: updated);
  }

  static String? _cleanGenre(String? g) {
    final t = g?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  String _folderPath(MusicSource src, String relativePath) {
    final root = src.type == SourceType.volume
        ? src.displayName
        : src.displayName;
    final rel = relativePath.endsWith('/')
        ? relativePath.substring(0, relativePath.length - 1)
        : relativePath;
    return rel.isEmpty ? root : '$root/$rel';
  }

  /// Light check on resume: permission + source availability, no full scan
  /// (P05-14).
  Future<void> refreshOnResume() async {
    if (state.value.isRunning) return;
    final before = permission.value;
    final accessBefore = {for (final s in sources.value) s.id: s.accessible};
    await checkPermission();
    final after = await refreshSources();
    final accessChanged = after.any((s) => accessBefore[s.id] != s.accessible);
    if (before != permission.value || accessChanged) await library.reload();
  }
}

class _SourceResult {
  const _SourceResult(
    this.state,
    this.completed,
    this.missingIds,
    this.seenCount,
  );
  final ScanState state;
  final bool completed;
  final List<int> missingIds;
  final int seenCount;
}
