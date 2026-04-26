import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../nutrition/nutrition_utils.dart';
import '../services/food_log_service.dart';
import 'result_screen.dart';

/// Where this entry came from (stored in [nutrition] map under `_fitcore` key).
class FoodEntrySource {
  static const String scan = 'scan';
  static const String search = 'search';
  static const String manual = 'manual';
}

const List<String> kMealTypes = [
  'breakfast',
  'lunch',
  'dinner',
  'snack',
];

String mealTypeLabel(String id) {
  switch (id) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    case 'snack':
      return 'Snacks';
    default:
      return id;
  }
}

/// Edit name, serving, amount (portion), optional macros; pick meal; save to local DB.
class MealLogEditorScreen extends StatefulWidget {
  final Map<String, dynamic> initialNutrition;
  final String source;

  /// Pops the editor plus this many previous routes (e.g. 1 to also pop [ResultScreen] after a scan).
  final int extraPopsAfterSave;

  const MealLogEditorScreen({
    super.key,
    required this.initialNutrition,
    this.source = FoodEntrySource.scan,
    this.extraPopsAfterSave = 0,
  });

  @override
  State<MealLogEditorScreen> createState() => _MealLogEditorScreenState();
}

class _MealLogEditorScreenState extends State<MealLogEditorScreen> {
  late Map<String, dynamic> _original;
  double _portion = 1.0;
  String _mealType = 'lunch';

  late final TextEditingController _dishCtrl;
  late final TextEditingController _servingCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _pCtrl;
  late final TextEditingController _cCtrl;
  late final TextEditingController _fCtrl;
  late final TextEditingController _noteCtrl;
  final _log = FoodLogService.instance;

  @override
  void initState() {
    super.initState();
    _original = copyNutritionMap(widget.initialNutrition);
    if (_original['macros'] is! Map) {
      _original['macros'] = {
        'protein_g': 0,
        'carbs_g': 0,
        'fats_g': 0,
        'fiber_g': 0,
      };
    }
    if (_original['micros'] is! Map) {
      _original['micros'] = {
        'iron_mg': 0,
        'calcium_mg': 0,
        'vitamin_c_mg': 0,
        'vitamin_b12_mcg': 0,
        'sodium_mg': 0,
      };
    }
    final m = _original['meal_type'] as String?;
    if (m != null && kMealTypes.contains(m)) {
      _mealType = m;
    }
    _dishCtrl = TextEditingController();
    _servingCtrl = TextEditingController();
    _kcalCtrl = TextEditingController();
    _pCtrl = TextEditingController();
    _cCtrl = TextEditingController();
    _fCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    _refillFromPortion();
  }

  @override
  void dispose() {
    _dishCtrl.dispose();
    _servingCtrl.dispose();
    _kcalCtrl.dispose();
    _pCtrl.dispose();
    _cCtrl.dispose();
    _fCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _refillFromPortion() {
    final w = copyNutritionMap(_original);
    scaleNutritionMap(w, _portion);
    _dishCtrl.text = w['dish_name'] as String? ?? 'Meal';
    _servingCtrl.text = w['serving_size'] as String? ?? '';
    _kcalCtrl.text = ((w['calories'] as num?)?.toDouble() ?? 0)
        .round()
        .toString();
    final mac = w['macros'] as Map<String, dynamic>? ?? {};
    _pCtrl.text = (mac['protein_g'] as num?)?.toStringAsFixed(1) ?? '0';
    _cCtrl.text = (mac['carbs_g'] as num?)?.toStringAsFixed(1) ?? '0';
    _fCtrl.text = (mac['fats_g'] as num?)?.toStringAsFixed(1) ?? '0';
    _noteCtrl.text = w['health_note'] as String? ?? '';
  }

  void _onPortionChanged(double p) {
    setState(() {
      _portion = p;
      _refillFromPortion();
    });
  }

  Map<String, dynamic> _buildPayload() {
    final m = <String, dynamic>{
      'dish_name': _dishCtrl.text.trim().isEmpty
          ? 'Meal'
          : _dishCtrl.text.trim(),
      'serving_size': _servingCtrl.text.trim().isEmpty
          ? '1 serving'
          : _servingCtrl.text.trim(),
      'calories': parseDoubleLoose(_kcalCtrl.text),
      'confidence': 'medium',
      'health_note': _noteCtrl.text.trim(),
      'macros': {
        'protein_g': parseDoubleLoose(_pCtrl.text),
        'carbs_g': parseDoubleLoose(_cCtrl.text),
        'fats_g': parseDoubleLoose(_fCtrl.text),
        'fiber_g': _original['macros'] is Map
            ? (((_original['macros'] as Map)['fiber_g'] as num?)?.toDouble() ?? 0) *
                _portion
            : 0.0,
      },
    };
    final om = _original['micros'] as Map<String, dynamic>?;
    if (om != null) {
      final micros = <String, dynamic>{};
      for (final e in om.entries) {
        final v = (e.value as num?)?.toDouble() ?? 0;
        micros[e.key] = v * _portion;
      }
      m['micros'] = micros;
    } else {
      m['micros'] = {
        'iron_mg': 0.0,
        'calcium_mg': 0.0,
        'vitamin_c_mg': 0.0,
        'vitamin_b12_mcg': 0.0,
        'sodium_mg': 0.0,
      };
    }
    m['meal_type'] = _mealType;
    m['_fitcore'] = {
      'source': widget.source,
      'portion': _portion,
    };
    return m;
  }

  Future<void> _save() async {
    final payload = _buildPayload();
    try {
      await _log.insertEntry(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to log', style: AppTextStyles.body),
            backgroundColor: AppColors.surface,
          ),
        );
        final n = 1 + widget.extraPopsAfterSave;
        for (var i = 0; i < n; i++) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save', style: AppTextStyles.body),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  void _preview() {
    final payload = _buildPayload();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (c, a, s) => ResultScreen(
          nutritionData: payload,
          showBack: true,
          showAddToLog: false,
        ),
        transitionsBuilder: (c, a, s, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.source == FoodEntrySource.manual
                          ? 'Add food'
                          : 'Add to log',
                      style: AppTextStyles.heading,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.x2),
                children: [
                  Text('Meal', style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.x1),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kMealTypes.map((id) {
                      final sel = _mealType == id;
                      return ChoiceChip(
                        label: Text(mealTypeLabel(id)),
                        selected: sel,
                        onSelected: (_) =>
                            setState(() => _mealType = id),
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surface,
                        labelStyle: AppTextStyles.bodySmall.copyWith(
                          color: sel ? AppColors.background : AppColors.primaryText,
                        ),
                        side: const BorderSide(color: AppColors.border),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text('Portion (×${ _portion.toStringAsFixed(2) })', style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.x1),
                  Slider(
                    value: _portion,
                    min: 0.25,
                    max: 3.0,
                    divisions: 22,
                    activeColor: AppColors.accent,
                    onChanged: (v) => _onPortionChanged(v),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _LabeledField(
                    label: 'Food name',
                    controller: _dishCtrl,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _LabeledField(
                    label: 'Serving / notes (size)',
                    controller: _servingCtrl,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _LabeledField(
                    label: 'Calories (kcal)',
                    controller: _kcalCtrl,
                    keyboard: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Protein (g)',
                          controller: _pCtrl,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: _LabeledField(
                          label: 'Carbs (g)',
                          controller: _cCtrl,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: _LabeledField(
                          label: 'Fat (g)',
                          controller: _fCtrl,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _LabeledField(
                    label: 'Note',
                    controller: _noteCtrl,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _preview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadius,
                        ),
                      ),
                      child: Text('Preview', style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.accent,
                      )),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text('ADD TO LOG', style: AppTextStyles.buttonText),
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
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboard,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body,
          onChanged: (_) {
            // Kept for potential validation
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderRadius,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadius,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadius,
              borderSide: const BorderSide(color: AppColors.accent, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: AppSpacing.x2,
            ),
          ),
        ),
      ],
    );
  }
}
