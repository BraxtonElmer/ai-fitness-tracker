import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const _dbName = 'fitcore_food_log.db';

/// Single SQLite file for food logs, user profile, and BMI log.
class LocalDatabase {
  LocalDatabase._();
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) {
      return _db!;
    }
    final d = await getDatabasesPath();
    final path = p.join(d, _dbName);
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await _v1foodLogs(db);
        await _v2Profile(db);
      },
      onUpgrade: (db, old, newV) async {
        if (old < 2) {
          await _v2Profile(db);
        }
      },
    );
    return _db!;
  }

  static Future<void> _v1foodLogs(Database db) async {
    await db.execute('''
      CREATE TABLE food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at_ms INTEGER NOT NULL,
        data_json TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_food_logs_created ON food_logs(created_at_ms)',
    );
  }

  static Future<void> _v2Profile(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        height_cm REAL,
        weight_kg REAL,
        bmi REAL,
        age INTEGER,
        sex TEXT,
        activity REAL,
        daily_kcal_goal INTEGER,
        suggested_tdee INTEGER,
        updated_at_ms INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE bmi_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at_ms INTEGER NOT NULL,
        height_cm REAL,
        weight_kg REAL,
        bmi REAL,
        goal_kcal_at_save INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_bmi_log_time ON bmi_log(created_at_ms DESC)',
    );
  }
}
