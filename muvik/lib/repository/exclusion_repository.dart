import 'package:sqflite/sqflite.dart';

import '../models/data_models/excluded_item.dart';
import '../services/storage/database_helper.dart';
import '../services/storage/schema.dart';

class ExclusionRepository {
  final DatabaseHelper _db = DatabaseHelper();
  static const String _t = DbSchema.tableExcluded;

  Future<DatabaseExecutor> _e(DatabaseExecutor? exec) async =>
      exec ?? await _db.database;

  Future<List<ExcludedItem>> getAll({DatabaseExecutor? exec}) async {
    final rows = await (await _e(exec)).query(_t);
    return rows.map(ExcludedItem.fromMap).toList();
  }

  Future<int> insert(ExcludedItem item, {DatabaseExecutor? exec}) async =>
      (await _e(exec)).insert(
        _t,
        item.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  Future<int> delete(
    ExcludedType type,
    String identity, {
    DatabaseExecutor? exec,
  }) async => (await _e(exec)).delete(
    _t,
    where: 'type = ? AND identity = ?',
    whereArgs: [type.key, identity],
  );
}
