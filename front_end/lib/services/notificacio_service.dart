import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/services/app_api_service.dart';

class NotificacioServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const NotificacioServiceException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}

class NotificacioService extends AppApiService {
  NotificacioService({String? baseUrl, http.Client? client}) : super(
    baseUrl: baseUrl ?? ApiConstants.baseUrl,
    client: client,
    exceptionFactory: (message, {int? statusCode, String? body}) => NotificacioServiceException(message, statusCode: statusCode, body: body),
  );

  void dispose() => client.close();

  Future<List<Map<String, dynamic>>> fetchMyNotificacions({bool noLlegides = false}) async {
    final scope = await _resolveNotificationScope();
    return getJsonList(
      '/$scope/me/notificacions/',
      queryParameters: {if (noLlegides) 'no_llegides': 'true'},
      fallback: 'Error carregant les notificacions',
      invalidResponseMessage: 'La resposta de les notificacions no és vàlida.',
    );
  }

  Future<int> fetchNotificacionsCount() async {
    final scope = await _resolveNotificationScope();
    final data = await getJsonMap(
      '/$scope/me/notificacions/count/',
      fallback: 'Error carregant el comptador de notificacions',
      invalidResponseMessage: 'La resposta del comptador no és vàlida.',
    );

    final raw = data['count'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  Future<Map<String, dynamic>> marcarLlegida(int pk) async {
    final scope = await _resolveNotificationScope();
    return _patchJson('/$scope/me/notificacions/$pk/llegida/', body: {}, fallback: 'Error marcant la notificació com a llegida');
  }

  Future<String> _resolveNotificationScope() async {
    await requireAuthenticatedSession();

    final prefs = await SharedPreferences.getInstance();
    final tipus = prefs.getString('tipus')?.trim().toLowerCase();

    if (tipus == 'treballador') return 'treballadors';
    if (tipus == 'empresa') return 'empresa';

    throw const NotificacioServiceException('Tipus de sessió no reconegut per carregar notificacions.');
  }

  Future<Map<String, dynamic>> _patchJson(String path, {required Map<String, dynamic> body, required String fallback}) async {
    final token = await requireAuthenticatedSession();
    final response = await client.patch(buildUri(path), headers: authHeaders(token), body: jsonEncode(body));

    if (response.statusCode != 200) {
      throw NotificacioServiceException(extractErrorMessage(response, fallback: fallback), statusCode: response.statusCode, body: response.body);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const NotificacioServiceException('La resposta del servidor no és vàlida.');
  }
}
