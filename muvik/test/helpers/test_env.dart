import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/song.dart';
import 'package:muvik/repository/song_repository.dart';
import 'package:muvik/services/storage/database_helper.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Fresh in-memory muvik.db (+ mock prefs) for each test.
Future<void> setUpTestDb() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  DatabaseHelper.factoryOverride = databaseFactoryFfi;
  DatabaseHelper.pathOverride = inMemoryDatabasePath;
  await DatabaseHelper().closeForTest();
  SharedPreferences.setMockInitialValues({});
  await PrefStore.init();
}

Future<void> tearDownTestDb() => DatabaseHelper().closeForTest();

Future<int> insertSong(
  String identity, {
  String? title,
  String? artist,
  int durationMs = 180000,
  int sourceId = 1,
}) {
  final now = DateTime(2026, 10, 1);
  return SongRepository().insert(
    Song(
      sourceId: sourceId,
      identity: identity,
      uri: 'content://media/$identity',
      title: title ?? identity,
      artist: artist,
      durationMs: durationMs,
      folderPath: 'Music',
      fileName: '$identity.mp3',
      firstSeenAt: now,
      updatedAt: now,
    ),
  );
}
