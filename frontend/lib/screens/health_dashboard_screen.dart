import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/health_service.dart';

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
              'Health permissions were denied. Go to Settings > Apps > Health Connect to grant access manually.';
        });
      }
      return;
    }

    await _fetchData();
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

  Future<void> _fetchData() async {
    try {
      final data = await HealthService.fetchTodayData();
      if (mounted) {
        setState(() {
          _steps = data['steps'] as int;
          _activeCalories = data['activeCalories'] as int;
          _sleepMinutes = data['sleepMinutes'] as int;
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
    if (hours == 0 && mins == 0) return '--';
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.x4),
            Text('Dashboard', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.x4),
            if (_loading)
              const LinearProgressIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                minHeight: 2,
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else
              _buildMetricGrid(),
          ],
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
