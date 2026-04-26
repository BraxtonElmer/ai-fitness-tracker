import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// Local food log. Uses [LocalDatabase] (same file as user profile + BMI log).
class FoodLogService extends ChangeNotifier {
  FoodLogService._();
  static final FoodLogService instance = FoodLogService._();

  Future<Database> get database => LocalDatabase.instance;

  static int _startOfLocalDayMs([DateTime? ref]) {
    final n = ref ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day);
    return start.millisecondsSinceEpoch;
  }

  static int _endOfLocalDayMs([DateTime? ref]) {
    final n = ref ?? DateTime.now();
    final end = DateTime(n.year, n.month, n.day, 23, 59, 59, 999);
    return end.millisecondsSinceEpoch;
  }

  /// Insert a successful nutrition result from the AI.
  Future<int> insertEntry(Map<String, dynamic> nutritionData) async {
    final db = await database;
    final id = await db.insert('food_logs', {
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      'data_json': json.encode(nutritionData),
    });
    notifyListeners();
    return id;
  }

  Future<List<FoodLogEntry>> allEntries({int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'food_logs',
      orderBy: 'created_at_ms DESC',
      limit: limit,
    );
    return rows.map(FoodLogEntry.fromRow).toList();
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<TodayFoodTotals> todayTotals() async {
    final db = await database;
    final start = _startOfLocalDayMs();
    final end = _endOfLocalDayMs();
    final rows = await db.query(
      'food_logs',
      where: 'created_at_ms >= ? AND created_at_ms <= ?',
      whereArgs: [start, end],
    );
    var kcal = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fats = 0.0;
    for (final row in rows) {
      final data = json.decode(row['data_json']! as String) as Map<String, dynamic>;
      kcal += (data['calories'] as num?)?.toDouble() ?? 0;
      final m = data['macros'] as Map<String, dynamic>? ?? {};
      protein += (m['protein_g'] as num?)?.toDouble() ?? 0;
      carbs += (m['carbs_g'] as num?)?.toDouble() ?? 0;
      fats += (m['fats_g'] as num?)?.toDouble() ?? 0;
    }
    return TodayFoodTotals(
      entryCount: rows.length,
      calories: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatsG: fats,
    );
  }
}

class TodayFoodTotals {
  final int entryCount;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatsG;

  const TodayFoodTotals({
    this.entryCount = 0,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatsG = 0,
  });
}

class FoodLogEntry {
  final int id;
  final int createdAtMs;
  final Map<String, dynamic> nutritionData;

  FoodLogEntry({
    required this.id,
    required this.createdAtMs,
    required this.nutritionData,
  });

  factory FoodLogEntry.fromRow(Map<String, Object?> row) {
    return FoodLogEntry(
      id: row['id']! as int,
      createdAtMs: row['created_at_ms']! as int,
      nutritionData: json.decode(row['data_json']! as String) as Map<String, dynamic>,
    );
  }

  String get dishName => nutritionData['dish_name'] as String? ?? 'Meal';
  double get calories => (nutritionData['calories'] as num?)?.toDouble() ?? 0;

  String get mealTypeId => nutritionData['meal_type'] as String? ?? 'lunch';

  String get mealTypeLabel {
    switch (mealTypeId) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return mealTypeId;
    }
  }
}
