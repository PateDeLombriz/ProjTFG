import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/models/incidencia_models.dart';

class IncidenciaServiceException implements Exception {
  final String message;
  final int? statusCode;

  const IncidenciaServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class IncidenciaService {
  final String baseUrl;
  final http.Client _client;

  String? _validatedToken;

  IncidenciaService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<IncidenciaProfileData> fetchIncidenciaProfile(int incidenciaId) async {
    final raw = await fetchIncidenciaRaw(incidenciaId);
    return IncidenciaProfileData.fromMap(raw);
  }

  Future<Map<String, dynamic>> fetchIncidenciaRaw(int incidenciaId) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.get(
      Uri.parse('$baseUrl/incidencia/$incidenciaId/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw IncidenciaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant la incidència',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const IncidenciaServiceException(
        'La resposta de la incidència no és vàlida.',
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> updateIncidencia(
    int incidenciaId,
    Map<String, dynamic> payload,
  ) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.put(
      Uri.parse('$baseUrl/incidencia/$incidenciaId/'),
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw IncidenciaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error actualitzant la incidència',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const IncidenciaServiceException(
        'La resposta d’actualització de la incidència no és vàlida.',
      );
    }

    return decoded;
  }

  Future<void> deleteIncidencia(int incidenciaId) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.delete(
      Uri.parse('$baseUrl/incidencia/$incidenciaId/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw IncidenciaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error eliminant la incidència',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> ensureAuthenticatedSession() async {
    await _requireAuthenticatedSession();
  }

  Future<String> _requireAuthenticatedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _readStoredToken(prefs);

    if (token == null || token.isEmpty) {
      throw const IncidenciaServiceException('No hi ha sessió guardada.');
    }

    if (_validatedToken == token) {
      return token;
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/me/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      await _storeSessionContext(prefs, token, response.body);
      _validatedToken = token;
      return token;
    }

    _validatedToken = null;

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _clearStoredSession();
      throw IncidenciaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'La sessió ha caducat o no és vàlida. Torna a fer login.',
        ),
        statusCode: response.statusCode,
      );
    }

    throw IncidenciaServiceException(
      _extractErrorMessage(
        response,
        fallback: 'Error al carregar la sessió.',
      ),
      statusCode: response.statusCode,
    );
  }

  String? _readStoredToken(SharedPreferences prefs) {
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final access = prefs.getString('access')?.trim();
    if (access != null && access.isNotEmpty) {
      return access;
    }

    final legacyToken = prefs.getString('session_token')?.trim();
    if (legacyToken != null && legacyToken.isNotEmpty) {
      return legacyToken;
    }

    return null;
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _storeSessionContext(
    SharedPreferences prefs,
    String token,
    String body,
  ) async {
    await prefs.setString('token', token);

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final subjectId = decoded['subject_id'];
        final tipus = decoded['tipus'];
        final idEmpresa = decoded['id_empresa'];

        if (subjectId != null) {
          await prefs.setString('subject_id', subjectId.toString());
        }

        if (tipus != null) {
          await prefs.setString('tipus', tipus.toString());
        }

        if (idEmpresa != null) {
          await prefs.setString('id_empresa', idEmpresa.toString());
        }
      }
    } catch (_) {
      // Si /me/ retorna un body inesperat, mantenim almenys el token.
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('access');
    await prefs.remove('refresh');
    await prefs.remove('tipus');
    await prefs.remove('subject_id');
    await prefs.remove('id_empresa');
    _validatedToken = null;
  }

  Future<void> _handleUnauthorizedIfNeeded(int statusCode) async {
    if (statusCode == 401 || statusCode == 403) {
      await _clearStoredSession();
    }
  }

  String _extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }

        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }

        final nonFieldErrors = decoded['non_field_errors'];
        if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
          return nonFieldErrors.first.toString();
        }

        if (decoded.isNotEmpty) {
          return decoded.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(' | ');
        }
      }

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.first.toString();
      }
    } catch (_) {
      final raw = response.body.trim();
      if (raw.isNotEmpty) {
        return raw;
      }
    }

    return fallback;
  }

  void dispose() {
    _client.close();
  }
}