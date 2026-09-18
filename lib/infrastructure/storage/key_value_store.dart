import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// Contract for lightweight persistent key-value storage.
abstract class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  Future<void> remove(String key);
  Future<void> clear();
}

/// SQLite-backed implementation of [KeyValueStore] using the key_value_store table.
class SqliteKeyValueStore implements KeyValueStore {
  final AppDatabase _appDatabase;

  const SqliteKeyValueStore(this._appDatabase);

  Database get _db => _appDatabase.database;

  @override
  Future<String?> getString(String key) async {
    final rows = await _db.query(
      'key_value_store',
      columns: ['value_text'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value_text'] as String?;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _db.insert(
      'key_value_store',
      {
        'key': key,
        'value_text': value,
        'value_type': 'string',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<bool?> getBool(String key) async {
    final intVal = await getInt(key);
    if (intVal == null) return null;
    return intVal == 1;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await setInt(key, value ? 1 : 0);
  }

  @override
  Future<int?> getInt(String key) async {
    final rows = await _db.query(
      'key_value_store',
      columns: ['value_int'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value_int'] as int?;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _db.insert(
      'key_value_store',
      {
        'key': key,
        'value_int': value,
        'value_type': 'int',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<double?> getDouble(String key) async {
    final rows = await _db.query(
      'key_value_store',
      columns: ['value_real'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value_real'] as double?;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _db.insert(
      'key_value_store',
      {
        'key': key,
        'value_real': value,
        'value_type': 'double',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remove(String key) async {
    await _db.delete(
      'key_value_store',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> clear() async {
    await _db.delete('key_value_store');
  }
}
