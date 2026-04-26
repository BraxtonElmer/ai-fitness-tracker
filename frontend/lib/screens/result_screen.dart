import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> nutritionData;
  final bool showBack;
  final bool showAddToLog;
  final VoidCallback? onAddToLog;

  const ResultScreen({
    super.key,
    required this.nutritionData,
    this.showBack = false,
    this.showAddToLog = true,
    this.onAddToLog,
  });

  // RDA values (adult male)
  static const Map<String, double> _rda = {
    'iron_mg': 8,
    'calcium_mg': 1000,
    'vitamin_c_mg': 90,
    'vitamin_b12_mcg': 2.4,
    'sodium_mg': 2300,
  };

  static const Map<String, String> _microLabels = {
    'iron_mg': 'Iron',
    'calcium_mg': 'Calcium',
    'vitamin_c_mg': 'Vitamin C',
    'vitamin_b12_mcg': 'Vitamin B12',
    'sodium_mg': 'Sodium',
  };

  static const Map<String, String> _microUnits = {
    'iron_mg': 'mg',
    'calcium_mg': 'mg',
    'vitamin_c_mg': 'mg',
    'vitamin_b12_mcg': 'mcg',
    'sodium_mg': 'mg',
  };

  @override
  Widget build(BuildContext context) {
    final dishName = nutritionData['dish_name'] as String? ?? 'Unknown';
    final confidence = nutritionData['confidence'] as String? ?? 'low';
    final servingSize =
        nutritionData['serving_size'] as String? ?? 'Unknown';
    final calories = (nutritionData['calories'] as num?)?.toDouble() ?? 0;
    final macros =
        nutritionData['macros'] as Map<String, dynamic>? ?? {};
    final micros =
        nutritionData['micros'] as Map<String, dynamic>? ?? {};
    final healthNote =
        nutritionData['health_note'] as String? ?? '';

    final protein = (macros['protein_g'] as num?)?.toDouble() ?? 0;
    final carbs = (macros['carbs_g'] as num?)?.toDouble() ?? 0;
    final fats = (macros['fats_g'] as num?)?.toDouble() ?? 0;
    final fiber = (macros['fiber_g'] as num?)?.toDouble() ?? 0;
    final macroTotal = protein + carbs + fats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.x1,
                    bottom: AppSpacing.x1,
                  ),
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x2),
                    // Dish name
                    Text(dishName, style: AppTextStyles.headingLarge),
                    const SizedBox(height: AppSpacing.x1),
                    // Confidence badge
                    _ConfidenceBadge(level: confidence),
                    const SizedBox(height: AppSpacing.x1),
                    // Serving size
                    Text(
                      servingSize,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    // Calories
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${calories.round()}',
                          style: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w600,
                            fontSize: 48,
                            color: AppColors.primaryText,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x1),
                        Text(
                          'kcal',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    // Macro bar chart
                    if (macroTotal > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 6,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (protein / macroTotal * 100).round(),
                                child: Container(
                                    color: AppColors.proteinColor),
                              ),
                              Expanded(
                                flex: (carbs / macroTotal * 100).round(),
                                child:
                                    Container(color: AppColors.carbsColor),
                              ),
                              Expanded(
                                flex: (fats / macroTotal * 100).round(),
                                child:
                                    Container(color: AppColors.fatsColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                    ],
                    // Macro rows
                    _MacroRow(
                      name: 'Protein',
                      grams: protein,
                      color: AppColors.proteinColor,
                      maxGrams: macroTotal,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _MacroRow(
                      name: 'Carbs',
                      grams: carbs,
                      color: AppColors.carbsColor,
                      maxGrams: macroTotal,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _MacroRow(
                      name: 'Fats',
                      grams: fats,
                      color: AppColors.fatsColor,
                      maxGrams: macroTotal,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _MacroRow(
                      name: 'Fiber',
                      grams: fiber,
                      color: AppColors.secondaryText,
                      maxGrams: macroTotal,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    // Divider
                    const Divider(),
                    const SizedBox(height: AppSpacing.x3),
                    // Micronutrients table
                    Text(
                      'Micronutrients',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    ..._buildMicroRows(micros),
                    const SizedBox(height: AppSpacing.x4),
                    // Health note
                    if (healthNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.x2),
                        child: Text(
                          healthNote,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showAddToLog && onAddToLog != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onAddToLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderRadius,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ADD TO LOG',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(
                            color: AppColors.accent, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        showBack ? 'CLOSE' : 'SCAN ANOTHER',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMicroRows(Map<String, dynamic> micros) {
    final entries = _microLabels.entries.toList();
    final rows = <Widget>[];

    for (int i = 0; i < entries.length; i++) {
      final key = entries[i].key;
      final label = entries[i].value;
      final unit = _microUnits[key] ?? '';
      final value = (micros[key] as num?)?.toDouble() ?? 0;
      final rda = _rda[key] ?? 1;
      final rdaPercent = ((value / rda) * 100).round().clamp(0, 999);
      final isEven = i % 2 == 0;

      rows.add(
        Container(
          color: isEven ? AppColors.background : AppColors.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x1 + 4,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: AppTextStyles.body,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$rdaPercent%',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String level;

  const _ConfidenceBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (level.toLowerCase()) {
      case 'high':
        badgeColor = AppColors.success;
        break;
      case 'medium':
        badgeColor = const Color(0xFFE6B800);
        break;
      default:
        badgeColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1 + 4,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadius,
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        level.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String name;
  final double grams;
  final Color color;
  final double maxGrams;

  const _MacroRow({
    required this.name,
    required this.grams,
    required this.color,
    required this.maxGrams,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxGrams > 0 ? (grams / maxGrams) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            Text(
              '${grams.toStringAsFixed(1)}g',
              style: AppTextStyles.label,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: fraction,
              color: color,
              backgroundColor: AppColors.border,
              minHeight: 2,
            ),
          ),
        ),
      ],
    );
  }
}
