import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  // Set via: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
  // Defaults to 10.0.2.2 (Android emulator host alias for localhost)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static Future<Map<String, dynamic>> analyzeFood(File imageFile) async {
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
}
