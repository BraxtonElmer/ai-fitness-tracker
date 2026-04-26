import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class DailyActivity {
  final DateTime day;
  final int steps;
  final int activeCalories;

  const DailyActivity({
    required this.day,
    required this.steps,
    required this.activeCalories,
  });
}

class HealthService {
  static final Health _health = Health();

  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static final List<HealthDataAccess> _permissions =
      _types.map((_) => HealthDataAccess.READ).toList();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      await _health.configure();
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return granted;
    } catch (e) {
      debugPrint('Health permission error: $e');
      return false;
    }
  }

  /// Steps and active kcal for one local [day]. End of range is "now" if [day] is today, else end of that day.
  static Future<DailyActivity> fetchActivityForLocalDay(DateTime day) async {
    final d = _dateOnly(day);
    final now = DateTime.now();
    final end = _isSameLocalDay(d, now)
        ? now
        : DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
    return _activityBetween(d, end);
  }

  static Future<List<DailyActivity>> lastNDaysActivity(int n) async {
    if (n < 1) {
      return [];
    }
    if (!Platform.isAndroid) {
      return [];
    }
    try {
      await _health.configure();
    } catch (_) {
      // continue; queries may still work
    }
    final out = <DailyActivity>[];
    for (var i = n - 1; i >= 0; i--) {
      final ref = DateTime.now().subtract(Duration(days: i));
      final act = await fetchActivityForLocalDay(ref);
      out.add(
        DailyActivity(
          day: _dateOnly(ref),
          steps: act.steps,
          activeCalories: act.activeCalories,
        ),
      );
    }
    return out;
  }

  static Future<DailyActivity> _activityBetween(
    DateTime start,
    DateTime end,
  ) async {
    var steps = 0;
    try {
      final stepsCount = await _health.getTotalStepsInInterval(start, end);
      steps = stepsCount ?? 0;
    } catch (_) {
      steps = 0;
    }

    double activeCalories = 0;
    try {
      final calorieData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      for (final dp in calorieData) {
        final val = dp.value;
        if (val is NumericHealthValue) {
          activeCalories += val.numericValue.toDouble();
        }
      }
    } catch (_) {
      activeCalories = 0;
    }

    return DailyActivity(
      day: start,
      steps: steps,
      activeCalories: activeCalories.round(),
    );
  }

  static Future<Map<String, dynamic>> fetchTodayData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      final part = await _activityBetween(midnight, now);
      int steps = part.steps;
      int activeCal = part.activeCalories;

      double sleepMinutes = 0;
      try {
        final lastNightStart = midnight.subtract(const Duration(hours: 4));
        final lastNightEnd = midnight.add(const Duration(hours: 12));
        final sleepData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_ASLEEP],
          startTime: lastNightStart,
          endTime: lastNightEnd,
        );
        for (final dp in sleepData) {
          final duration = dp.dateTo.difference(dp.dateFrom).inMinutes;
          sleepMinutes += duration;
        }
      } catch (_) {
        sleepMinutes = 0;
      }

      return {
        'steps': steps,
        'activeCalories': activeCal,
        'sleepMinutes': sleepMinutes.round(),
      };
    } catch (e) {
      debugPrint('Health fetch error: $e');
      return {
        'steps': 0,
        'activeCalories': 0,
        'sleepMinutes': 0,
      };
    }
  }
}
