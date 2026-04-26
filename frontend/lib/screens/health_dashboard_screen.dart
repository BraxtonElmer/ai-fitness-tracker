import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../services/health_service.dart';
import 'settings_screen.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  bool _loading = true;
  String? _errorMessage;

  int _steps = 0;
  int _activeCalories = 0;
  int _sleepMinutes = 0;
  List<DailyActivity> _week = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await HealthService.isAvailable();
    if (!available) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Health Connect is required and is available on Android 9 and above.';
        });
      }
      return;
    }

    if (mounted) {
      await _showPermissionDialog();
    }

    final granted = await HealthService.requestPermissions();
    if (!granted) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Health permissions were denied. Use Settings below to open Health Connect.';
        });
      }
      return;
    }

    await _loadAll();
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadius,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Health Data Access',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'FitCore AI needs access to Health Connect to display your step count, active calories, and sleep data. No data is stored or shared.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CONTINUE',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final data = await HealthService.fetchTodayData();
      final week = await HealthService.lastNDaysActivity(7);
      if (mounted) {
        setState(() {
          _steps = data['steps'] as int;
          _activeCalories = data['activeCalories'] as int;
          _sleepMinutes = data['sleepMinutes'] as int;
          _week = week;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Could not load health data.';
        });
      }
    }
  }

  String _formatSleep(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0 && mins == 0) {
      return '--';
    }
    if (hours == 0) {
      return '${mins}m';
    }
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Activity', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (c) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(LucideIcons.settings, color: AppColors.mutedText),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            if (_errorMessage != null &&
                _errorMessage!.contains('permissions were denied')) {
              final g = await HealthService.requestPermissions();
              if (g) {
                await _loadAll();
              }
              return;
            }
            if (await HealthService.isAvailable()) {
              await _loadAll();
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x2),
            children: [
              if (_loading)
                const LinearProgressIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  minHeight: 2,
                )
              else if (_errorMessage != null) ...[
                _buildErrorState(),
                const SizedBox(height: AppSpacing.x2),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (c) => const SettingsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(LucideIcons.settings, size: 18),
                  label: Text(
                    'Open settings',
                    style: AppTextStyles.label.copyWith(color: AppColors.accent),
                  ),
                ),
              ] else ...[
                _buildMetricGrid(),
                if (_week.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Last 7 days — steps',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SizedBox(height: 160, child: _buildStepsChart()),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Last 7 days — active kcal',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SizedBox(height: 160, child: _buildActiveChart()),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        _errorMessage!,
        style: AppTextStyles.body.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildMetricGrid() {
    return Column(
      children: [
        Text(
          'Today',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: AppSpacing.x2),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '$_steps',
                label: 'Steps',
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: _MetricTile(
                value: _formatSleep(_sleepMinutes),
                label: 'Sleep',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        _MetricTile(
          value: '$_activeCalories',
          label: 'Active Calories',
        ),
      ],
    );
  }

  double _maxStepY() {
    if (_week.isEmpty) {
      return 1000;
    }
    final m = _week.map((e) => e.steps).reduce((a, b) => a > b ? a : b);
    return (m * 1.15).clamp(1000, 1e7);
  }

  double _maxActiveY() {
    if (_week.isEmpty) {
      return 500;
    }
    final m = _week.map((e) => e.activeCalories).reduce((a, b) => a > b ? a : b);
    return (m * 1.2 + 1).clamp(200, 1e6);
  }

  Widget _buildStepsChart() {
    final maxY = _maxStepY();
    return BarChart(
      BarChartData(
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
              reservedSize: 32,
              getTitlesWidget: (v, m) {
                if (v < 0) {
                  return const SizedBox();
                }
                return Text(
                  v.round().toString(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedText, fontSize: 8),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, m) {
                final idx = i.toInt();
                if (idx < 0 || idx >= _week.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.E().format(_week[idx].day),
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
          for (var i = 0; i < _week.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _week[i].steps.toDouble(),
                  color: AppColors.accent,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActiveChart() {
    final maxY = _maxActiveY();
    return BarChart(
      BarChartData(
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
              reservedSize: 28,
              getTitlesWidget: (v, m) {
                return Text(
                  v.round().toString(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedText, fontSize: 8),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, m) {
                final idx = i.toInt();
                if (idx < 0 || idx >= _week.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.Md().format(_week[idx].day),
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
        barGroups: [
          for (var i = 0; i < _week.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _week[i].activeCalories.toDouble(),
                  color: AppColors.proteinColor,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;

  const _MetricTile({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.headingLarge,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
