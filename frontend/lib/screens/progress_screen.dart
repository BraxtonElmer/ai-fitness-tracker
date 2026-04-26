import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../services/food_log_service.dart';
import '../services/user_profile_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _food = FoodLogService.instance;
  final _profile = UserProfileService.instance;

  int _rangeDays = 7;
  bool _loading = true;
  int? _goalKcal;
  int _streak = 0;
  List<DailyKcal> _series = [];
  double _weekAvg = 0;
  int _mealsInRange = 0;
  int _daysUnder = 0;
  int _daysOver = 0;
  List<BmiLogEntry> _bmiRows = [];
  int _bmiError = 0;

  @override
  void initState() {
    super.initState();
    _food.addListener(_reload);
    _load();
  }

  @override
  void dispose() {
    _food.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _bmiError = 0;
    });
    try {
      final p = await _profile.getProfile();
      _goalKcal = p.dailyKcalGoal;
      final series = await _food.lastNDaysKcal(_rangeDays);
      final streak = await _food.currentFoodStreak();
      final from = series.first.day;
      final to = series.last.day;
      final meals = await _food.countEntriesInRange(from, to);
      var under = 0;
      var over = 0;
      final g = _goalKcal;
      for (final d in series) {
        if (d.calories <= 0) {
          continue;
        }
        if (g != null && g > 0) {
          if (d.calories > g) {
            over++;
          } else {
            under++;
          }
        }
      }
      final totalK = series.fold<double>(0, (a, b) => a + b.calories);
      final avg = series.isEmpty ? 0.0 : totalK / series.length;
      List<BmiLogEntry> bmi = [];
      try {
        bmi = await _profile.bmiHistory(limit: 60);
        bmi.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
      } catch (_) {
        bmi = [];
        if (mounted) {
          setState(() => _bmiError = 1);
        }
      }
      if (mounted) {
        setState(() {
          _streak = streak;
          _series = series;
          _weekAvg = avg;
          _mealsInRange = meals;
          _daysUnder = under;
          _daysOver = over;
          _bmiRows = bmi;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Progress', style: AppTextStyles.headingSmall),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.x2),
                children: [
                  _buildRangeToggle(),
                  const SizedBox(height: AppSpacing.x2),
                  _buildStreakCard(),
                  const SizedBox(height: AppSpacing.x2),
                  _buildWeekSummary(),
                  const SizedBox(height: AppSpacing.x2),
                  Text('Calories', style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.x1),
                  SizedBox(
                    height: 200,
                    child: _kcalChart(),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text('Weight (from BMI saves)', style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.x1),
                  if (_bmiRows.length < 2)
                    Text(
                      _bmiError != 0
                          ? 'Could not load body history'
                          : 'Log weight from BMI & goal at least twice to see a line.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: _weightChart(),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRangeToggle() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7 d')),
        ButtonSegment(value: 30, label: Text('30 d')),
      ],
      selected: {_rangeDays},
      onSelectionChanged: (s) {
        setState(() => _rangeDays = s.first);
        _load();
      },
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flame, color: AppColors.accent, size: 28),
          const SizedBox(width: AppSpacing.x2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log streak', style: AppTextStyles.bodySmall),
              Text(
                '$_streak day${_streak == 1 ? '' : 's'} in a row',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSummary() {
    final g = _goalKcal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _rangeDays == 7 ? 'This week' : 'Last 30 days',
            style: AppTextStyles.label.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryStat(
                'Avg kcal / day',
                _weekAvg.round().toString(),
              ),
              _summaryStat('Meals logged', '$_mealsInRange'),
            ],
          ),
          if (g != null && g > 0) ...[
            const SizedBox(height: AppSpacing.x2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryStat('Days on target', '$_daysUnder'),
                _summaryStat('Days over $g', '$_daysOver'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.headingSmall),
      ],
    );
  }

  Widget _kcalChart() {
    if (_series.isEmpty) {
      return Center(
        child: Text('No data yet', style: AppTextStyles.body),
      );
    }
    final maxK = _series
        .map((e) => e.calories)
        .reduce((a, b) => a > b ? a : b);
    final g = _goalKcal?.toDouble() ?? 0.0;
    var top = (maxK > g ? maxK : g) * 1.15;
    if (top < 1) {
      top = 2000;
    }

    return BarChart(
      BarChartData(
        maxY: top,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) {
            return FlLine(color: AppColors.border, strokeWidth: 0.5);
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) {
                if (v % 500 != 0 && v != 0) {
                  return const SizedBox();
                }
                return Text(
                  v.round().toString(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedText, fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, m) {
                final idx = i.toInt();
                if (idx < 0 || idx >= _series.length) {
                  return const SizedBox();
                }
                final d = _series[idx].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _rangeDays == 7
                        ? DateFormat.E().format(d)
                        : '${d.month}/${d.day}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < _series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _series[i].calories,
                  color: _rodColor(_series[i].calories, g),
                  width: _rangeDays == 7 ? 14 : 5,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
        extraLinesData: g > 0
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: g,
                    color: AppColors.accent.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 9,
                      ),
                      labelResolver: (_) => 'Goal $g',
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Color _rodColor(double k, double goal) {
    if (goal <= 0) {
      return AppColors.proteinColor;
    }
    if (k > goal) {
      return AppColors.error.withValues(alpha: 0.85);
    }
    return AppColors.accent.withValues(alpha: 0.75);
  }

  Widget _weightChart() {
    final rows = _bmiRows;
    if (rows.length < 2) {
      return const SizedBox();
    }
    var minW = rows.first.weightKg;
    var maxW = rows.first.weightKg;
    for (final e in rows) {
      if (e.weightKg < minW) {
        minW = e.weightKg;
      }
      if (e.weightKg > maxW) {
        maxW = e.weightKg;
      }
    }
    var pad = (maxW - minW) * 0.15;
    if (pad < 0.5) {
      pad = 0.5;
    }
    final minY = minW - pad;
    final maxY = maxW + pad;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) {
            return FlLine(color: AppColors.border, strokeWidth: 0.5);
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, m) {
                return Text(
                  v.toStringAsFixed(0),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedText, fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) {
                  return const SizedBox();
                }
                final t = DateTime.fromMillisecondsSinceEpoch(
                  rows[i].createdAtMs,
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.Md().format(t),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 8,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < rows.length; i++)
                FlSpot(i.toDouble(), rows[i].weightKg),
            ],
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
