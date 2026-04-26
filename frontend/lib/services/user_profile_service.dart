import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

class UserProfile {
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final int? age;
  final String? sex; // M / F
  final double? activity;
  final int? dailyKcalGoal;
  final int? suggestedTdee;
  final int? updatedAtMs;

  const UserProfile({
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.age,
    this.sex,
    this.activity,
    this.dailyKcalGoal,
    this.suggestedTdee,
    this.updatedAtMs,
  });

  bool get hasGoal => dailyKcalGoal != null && dailyKcalGoal! > 0;

  factory UserProfile.fromRow(Map<String, Object?>? r) {
    if (r == null || r.isEmpty) {
      return const UserProfile();
    }
    return UserProfile(
      heightCm: r['height_cm'] as double?,
      weightKg: r['weight_kg'] as double?,
      bmi: r['bmi'] as double?,
      age: r['age'] as int?,
      sex: r['sex'] as String?,
      activity: (r['activity'] as num?)?.toDouble(),
      dailyKcalGoal: r['daily_kcal_goal'] as int?,
      suggestedTdee: r['suggested_tdee'] as int?,
      updatedAtMs: r['updated_at_ms'] as int?,
    );
  }
}

class BmiLogEntry {
  final int id;
  final int createdAtMs;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final int? goalKcal;

  BmiLogEntry({
    required this.id,
    required this.createdAtMs,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    this.goalKcal,
  });

  factory BmiLogEntry.fromRow(Map<String, Object?> r) {
    return BmiLogEntry(
      id: r['id']! as int,
      createdAtMs: r['created_at_ms']! as int,
      heightCm: (r['height_cm'] as num).toDouble(),
      weightKg: (r['weight_kg'] as num).toDouble(),
      bmi: (r['bmi'] as num).toDouble(),
      goalKcal: r['goal_kcal_at_save'] as int?,
    );
  }
}

class UserProfileService extends ChangeNotifier {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  Future<Database> get _db => LocalDatabase.instance;

  Future<UserProfile> getProfile() async {
    final db = await _db;
    final rows = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      return const UserProfile();
    }
    return UserProfile.fromRow(rows.first);
  }

  Future<int?> getDailyKcalGoal() async {
    final p = await getProfile();
    return p.dailyKcalGoal;
  }

  Future<void> saveProfileAndLogBmi({
    required double heightCm,
    required double weightKg,
    required double bmi,
    required int? age,
    required String? sex,
    required double activityFactor,
    required int? suggestedTdee,
    required int dailyKcalGoal,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'user_profile',
      {
        'id': 1,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'age': age,
        'sex': sex,
        'activity': activityFactor,
        'daily_kcal_goal': dailyKcalGoal,
        'suggested_tdee': suggestedTdee,
        'updated_at_ms': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert('bmi_log', {
      'created_at_ms': now,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'goal_kcal_at_save': dailyKcalGoal,
    });
    notifyListeners();
  }

  Future<List<BmiLogEntry>> bmiHistory({int limit = 30}) async {
    final db = await _db;
    final rows = await db.query(
      'bmi_log',
      orderBy: 'created_at_ms DESC',
      limit: limit,
    );
    return rows.map(BmiLogEntry.fromRow).toList();
  }
}
