import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/health_service.dart';
import 'food_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _steps = 0;
  int _activeCalories = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final available = await HealthService.isAvailable();
      if (!available) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final granted = await HealthService.requestPermissions();
      if (!granted) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final data = await HealthService.fetchTodayData();
      if (mounted) {
        setState(() {
          _steps = data['steps'] as int;
          _activeCalories = data['activeCalories'] as int;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
            Text(
              'Hello there',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: AppSpacing.x6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to scan tab — find the AppShell state and switch
                  final shellState =
                      context.findAncestorStateOfType<State>();
                  if (shellState != null && shellState.mounted) {
                    // Use a callback to navigate
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const Scaffold(
                          body: FoodScanScreen(),
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadius,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'SCAN FOOD',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            if (_loading)
              const LinearProgressIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                minHeight: 2,
              )
            else
              _buildSummaryRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.x2,
        horizontal: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildStatPair('Calories', '--')),
            const VerticalDivider(
              color: AppColors.border,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _buildStatPair('Steps', '$_steps'),
            ),
            const VerticalDivider(
              color: AppColors.border,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _buildStatPair('Active Cal', '$_activeCalories'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPair(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          value,
          style: AppTextStyles.headingSmall,
        ),
      ],
    );
  }
}
