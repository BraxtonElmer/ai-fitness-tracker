import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../services/health_service.dart';
import '../services/food_log_service.dart';
import '../services/user_profile_service.dart';
import 'bmi_screen.dart';
import 'food_scan_screen.dart';
import 'food_search_screen.dart';
import 'meal_log_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _steps = 0;
  int _activeCalories = 0;
  int _foodKcal = 0;
  int? _goalKcal;
  bool _loading = true;
  final FoodLogService _foodLog = FoodLogService.instance;
  final UserProfileService _profile = UserProfileService.instance;

  @override
  void initState() {
    super.initState();
    _foodLog.addListener(_onFoodLog);
    _profile.addListener(_onProfile);
    _loadFoodToday();
    _loadGoal();
    _loadHealthData();
  }

  @override
  void dispose() {
    _foodLog.removeListener(_onFoodLog);
    _profile.removeListener(_onProfile);
    super.dispose();
  }

  void _onProfile() {
    _loadGoal();
  }

  void _onFoodLog() {
    _loadFoodToday();
  }

  Future<void> _loadGoal() async {
    final g = await _profile.getProfile();
    if (mounted) {
      setState(() {
        _goalKcal = g.dailyKcalGoal;
      });
    }
  }

  Future<void> _loadFoodToday() async {
    final t = await _foodLog.todayTotals();
    if (mounted) {
      setState(() {
        _foodKcal = t.calories.round();
      });
    }
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

  void _openManualAdd() {
    final empty = <String, dynamic>{
      'dish_name': '',
      'serving_size': '1 serving',
      'calories': 0,
      'confidence': 'medium',
      'health_note': '',
      'meal_type': 'lunch',
      'macros': {
        'protein_g': 0.0,
        'carbs_g': 0.0,
        'fats_g': 0.0,
        'fiber_g': 0.0,
      },
      'micros': {
        'iron_mg': 0.0,
        'calcium_mg': 0.0,
        'vitamin_c_mg': 0.0,
        'vitamin_b12_mcg': 0.0,
        'sodium_mg': 0.0,
      },
    };
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (c, a, s) => MealLogEditorScreen(
          initialNutrition: empty,
          source: FoodEntrySource.manual,
        ),
        transitionsBuilder: (c, a, s, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Hello there',
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (c, a, s) => const Scaffold(
                              body: FoodScanScreen(),
                            ),
                            transitionsBuilder: (c, a, s, child) {
                              return FadeTransition(
                                opacity: a,
                                child: child,
                              );
                            },
                          ),
                        );
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
                  const SizedBox(height: AppSpacing.x2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (c, a, s) =>
                                    const FoodSearchScreen(),
                                transitionsBuilder: (c, a, s, child) =>
                                    FadeTransition(
                                  opacity: a,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderRadius,
                            ),
                          ),
                          icon: const Icon(LucideIcons.search, size: 18),
                          label: Text(
                            'Search',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (c, a, s) => const BmiScreen(),
                                transitionsBuilder: (c, a, s, child) =>
                                    FadeTransition(
                                  opacity: a,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderRadius,
                            ),
                          ),
                          icon: const Icon(LucideIcons.ruler, size: 18),
                          label: Text(
                            'BMI & goal',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openManualAdd,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadius,
                        ),
                      ),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(
                        'Add food manually',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  if (!_loading) _buildGoalTrack(),
                  const SizedBox(height: AppSpacing.x2),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTrack() {
    final g = _goalKcal;
    if (g == null || g <= 0) {
      return OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (c, a, s) => const BmiScreen(),
              transitionsBuilder: (c, a, s, child) =>
                  FadeTransition(opacity: a, child: child),
            ),
          ).then((_) => _loadGoal());
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.all(AppSpacing.x2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadius,
          ),
        ),
        icon: const Icon(LucideIcons.target, size: 20),
        label: Text(
          'Set daily kcal limit (BMI) to track eaten vs cap',
          style: AppTextStyles.label.copyWith(color: AppColors.accent),
          textAlign: TextAlign.start,
        ),
      );
    }
    final over = _foodKcal > g;
    final left = (g - _foodKcal).clamp(-99999, 99999);
    final p = (g == 0) ? 0.0 : (_foodKcal / g).clamp(0.0, 1.5);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        border: Border.all(
          color: over ? AppColors.error : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Today vs your limit',
            style: AppTextStyles.label.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_foodKcal / $g kcal',
                style: AppTextStyles.headingSmall,
              ),
              Text(
                over
                    ? 'Over by ${(_foodKcal - g)} kcal'
                    : '$left kcal left',
                style: AppTextStyles.label.copyWith(
                  color: over ? AppColors.error : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p > 1.0 ? 1.0 : p,
              minHeight: 6,
              color: over ? AppColors.error : AppColors.accent,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
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
            Expanded(
              child: _buildStatPair('Food (kcal)', '$_foodKcal'),
            ),
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
