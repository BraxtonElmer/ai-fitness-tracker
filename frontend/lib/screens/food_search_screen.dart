import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/indian_foods_seed.dart';
import '../theme.dart';
import '../services/open_food_facts_service.dart';
import 'meal_log_editor_screen.dart';

/// Indian dishes (estimates) + Open Food Facts (India + global), per-100g products.
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _ctrl = TextEditingController();
  final _gramCtrl = TextEditingController(text: '100');
  bool _loading = false;
  String? _err;

  List<IndianDish> _indian = const [];
  List<OffSearchHit> _inIndia = const [];
  List<OffSearchHit> _world = const [];

  @override
  void dispose() {
    _ctrl.dispose();
    _gramCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _ctrl.text.trim();
    if (q.length < 2) {
      setState(() {
        _indian = [];
        _inIndia = [];
        _world = [];
        _err = 'Type at least 2 characters (try: dosa, biryani, atta).';
      });
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final b = await OpenFoodFactsService.searchAll(q);
      if (mounted) {
        setState(() {
          _indian = b.indian;
          _inIndia = b.inIndia;
          _world = b.world;
          _loading = false;
          if (_indian.isEmpty && _inIndia.isEmpty && _world.isEmpty) {
            _err = 'No matches — try another spelling or a packaged brand name for OFF.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = 'Search failed, check your connection';
        });
      }
    }
  }

  void _openOff(OffSearchHit hit) {
    final g = double.tryParse(_gramCtrl.text.trim().replaceAll(',', '.')) ?? 100;
    final gUse = g.clamp(1.0, 2000.0);
    final n = hit.toNutritionForGrams(gUse);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (c, a, s) => MealLogEditorScreen(
          initialNutrition: n,
          source: FoodEntrySource.search,
        ),
        transitionsBuilder: (c, a, s, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  void _openIndian(IndianDish d) {
    final n = d.toNutrition(portion: 1.0);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (c, a, s) => MealLogEditorScreen(
          initialNutrition: n,
          source: FoodEntrySource.search,
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.accent),
        ),
        title: Text(
          'Search food',
          style: AppTextStyles.heading.copyWith(fontSize: AppFontSizes.lg),
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _runSearch(),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Dosa, biryani, Amul, Maggi, atta…',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderRadius,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _runSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                    ),
                    child: const Icon(LucideIcons.search, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x2,
              0,
            ),
            child: Row(
              children: [
                Text(
                  'Portion (g) for packaged foods',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _gramCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Text(
                _err!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.x2),
                children: [
                  if (_indian.isNotEmpty) ...[
                    _header('Indian dishes (typical serving, estimate)'),
                    ..._indian.map(
                      (d) => _tile(
                        d.name,
                        '${d.servingSize} · ~${d.kcal} kcal',
                        onTap: () => _openIndian(d),
                        chip: 'Estimate',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                  ],
                  if (_inIndia.isNotEmpty) ...[
                    _header('Packaged in India (Open Food Facts)'),
                    ..._inIndia.map(
                      (h) => _tile(
                        h.name,
                        '${h.kcal100.round()} kcal / 100g · ${h.regionLabel}',
                        onTap: () => _openOff(h),
                        chip: 'IN',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                  ],
                  if (_world.isNotEmpty) ...[
                    _header('Global products (Open Food Facts)'),
                    ..._world.map(
                      (h) => _tile(
                        h.name,
                        '${h.kcal100.round()} kcal / 100g',
                        onTap: () => _openOff(h),
                        chip: 'OFF',
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Text(
        t,
        style: AppTextStyles.label.copyWith(
          color: AppColors.mutedText,
        ),
      ),
    );
  }

  Widget _tile(
    String title,
    String sub, {
    required VoidCallback onTap,
    String? chip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x1),
      child: ListTile(
        onTap: onTap,
        tileColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: AppTextStyles.label, maxLines: 2),
        subtitle: Text(
          sub,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        leading: chip != null
            ? Text(
                chip,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                ),
              )
            : null,
        trailing: const Icon(
          LucideIcons.chevronRight,
          color: AppColors.mutedText,
        ),
      ),
    );
  }
}
