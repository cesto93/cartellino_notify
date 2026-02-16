/// Port of database.py — SQLite persistence layer.
///
/// Stores global settings, daily user settings (start_time, leisure_time),
/// and provides the same API surface as the Python original.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const String _dbName = 'cartellino.db';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    late final String path;

    if (kIsWeb) {
      path = _dbName;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/$_dbName';
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS user_settings '
          '(key TEXT, value TEXT, date TEXT, PRIMARY KEY (key, date))',
        );

        // Insert defaults
        await db.insert('settings', {'key': 'work_time', 'value': '07:12'},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        await db.insert('settings', {'key': 'lunch_time', 'value': '00:30'},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      },
    );
  }

  // ── Global settings ──────────────────────────────────────────────────────

  Future<void> storeSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  // ── Daily user settings ──────────────────────────────────────────────────

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> storeStartTime(String startTime) async {
    await storeDailySetting('start_time', startTime);
  }

  Future<String?> getStartTime() async {
    return getDailySetting('start_time');
  }

  Future<void> storeDailySetting(String key, String value) async {
    final db = await database;
    final today = _today();
    await db.insert(
      'user_settings',
      {'key': key, 'value': value, 'date': today},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getDailySetting(String key) async {
    final db = await database;
    final today = _today();
    final rows = await db.query(
      'user_settings',
      where: 'key = ? AND date = ?',
      whereArgs: [key, today],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> clearDailySetting(String key) async {
    final db = await database;
    final today = _today();
    await db.delete(
      'user_settings',
      where: 'key = ? AND date = ?',
      whereArgs: [key, today],
    );
  }
}
