import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  static final Health _health = Health();

  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static final List<HealthDataAccess> _permissions =
      _types.map((_) => HealthDataAccess.READ).toList();

  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
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

  static Future<Map<String, dynamic>> fetchTodayData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // Steps
      int steps = 0;
      try {
        final stepsCount = await _health.getTotalStepsInInterval(
          midnight,
          now,
        );
        steps = stepsCount ?? 0;
      } catch (_) {
        steps = 0;
      }

      // Active calories
      double activeCalories = 0;
      try {
        final calorieData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: midnight,
          endTime: now,
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

      // Sleep — look at last night (yesterday 8pm to today 12pm)
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
        'activeCalories': activeCalories.round(),
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
