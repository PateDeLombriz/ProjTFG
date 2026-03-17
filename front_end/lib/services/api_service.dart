import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/obra_models.dart';

/// API base configurable:
/// - Web/desktop: per defecte http://localhost:8000
/// - Android emulator (si no passes dart-define): http://10.0.2.2:8000
///
/// Pots sobreescriure-ho així:
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000
const String _apiBaseUrlFromDefine = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String get _apiBaseUrl {
  if (_apiBaseUrlFromDefine.isNotEmpty) return _apiBaseUrlFromDefine;

  // Defaults raonables per entorn dev
  return kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
}

Future<List<Obra>> getObres() async {
  final uri = Uri.parse('$_apiBaseUrl/api/obres/');

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      debugPrint('GET $uri -> ${response.statusCode}');
      // Evita loguejar respostes enormes o sensibles
      final bodyPreview = response.body.length > 300
          ? '${response.body.substring(0, 300)}...'
          : response.body;
      debugPrint('BODY preview: $bodyPreview');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Expected a JSON list');
      }
      return decoded.map<Obra>((json) => Obra.fromMap(json)).toList();
    }

    // Errors HTTP amb missatge clar
    throw Exception('API error ${response.statusCode}: ${response.reasonPhrase}');
  } on SocketException {
    throw Exception('Network error: cannot reach the server ($_apiBaseUrl)');
  } on FormatException catch (e) {
    throw Exception('Invalid JSON from server: ${e.message}');
  } on http.ClientException catch (e) {
    throw Exception('HTTP client error: ${e.message}');
  }
}