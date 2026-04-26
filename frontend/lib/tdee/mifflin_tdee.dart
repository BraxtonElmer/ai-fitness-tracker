/// Mifflin–St Jeor BMR, then activity factor → maintenance kcal.
class MifflinTdee {
  MifflinTdee._();

  static double bmrKcal({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    final a = 10.0 * weightKg + 6.25 * heightCm - 5.0 * age;
    if (isMale) {
      return a + 5.0;
    }
    return a - 161.0;
  }

  static double tdeeKcal({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
    required double activityFactor,
  }) {
    final b = bmrKcal(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      isMale: isMale,
    );
    return b * activityFactor;
  }
}

const Map<String, double> kActivityLabelToFactor = {
  'Sedentary': 1.2,
  'Light (1-3x/wk)': 1.375,
  'Moderate (3-5x/wk)': 1.55,
  'Active (6-7x/wk)': 1.725,
  'Very active': 1.9,
};

String activityLabelByFactor(double f) {
  String? best;
  var bestD = 999.0;
  for (final e in kActivityLabelToFactor.entries) {
    final d = (e.value - f).abs();
    if (d < bestD) {
      bestD = d;
      best = e.key;
    }
  }
  return best ?? 'Light (1-3x/wk)';
}

double activityFactorByLabel(String? label) {
  if (label == null) {
    return 1.375;
  }
  return kActivityLabelToFactor[label] ?? 1.375;
}
