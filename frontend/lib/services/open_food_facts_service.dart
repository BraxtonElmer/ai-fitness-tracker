import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/indian_foods_seed.dart';
import '../nutrition/nutrition_utils.dart';

const _offFields =
    'product_name,brands,nutriments,image_front_small_url,code';

String _url(String host) =>
    'https://$host.openfoodfacts.org/cgi/search.pl?search_simple=1&action=process&json=true&page_size=15&fields=$_offFields&search_terms=';

class SearchAllResult {
  final List<IndianDish> indian;
  final List<OffSearchHit> inIndia;
  final List<OffSearchHit> world;

  const SearchAllResult({
    required this.indian,
    required this.inIndia,
    required this.world,
  });
}

class OpenFoodFactsService {
  static Future<SearchAllResult> searchAll(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      return const SearchAllResult(indian: [], inIndia: [], world: []);
    }
    final local = searchIndianSeeds(q);
    final a = _searchOpenFood('in', q);
    final b = _searchOpenFood('world', q);
    final r = await Future.wait([a, b]);
    return SearchAllResult(
      indian: local,
      inIndia: r[0],
      world: r[1],
    );
  }

  static Future<List<OffSearchHit>> _searchOpenFood(
    String host,
    String terms,
  ) async {
    final uri = Uri.parse('${_url(host)}${Uri.encodeComponent(terms)}');
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) {
        return [];
      }
      return _parseResponse(r.body, host: host);
    } catch (_) {
      return [];
    }
  }

  static List<OffSearchHit> _parseResponse(
    String body, {
    required String host,
  }) {
    final j = json.decode(body) as Map<String, dynamic>?;
    final list = j?['products'] as List<dynamic>?;
    if (list == null) {
      return [];
    }
    final out = <OffSearchHit>[];
    for (final raw in list) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final n = raw['nutriments'] as Map<String, dynamic>?;
      if (n == null) {
        continue;
      }
      final kcal = _kcal100(n);
      if (kcal == null || kcal <= 0) {
        continue;
      }
      final name = (raw['product_name'] as String? ?? 'Unknown').trim();
      if (name.isEmpty) {
        continue;
      }
      final saltG = (n['salt_100g'] as num?)?.toDouble() ?? 0.0;
      final sodiG = (n['sodium_100g'] as num?)?.toDouble();
      final sodiumMg = sodiG != null
          ? sodiG * 1000.0
          : saltG * 400.0;
      out.add(OffSearchHit(
        name: name,
        brand: (raw['brands'] as String? ?? '').trim(),
        kcal100: kcal,
        protein100: (n['proteins_100g'] as num?)?.toDouble() ?? 0,
        carbs100: (n['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
        fat100: (n['fat_100g'] as num?)?.toDouble() ?? 0,
        fiber100: (n['fiber_100g'] as num?)?.toDouble() ?? 0,
        sodiumMg100: sodiumMg,
        imageUrl: raw['image_front_small_url'] as String?,
        code: raw['code'] as String? ?? '',
        sourceHost: host,
      ));
      if (out.length >= 12) {
        break;
      }
    }
    return out;
  }

  static double? _kcal100(Map<String, dynamic> n) {
    final a = n['energy-kcal_100g'] as num?;
    if (a != null) {
      return a.toDouble();
    }
    final k = n['energy_100g'] as num?;
    if (k != null) {
      return k.toDouble() / 4.184;
    }
    return null;
  }
}

class OffSearchHit {
  final String name;
  final String brand;
  final double kcal100;
  final double protein100;
  final double carbs100;
  final double fat100;
  final double fiber100;
  final double sodiumMg100;
  final String? imageUrl;
  final String code;
  final String sourceHost;

  OffSearchHit({
    required this.name,
    required this.brand,
    required this.kcal100,
    required this.protein100,
    required this.carbs100,
    required this.fat100,
    required this.fiber100,
    required this.sodiumMg100,
    this.imageUrl,
    required this.code,
    this.sourceHost = 'world',
  });

  String get regionLabel => sourceHost == 'in' ? 'Open Food Facts · India' : 'Open Food Facts';

  String get fullTitle {
    if (brand.isEmpty) {
      return name;
    }
    return '$name · $brand';
  }

  Map<String, dynamic> toNutritionForGrams(double grams) {
    final f = grams / 100.0;
    final m = <String, dynamic>{
      'dish_name': name,
      'serving_size': '${grams.round()} g',
      'calories': kcal100 * f,
      'confidence': 'medium',
      'health_note': 'Open Food Facts (estimate, per 100g label)',
      'meal_type': 'lunch',
      'macros': {
        'protein_g': protein100 * f,
        'carbs_g': carbs100 * f,
        'fats_g': fat100 * f,
        'fiber_g': fiber100 * f,
      },
      'micros': {
        'iron_mg': 0.0,
        'calcium_mg': 0.0,
        'vitamin_c_mg': 0.0,
        'vitamin_b12_mcg': 0.0,
        'sodium_mg': sodiumMg100 * f,
      },
    };
    m['_fitcore'] = {
      'source': 'search',
      'off_code': code,
    };
    return copyNutritionMap(m);
  }
}
