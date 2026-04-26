import 'dart:convert';

/// Deep copy JSON-like nutrition map from AI, search, or manual entry.
Map<String, dynamic> copyNutritionMap(Map<String, dynamic> source) {
  return Map<String, dynamic>.from(
    json.decode(json.encode(source)) as Map<dynamic, dynamic>,
  );
}

/// Multiply kcal, macros, and micros by [factor] (e.g. 0.5 = half serving).
void scaleNutritionMap(Map<String, dynamic> m, double factor) {
  final cal = (m['calories'] as num?)?.toDouble();
  if (cal != null) {
    m['calories'] = cal * factor;
  }
  final macros = m['macros'] as Map<String, dynamic>?;
  if (macros != null) {
    for (final k in const [
      'protein_g',
      'carbs_g',
      'fats_g',
      'fiber_g',
    ]) {
      final v = (macros[k] as num?)?.toDouble();
      if (v != null) {
        macros[k] = v * factor;
      }
    }
  }
  final micros = m['micros'] as Map<String, dynamic>?;
  if (micros != null) {
    for (final e in micros.entries) {
      final v = (e.value as num?)?.toDouble();
      if (v != null) {
        micros[e.key] = v * factor;
      }
    }
  }
}

/// Parse a text field to double, default 0.
double parseDoubleLoose(String? t) {
  if (t == null || t.trim().isEmpty) {
    return 0;
  }
  return double.tryParse(t.trim().replaceAll(',', '.')) ?? 0;
}
