import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// Local food log. Uses [LocalDatabase] (same file as user profile + BMI log).
class FoodLogService extends ChangeNotifier {
  FoodLogService._();
  static final FoodLogService instance = FoodLogService._();

  Future<Database> get database => LocalDatabase.instance;

  /// Start of the local calendar day (midnight) for [day].
  static DateTime dateOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static int _startOfLocalDayMs(DateTime day) {
    final start = dateOnly(day);
    return start.millisecondsSinceEpoch;
  }

  static int _endOfLocalDayMs(DateTime day) {
    final n = dateOnly(day);
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

  Future<TodayFoodTotals> todayTotals() => totalsForDay(DateTime.now());

  Future<TodayFoodTotals> totalsForDay(DateTime day) async {
    final db = await database;
    final start = _startOfLocalDayMs(day);
    final end = _endOfLocalDayMs(day);
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

  Future<List<FoodLogEntry>> entriesForDay(DateTime day) async {
    final db = await database;
    final start = _startOfLocalDayMs(day);
    final end = _endOfLocalDayMs(day);
    final rows = await db.query(
      'food_logs',
      where: 'created_at_ms >= ? AND created_at_ms <= ?',
      whereArgs: [start, end],
      orderBy: 'created_at_ms DESC',
    );
    return rows.map(FoodLogEntry.fromRow).toList();
  }

  /// Inclusive of both [from] and [to] local days. Keys are [dateOnly] values.
  Future<Map<DateTime, double>> kcalByDayInRange(DateTime from, DateTime to) async {
    final a = dateOnly(from);
    final b = dateOnly(to);
    if (a.isAfter(b)) return {};
    final db = await database;
    final start = _startOfLocalDayMs(a);
    final end = _endOfLocalDayMs(b);
    final rows = await db.query(
      'food_logs',
      where: 'created_at_ms >= ? AND created_at_ms <= ?',
      whereArgs: [start, end],
    );
    final map = <DateTime, double>{};
    for (final row in rows) {
      final t = row['created_at_ms']! as int;
      final d = dateOnly(DateTime.fromMillisecondsSinceEpoch(t));
      final data = json.decode(row['data_json']! as String) as Map<String, dynamic>;
      final k = (data['calories'] as num?)?.toDouble() ?? 0;
      map[d] = (map[d] ?? 0) + k;
    }
    return map;
  }

  /// Inclusive. Days that have at least one log (for calendar markers).
  Future<Set<DateTime>> daysWithEntriesInRange(DateTime from, DateTime to) async {
    final map = await kcalByDayInRange(from, to);
    return map.keys.toSet();
  }

  /// Consecutive local days ending at [lastDay] with at least one log each.
  /// If [lastDay] is empty, returns 0.
  Future<int> foodLogStreakEndingAt(DateTime lastDay) async {
    var d = dateOnly(lastDay);
    var streak = 0;
    while (true) {
      final t = await totalsForDay(d);
      if (t.entryCount == 0) {
        break;
      }
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Streak of days with logs ending today (0 if you did not log today).
  Future<int> currentFoodStreak() => foodLogStreakEndingAt(DateTime.now());

  /// Number of log rows in the inclusive local-day range.
  Future<int> countEntriesInRange(DateTime from, DateTime to) async {
    final a = dateOnly(from);
    final b = dateOnly(to);
    if (a.isAfter(b)) {
      return 0;
    }
    final db = await database;
    final start = _startOfLocalDayMs(a);
    final end = _endOfLocalDayMs(b);
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM food_logs WHERE created_at_ms >= ? AND created_at_ms <= ?',
      [start, end],
    );
    if (r.isEmpty) {
      return 0;
    }
    return (r.first['c'] as int?) ?? 0;
  }

  /// Last [n] local days of total kcal (oldest first), including days with 0.
  Future<List<DailyKcal>> lastNDaysKcal(int n) async {
    if (n < 1) return [];
    final today = dateOnly(DateTime.now());
    final from = today.subtract(Duration(days: n - 1));
    final map = await kcalByDayInRange(from, today);
    final out = <DailyKcal>[];
    for (var i = 0; i < n; i++) {
      final d = from.add(Duration(days: i));
      out.add(DailyKcal(
        day: d,
        calories: map[d] ?? 0,
      ));
    }
    return out;
  }
}

/// One local calendar day and total kcal (for charts).
class DailyKcal {
  final DateTime day;
  final double calories;

  const DailyKcal({required this.day, required this.calories});
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
