import 'package:sqflite/sqflite.dart';

import '../models/data_models/music_source.dart';
import '../services/storage/database_helper.dart';
import '../services/storage/schema.dart';

class SourceRepository {
  final DatabaseHelper _db = DatabaseHelper();
  static const String _t = DbSchema.tableSources;

  Future<DatabaseExecutor> _e(DatabaseExecutor? exec) async =>
      exec ?? await _db.database;

  Future<List<MusicSource>> getAll({DatabaseExecutor? exec}) async {
    final rows = await (await _e(exec)).query(_t, orderBy: 'id ASC');
    return rows.map(MusicSource.fromMap).toList();
  }

  Future<MusicSource?> getByUri(String uri, {DatabaseExecutor? exec}) async {
    final rows = await (await _e(
      exec,
    )).query(_t, where: 'uri = ?', whereArgs: [uri]);
    return rows.isEmpty ? null : MusicSource.fromMap(rows.first);
  }

  Future<MusicSource?> getById(int id, {DatabaseExecutor? exec}) async {
    final rows = await (await _e(
      exec,
    )).query(_t, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : MusicSource.fromMap(rows.first);
  }

  Future<int> insert(MusicSource s, {DatabaseExecutor? exec}) async =>
      (await _e(exec)).insert(_t, s.toMap()..remove('id'));

  Future<int> update(MusicSource s, {DatabaseExecutor? exec}) async =>
      (await _e(
        exec,
      )).update(_t, s.toMap(), where: 'id = ?', whereArgs: [s.id]);
}
