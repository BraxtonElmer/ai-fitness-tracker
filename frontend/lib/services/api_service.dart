import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  /// Set via `--dart-define=GEMINI_API_KEY=...` for standalone food scan
  /// (direct Gemini from the app). If empty, [analyzeFood] uses [baseUrl].
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// REST model id. Defaults to 2.5 Flash (2.0 is deprecated; free tier often
  /// returns quota `limit: 0` for 2.0 in many projects).
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String _nutritionPrompt = r'''You are an expert nutritionist specializing in Indian cuisine. Analyze the food in this image and return ONLY a valid JSON object with no extra text, no markdown, no backticks.

The JSON must follow this exact structure:
{
  "dish_name": "Name of the dish",
  "confidence": "high" or "medium" or "low",
  "serving_size": "Estimated serving size as plain text",
  "calories": number,
  "macros": {
    "protein_g": number,
    "carbs_g": number,
    "fats_g": number,
    "fiber_g": number
  },
  "micros": {
    "iron_mg": number,
    "calcium_mg": number,
    "vitamin_c_mg": number,
    "vitamin_b12_mcg": number,
    "sodium_mg": number
  },
  "health_note": "A single helpful sentence about this dish"
}

If you cannot identify the food, return:
{
  "dish_name": "Unknown",
  "confidence": "low",
  "serving_size": "Unknown",
  "calories": 0,
  "macros": {"protein_g": 0, "carbs_g": 0, "fats_g": 0, "fiber_g": 0},
  "micros": {"iron_mg": 0, "calcium_mg": 0, "vitamin_c_mg": 0, "vitamin_b12_mcg": 0, "sodium_mg": 0},
  "health_note": "Could not identify the food in the image."
}

Return ONLY the JSON object. No other text.''';

  static String _cleanGeminiResponse(String text) {
    var t = text.trim();
    t = t.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
    t = t.replaceFirst(RegExp(r'\s*```$'), '');
    return t.trim();
  }

  static String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.tiff') || lower.endsWith('.tif')) {
      return 'image/tiff';
    }
    return 'image/jpeg';
  }

  static String? _extractModelText(Map<String, dynamic> body) {
    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return null;
    }
    final first = candidates[0] as Map<String, dynamic>?;
    final content = first?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null) {
      return null;
    }
    final buffer = StringBuffer();
    for (final p in parts) {
      if (p is Map<String, dynamic>) {
        final t = p['text'] as String?;
        if (t != null) {
          buffer.write(t);
        }
      }
    }
    if (buffer.isEmpty) {
      return null;
    }
    return buffer.toString();
  }

  static String? _messageFromGeminiError(Map<String, dynamic> body) {
    final err = body['error'];
    if (err is Map<String, dynamic>) {
      return err['message'] as String?;
    }
    return null;
  }

  /// The API returns long quota messages. Map them to a short, actionable line.
  static String _presentGeminiFailure(String? raw) {
    final t = (raw ?? '').toLowerCase();
    final isQuota = t.contains('quota') ||
        t.contains('resourceexhausted') ||
        t.contains('exceeded your current quota') ||
        t.contains('free_tier') ||
        t.contains('limit: 0');
    if (isQuota) {
      return 'Gemini quota or billing: link a billing account on your API key’s '
          'Cloud project (free usage can still be \$0) and enable Generative Language '
          'API, or use --dart-define=GEMINI_MODEL=gemini-2.5-flash-lite. '
          'https://ai.google.dev/gemini-api/docs/rate-limits';
    }
    if (raw == null || raw.trim().isEmpty) {
      return 'The AI could not analyze this image. Please try again.';
    }
    if (raw.length > 360) {
      return '${raw.substring(0, 360)}…';
    }
    return raw;
  }

  static Future<Map<String, dynamic>> _analyzeWithGeminiRest(
    File imageFile,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final mime = _mimeForPath(imageFile.path);
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/'
      'models/$geminiModel:generateContent',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': _nutritionPrompt},
            {
              'inline_data': {
                'mime_type': mime,
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
    };

    try {
      final response = await http
          .post(
            uri.replace(queryParameters: {'key': geminiApiKey}),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 60));

      Map<String, dynamic> body;
      try {
        body = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': false,
          'message':
              'Could not read nutrition data. Try a clearer photo.',
        };
      }

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': _presentGeminiFailure(_messageFromGeminiError(body)),
        };
      }

      final errMsg = _messageFromGeminiError(body);
      if (errMsg != null) {
        return {
          'success': false,
          'message': _presentGeminiFailure(errMsg),
        };
      }

      final rawText = _extractModelText(body);
      if (rawText == null || rawText.isEmpty) {
        return {
          'success': false,
          'message': 'The AI could not return nutrition data. Try another photo.',
        };
      }

      final cleaned = _cleanGeminiResponse(rawText);
      try {
        final nutritionData = json.decode(cleaned) as Map<String, dynamic>;
        return {'success': true, 'data': nutritionData};
      } on FormatException {
        return {
          'success': false,
          'message':
              'The AI returned an unreadable response. Please try again with a clearer photo.',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Analysis is taking too long, try again.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Cannot reach the AI service, check your connection.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not read nutrition data. Try a clearer photo.',
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzeWithBackend(
    File imageFile,
  ) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> body;
      try {
        body = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': false,
          'message':
              'Could not read nutrition data. Try a clearer photo.',
        };
      }

      if (response.statusCode == 200 && body['success'] == true) {
        return body;
      }

      return {
        'success': false,
        'message': body['message'] as String? ??
            'Something went wrong. Please try again.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Analysis is taking too long, try again.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Cannot reach server, check your connection.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not read nutrition data. Try a clearer photo.',
      };
    }
  }

  static Future<Map<String, dynamic>> analyzeFood(File imageFile) async {
    if (geminiApiKey.isNotEmpty) {
      return _analyzeWithGeminiRest(imageFile);
    }
    return _analyzeWithBackend(imageFile);
  }
}
