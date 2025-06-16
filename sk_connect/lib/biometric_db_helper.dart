// lib/biometric_db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BiometricDBHelper {
  static Database? _db;

  /// Opens (or creates) the database at ‘biometric_settings.db’ and
  /// ensures a table named `settings` exists with one row.
  static Future<Database> _getDB() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biometric_settings.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create a single-row table with 'biometric_enabled' flag.
        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            biometric_enabled INTEGER
          )
        ''');
        // Insert the initial row with biometric_enabled = 0 (false).
        await db.insert('settings', {'id': 1, 'biometric_enabled': 0});
      },
    );

    return _db!;
  }

  /// Returns true if the user has enabled biometrics (1), false otherwise (0 or no row).
  static Future<bool> isBiometricEnabled() async {
    final db = await _getDB();
    final result = await db.query(
      'settings',
      columns: ['biometric_enabled'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) return false;
    return (result.first['biometric_enabled'] as int) == 1;
  }

  /// Sets biometric_enabled to 1 or 0.
  static Future<void> setBiometricEnabled(bool enabled) async {
    final db = await _getDB();
    await db.update(
      'settings',
      {'biometric_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
