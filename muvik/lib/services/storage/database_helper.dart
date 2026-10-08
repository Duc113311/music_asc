import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';
import '../../utils/app_log.dart';

/// Singleton SQLite opener. A Completer blocks concurrent opens (P04-01).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  /// Tests inject an ffi factory and in-memory path.
  @visibleForTesting
  static DatabaseFactory? factoryOverride;
  @visibleForTesting
  static String? pathOverride;

  Database? _database;
  Completer<Database>? _initCompleter;

  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;
    final pending = _initCompleter;
    if (pending != null) return pending.future;
    final completer = Completer<Database>();
    _initCompleter = completer;
    try {
      final opened = await _open();
      _database = opened;
      completer.complete(opened);
      return opened;
    } catch (e, st) {
      AppLog.error('DatabaseHelper.open', e, st);
      completer.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final factory = factoryOverride ?? databaseFactory;
    final path =
        pathOverride ??
        p.join(await factory.getDatabasesPath(), DbSchema.dbName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DbSchema.dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final sql in DbSchema.createV1) {
      batch.execute(sql);
    }
    await batch.commit(noResult: true);
    // Apply any later migrations so a fresh install equals an upgraded one.
    await _onUpgrade(db, 1, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      final steps = DbSchema.migrations[v];
      if (steps == null) continue;
      for (final sql in steps) {
        await db.execute(sql);
      }
    }
  }

  @visibleForTesting
  Future<void> closeForTest() async {
    await _database?.close();
    _database = null;
    _initCompleter = null;
  }
}
