import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/excluded_item.dart';
import 'package:muvik/models/ui_models/scan_state.dart';
import 'package:muvik/repository/song_repository.dart';
import 'package:muvik/services/application/library_data_service.dart';
import 'package:muvik/services/application/library_scan_service.dart';
import 'package:muvik/services/application/song_identity.dart';
import 'package:muvik/utils/metadata_fallback.dart';

import 'helpers/test_env.dart';

const _channel = MethodChannel('com.asctechsoft.muvik/media_library');

Map<String, Object?> _row(
  int id,
  String name, {
  String? title,
  String rel = 'Music/',
}) => {
  'uri': 'content://media/external_primary/audio/media/$id',
  'mediaId': id,
  'title': title ?? name,
  'artist': 'Artist',
  'album': 'Album',
  'albumId': 1,
  'durationMs': 200000,
  'size': 4000000,
  'mime': 'audio/mpeg',
  'displayName': '$name.mp3',
  'relativePath': rel,
  'dateAddedMs': 0,
};

void main() {
  late List<Map<String, Object?>> files;
  late bool volumeMounted;
  late LibraryDataService lib;
  late LibraryScanService scan;

  setUp(() async {
    await setUpTestDb();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    files = [];
    volumeMounted = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'sdkInt':
              return 34;
            case 'getVolumes':
              return volumeMounted
                  ? [
                      {
                        'name': 'external_primary',
                        'description': 'Internal storage',
                        'isPrimary': true,
                        'isRemovable': false,
                        'mounted': true,
                      },
                    ]
                  : <Map<String, Object?>>[];
            case 'countVolume':
              return files.length;
            case 'queryVolume':
              final args = call.arguments as Map;
              final offset = args['offset'] as int;
              final limit = args['limit'] as int;
              return files.skip(offset).take(limit).toList();
            case 'hasTreePermission':
              return true;
          }
          return null;
        });
    lib = LibraryDataService();
    scan = LibraryScanService(library: lib);
    scan.permission.value = AudioPermissionStatus.granted;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    await tearDownTestDb();
  });

  group('Library scan (P19-01)', () {
    test(
      'rescan never duplicates; same name in different folders stays separate',
      () async {
        files = [_row(1, 'a'), _row(2, 'b'), _row(3, 'a', rel: 'Download/')];
        final r1 = await scan.scan();
        expect(r1.status, ScanStatus.success);
        expect(r1.added, 3);
        final r2 = await scan.scan();
        expect(r2.added, 0);
        expect(r2.updated, 0);
        expect(r2.hasChanges, isFalse);
        expect(lib.visibleSongs.length, 3);
      },
    );

    test('metadata refresh keeps favorites', () async {
      files = [_row(1, 'a')];
      await scan.scan();
      final song = lib.visibleSongs.single;
      await lib.setFavorite(song.id!, true);
      files = [_row(1, 'a', title: 'New title')];
      final r = await scan.scan();
      expect(r.updated, 1);
      final fresh = lib.visibleSongs.single;
      expect(fresh.displayTitle, 'New title');
      expect(fresh.favorite, isTrue);
      expect(fresh.id, song.id);
    });

    test(
      'file gone after a complete scan is marked unavailable, not deleted',
      () async {
        files = [_row(1, 'a'), _row(2, 'b')];
        await scan.scan();
        files = [_row(1, 'a')];
        final r = await scan.scan();
        expect(r.markedMissing, 1);
        final all = await SongRepository().getVisible();
        expect(all.length, 2);
        expect(all.where((s) => !s.available).single.fileName, 'b.mp3');
        // Coming back makes it available again.
        files = [_row(1, 'a'), _row(2, 'b')];
        await scan.scan();
        expect(
          (await SongRepository().getVisible()).every((s) => s.available),
          isTrue,
        );
      },
    );

    test('excluded songs are not added back by rescans', () async {
      files = [_row(1, 'a'), _row(2, 'b')];
      await scan.scan();
      final b = lib.visibleSongs.firstWhere((s) => s.fileName == 'b.mp3');
      await lib.excludeSong(b);
      await scan.scan();
      expect(lib.visibleSongs.map((s) => s.fileName), ['a.mp3']);
    });

    test('folder exclusion covers files inside it', () {
      final ex = ExcludedItem(
        type: ExcludedType.folder,
        identity: 'external_primary/download/',
        createdAt: DateTime(2026),
      );
      expect(ex.covers('external_primary/download/x.mp3'), isTrue);
      expect(ex.covers('external_primary/downloads/x.mp3'), isFalse);
    });

    test('lost volume marks songs unavailable but keeps rows', () async {
      files = [_row(1, 'a')];
      await scan.scan();
      volumeMounted = false;
      await scan.refreshSources();
      await lib.reload();
      expect(lib.visibleSongs.single.available, isFalse);
      expect(scan.sources.value.single.accessible, isFalse);
    });

    test('a second scan request while running returns the same scan', () async {
      files = List.generate(10, (i) => _row(i + 1, 's$i'));
      final f1 = scan.scan();
      final f2 = scan.scan();
      expect(identical(await f1, await f2), isTrue);
    });
  });

  group('Identity and fallbacks', () {
    test('MediaStore row and SAF document of the same file share identity', () {
      final a = SongIdentity.fromVolume(
        'external_primary',
        'Music/Pop/',
        'Song.mp3',
      );
      final b = SongIdentity.fromDocumentUri(
        'content://com.android.externalstorage.documents/tree/primary%3AMusic/document/primary%3AMusic%2FPop%2FSong.mp3',
      );
      expect(a, b);
      expect(
        SongIdentity.fromVolume('external', 'Music', 'x.mp3'),
        'external_primary/music/x.mp3',
      );
    });

    test('missing title falls back to file name; unknown tags are null', () {
      expect(MetadataFallback.title(null, 'track01.flac'), 'track01');
      expect(MetadataFallback.title('<unknown>', 'a.mp3'), 'a');
      expect(MetadataFallback.clean('<unknown>'), isNull);
    });

    test('search normalization ignores case and Vietnamese diacritics', () {
      expect(
        MetadataFallback.normalize('Một Ngày Dịu Dàng'),
        'mot ngay diu dang',
      );
      expect(MetadataFallback.normalize('ĐƯỜNG VỀ'), 'duong ve');
    });
  });
}
