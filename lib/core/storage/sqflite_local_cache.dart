import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_cache.dart';

/// Caché del último estado conocido en SQLite.
///
/// Tabla clave-valor con marca de tiempo para identificar datos
/// desactualizados. Se borra por completo al cerrar sesión.
class SqfliteLocalCache implements LocalCache {
  SqfliteLocalCache._(this._db);

  final Database _db;
  static const _table = 'cache_entries';

  static Future<SqfliteLocalCache> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      '$dir/safecore_cache.db',
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE $_table (key TEXT PRIMARY KEY, value TEXT NOT NULL, saved_at INTEGER NOT NULL)',
      ),
    );
    return SqfliteLocalCache._(db);
  }

  @override
  Future<CacheEntry?> read(String key) async {
    final rows = await _db.query(
      _table,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final value = row['value'];
    final savedAt = row['saved_at'];
    if (value is! String || savedAt is! int) return null;
    try {
      return CacheEntry(
        value: jsonDecode(value),
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      );
    } on FormatException {
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? jsonValue) => _db.insert(
        _table,
        {
          'key': key,
          'value': jsonEncode(jsonValue),
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> remove(String key) =>
      _db.delete(_table, where: 'key = ?', whereArgs: [key]);

  @override
  Future<void> clear() => _db.delete(_table);
}
