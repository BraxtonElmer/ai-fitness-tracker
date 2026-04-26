import '../nutrition/nutrition_utils.dart';

/// Ballpark kcal for common Indian home / street servings (planning/tracking only).
class IndianDish {
  final String name;
  final String servingSize;
  final String keywords; // space-separated for search
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatsG;

  const IndianDish({
    required this.name,
    required this.servingSize,
    required this.keywords,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  Map<String, dynamic> toNutrition({double portion = 1.0}) {
    final m = <String, dynamic>{
      'dish_name': name,
      'serving_size': servingSize,
      'calories': kcal * portion,
      'confidence': 'low',
      'health_note': 'Typical-serving estimate for Indian home food — adjust if needed.',
      'meal_type': 'lunch',
      'macros': {
        'protein_g': proteinG * portion,
        'carbs_g': carbsG * portion,
        'fats_g': fatsG * portion,
        'fiber_g': 2.0 * portion,
      },
      'micros': {
        'iron_mg': 1.0 * portion,
        'calcium_mg': 20.0 * portion,
        'vitamin_c_mg': 1.0 * portion,
        'vitamin_b12_mcg': 0.1 * portion,
        'sodium_mg': 200.0 * portion,
      },
    };
    m['_fitcore'] = {
      'source': 'indian_seed',
    };
    return copyNutritionMap(m);
  }
}

/// Curated list — add more as needed. Search is token + substring.
const List<IndianDish> kIndianDishes = [
  IndianDish(
    name: 'Masala dosa',
    servingSize: '1 medium with chutney (about 1 plate)',
    keywords: 'dosa masala south indian',
    kcal: 300,
    proteinG: 8,
    carbsG: 40,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Plain dosa',
    servingSize: '1 medium',
    keywords: 'dosa plain ghee',
    kcal: 200,
    proteinG: 5,
    carbsG: 32,
    fatsG: 5,
  ),
  IndianDish(
    name: 'Idli (2 pieces)',
    servingSize: '2 idli + sambhar',
    keywords: 'idli sambhar south',
    kcal: 200,
    proteinG: 5,
    carbsG: 38,
    fatsG: 2,
  ),
  IndianDish(
    name: 'Vada sambhar (1)',
    servingSize: '1 medu vada with sambhar',
    keywords: 'vada medu',
    kcal: 200,
    proteinG: 5,
    carbsG: 22,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Poha',
    servingSize: '1 plate cooked',
    keywords: 'poha flattened rice breakfast',
    kcal: 250,
    proteinG: 5,
    carbsG: 40,
    fatsG: 6,
  ),
  IndianDish(
    name: 'Upma',
    servingSize: '1 plate',
    keywords: 'upma rava sooji',
    kcal: 300,
    proteinG: 6,
    carbsG: 45,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Paratha (aloo)',
    servingSize: '1 paratha with curd or pickle',
    keywords: 'paratha aloo alu roti',
    kcal: 300,
    proteinG: 6,
    carbsG: 35,
    fatsG: 15,
  ),
  IndianDish(
    name: 'Paratha (plain)',
    servingSize: '1 with curd',
    keywords: 'paratha ghee',
    kcal: 250,
    proteinG: 5,
    carbsG: 32,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Chapati (roti) — 1',
    servingSize: '1 whole wheat (small)',
    keywords: 'roti chapati phulka',
    kcal: 70,
    proteinG: 2,
    carbsG: 15,
    fatsG: 0.5,
  ),
  IndianDish(
    name: 'Dal (lentil curry) + rice',
    servingSize: '1 katori dal + 1 cup rice',
    keywords: 'dal chawal rice toor moong arhar',
    kcal: 450,
    proteinG: 12,
    carbsG: 70,
    fatsG: 8,
  ),
  IndianDish(
    name: 'Rajma chawal',
    servingSize: '1 regular plate',
    keywords: 'rajma rice kidney bean',
    kcal: 500,
    proteinG: 15,
    carbsG: 75,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Chole bhature',
    servingSize: '2 bhature + chana',
    keywords: 'chole chana bhature punjabi',
    kcal: 800,
    proteinG: 20,
    carbsG: 90,
    fatsG: 40,
  ),
  IndianDish(
    name: 'Chole (chana) + 2 roti',
    servingSize: 'home-style plate',
    keywords: 'chole chana roti',
    kcal: 500,
    proteinG: 16,
    carbsG: 60,
    fatsG: 16,
  ),
  IndianDish(
    name: 'Paneer butter masala + roti (2)',
    servingSize: 'restaurant / home (approx.)',
    keywords: 'paneer butter roti',
    kcal: 600,
    proteinG: 20,
    carbsG: 50,
    fatsG: 32,
  ),
  IndianDish(
    name: 'Palak paneer + roti (2)',
    servingSize: '1 plate',
    keywords: 'palak paneer saag',
    kcal: 500,
    proteinG: 18,
    carbsG: 45,
    fatsG: 24,
  ),
  IndianDish(
    name: 'Butter chicken + naan (1)',
    servingSize: 'typical order',
    keywords: 'butter chicken murgh murg naan',
    kcal: 700,
    proteinG: 32,
    carbsG: 55,
    fatsG: 36,
  ),
  IndianDish(
    name: 'Biryani (chicken) — 1 plate',
    servingSize: 'full plate, home/restaurant (varies a lot)',
    keywords: 'biryani chicken hyderabadi',
    kcal: 600,
    proteinG: 25,
    carbsG: 70,
    fatsG: 20,
  ),
  IndianDish(
    name: 'Biryani (veg) — 1 plate',
    servingSize: 'typical',
    keywords: 'biryani vegetable veg',
    kcal: 500,
    proteinG: 10,
    carbsG: 80,
    fatsG: 12,
  ),
  IndianDish(
    name: 'Samosa (1 large)',
    servingSize: 'street / frozen style',
    keywords: 'samosa snack',
    kcal: 250,
    proteinG: 4,
    carbsG: 28,
    fatsG: 14,
  ),
  IndianDish(
    name: 'Samosa (2 small)',
    servingSize: '2 pieces with chutney',
    keywords: 'samosa chutney',
    kcal: 200,
    proteinG: 3,
    carbsG: 24,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Pakora / bhajia (mixed) — 5 pieces',
    servingSize: 'onion/veg mix, fried',
    keywords: 'pakora bajji bhajiya fritter',
    kcal: 300,
    proteinG: 5,
    carbsG: 25,
    fatsG: 18,
  ),
  IndianDish(
    name: 'Dhokla (5 pieces) + chutney',
    servingSize: 'Gujarati style',
    keywords: 'dhokla chutney gujarat',
    kcal: 200,
    proteinG: 5,
    carbsG: 35,
    fatsG: 3,
  ),
  IndianDish(
    name: 'Pav bhaji — 1 plate',
    servingSize: '2 pav + bhaji (approx.)',
    keywords: 'pav bhaji mumbai',
    kcal: 500,
    proteinG: 8,
    carbsG: 65,
    fatsG: 20,
  ),
  IndianDish(
    name: 'Vada pav (1)',
    servingSize: '1 burger-style',
    keywords: 'vada pav mumbai',
    kcal: 300,
    proteinG: 6,
    carbsG: 40,
    fatsG: 12,
  ),
  IndianDish(
    name: 'Misal pav',
    servingSize: '1 full plate (varies by region)',
    keywords: 'misal pav maharashtra',
    kcal: 450,
    proteinG: 15,
    carbsG: 50,
    fatsG: 20,
  ),
  IndianDish(
    name: 'Appam + stew (veg) — 2 appam',
    servingSize: 'Kerala style (approx.)',
    keywords: 'appam stew kerala',
    kcal: 400,
    proteinG: 6,
    carbsG: 55,
    fatsG: 16,
  ),
  IndianDish(
    name: 'Rasam + rice',
    servingSize: '1 regular meal cup rice',
    keywords: 'rasam rice thali',
    kcal: 350,
    proteinG: 6,
    carbsG: 65,
    fatsG: 5,
  ),
  IndianDish(
    name: 'Curd rice',
    servingSize: '1 bowl',
    keywords: 'dahi chawal dahi bhat',
    kcal: 300,
    proteinG: 8,
    carbsG: 50,
    fatsG: 5,
  ),
  IndianDish(
    name: 'Khichdi',
    servingSize: '1 large bowl (dal-rice style)',
    keywords: 'khichdi kichri moong',
    kcal: 300,
    proteinG: 8,
    carbsG: 50,
    fatsG: 4,
  ),
  IndianDish(
    name: 'Aloo gobi + roti (2)',
    servingSize: 'home',
    keywords: 'aloo gobi potato cauliflower',
    kcal: 400,
    proteinG: 8,
    carbsG: 50,
    fatsG: 16,
  ),
  IndianDish(
    name: 'Egg curry + roti (2)',
    servingSize: '2 eggs, gravy',
    keywords: 'anda egg masala',
    kcal: 500,
    proteinG: 18,
    carbsG: 45,
    fatsG: 24,
  ),
  IndianDish(
    name: 'Fish curry + rice (1 cup)',
    servingSize: 'Bengali / coastal (approx.)',
    keywords: 'fish mach curry rice',
    kcal: 500,
    proteinG: 25,
    carbsG: 60,
    fatsG: 12,
  ),
  IndianDish(
    name: 'Thali (veg, average)',
    servingSize: 'restaurant thali (varies a lot)',
    keywords: 'thali meal',
    kcal: 800,
    proteinG: 20,
    carbsG: 100,
    fatsG: 30,
  ),
  IndianDish(
    name: 'Filter coffee (with milk+ sugar)',
    servingSize: '1 tumbler',
    keywords: 'coffee filter kaapi south',
    kcal: 50,
    proteinG: 1,
    carbsG: 6,
    fatsG: 1,
  ),
  IndianDish(
    name: 'Chai (masala, with sugar)',
    servingSize: '1 cup full milk',
    keywords: 'chai tea adrak elaichi',
    kcal: 90,
    proteinG: 2,
    carbsG: 10,
    fatsG: 3,
  ),
  IndianDish(
    name: 'Lassi (sweet)',
    servingSize: '1 glass',
    keywords: 'lassi dahi',
    kcal: 200,
    proteinG: 5,
    carbsG: 30,
    fatsG: 4,
  ),
  IndianDish(
    name: 'Jalebi (small serve)',
    servingSize: '6–8 small rings',
    keywords: 'jalebi sweet mithai',
    kcal: 200,
    proteinG: 1,
    carbsG: 40,
    fatsG: 3,
  ),
  IndianDish(
    name: 'Gulab jamun (2 pieces)',
    servingSize: '2 medium',
    keywords: 'gulab jamun sweet',
    kcal: 200,
    proteinG: 2,
    carbsG: 30,
    fatsG: 8,
  ),
  IndianDish(
    name: 'Rasgulla (2 pieces)',
    servingSize: '2 medium (syrup drained, approx.)',
    keywords: 'rasgulla bengal sweet',
    kcal: 150,
    proteinG: 2,
    carbsG: 32,
    fatsG: 0.5,
  ),
  IndianDish(
    name: 'Chaat (bhel) — 1 plate',
    servingSize: 'bhel / street (approx.)',
    keywords: 'bhel chaat sev',
    kcal: 300,
    proteinG: 5,
    carbsG: 45,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Dahi puri (6 pieces)',
    servingSize: 'chaat',
    keywords: 'dahi puri golgappa pani',
    kcal: 300,
    proteinG: 4,
    carbsG: 40,
    fatsG: 10,
  ),
  IndianDish(
    name: 'Paneer tikka (6–8 pieces)',
    servingSize: 'starter / snack',
    keywords: 'paneer tikka tandoor',
    kcal: 300,
    proteinG: 20,
    carbsG: 8,
    fatsG: 20,
  ),
  IndianDish(
    name: 'Chai + biscuit (2)',
    servingSize: 'evening',
    keywords: 'chai biscuit rusk',
    kcal: 100,
    proteinG: 1,
    carbsG: 16,
    fatsG: 2,
  ),
];

List<IndianDish> searchIndianSeeds(String query) {
  final q = query.trim().toLowerCase();
  if (q.length < 2) {
    return const [];
  }
  final toks = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (toks.isEmpty) {
    return const [];
  }
  final out = <IndianDish>[];
  for (final d in kIndianDishes) {
    final hay = '${d.name} ${d.keywords}'.toLowerCase();
    if (toks.every((t) => hay.contains(t))) {
      out.add(d);
    }
  }
  if (out.isEmpty) {
    for (final d in kIndianDishes) {
      final hay = '${d.name} ${d.keywords}'.toLowerCase();
      if (hay.contains(q)) {
        out.add(d);
      }
    }
  }
  if (out.length > 20) {
    return out.take(20).toList();
  }
  return out;
}
