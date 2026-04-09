import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/models/tasca_models.dart';

class TascaServiceException implements Exception {
  final String message;
  final int? statusCode;

  const TascaServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class TascaService {
  final String baseUrl;
  final http.Client _client;

  String? _validatedToken;

  TascaService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<TascaProfileData> fetchTascaProfile(int tascaId) async {
    final raw = await fetchTascaRaw(tascaId);
    return TascaProfileData.fromMap(raw);
  }

  Future<Map<String, dynamic>> fetchTascaDetail(int tascaId) async {
    return fetchTascaRaw(tascaId);
  }

  Future<Map<String, dynamic>> fetchTascaRaw(int tascaId) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.get(
      Uri.parse('$baseUrl/tasca/$tascaId/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TascaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant la tasca',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const TascaServiceException('La resposta de la tasca no és vàlida.');
    }

    return decoded;
  }

  /// Requereix que l'endpoint GET /tasques/ estigui exposat a urls.
  ///
  /// Al backend que m'has passat, la vista TascaList existeix,
  /// però la ruta està comentada a urls - apiApp.py.
  Future<List<Map<String, dynamic>>> fetchTasques({int? obraId}) async {
    final token = await _requireAuthenticatedSession();

    final uri = Uri.parse('$baseUrl/tasques/').replace(
      queryParameters: {
        if (obraId != null) 'id_obra': obraId.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TascaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant les tasques',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const TascaServiceException('La resposta de les tasques no és vàlida.');
    }

    return decoded.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTasquesByObra(int obraId) async {
    return fetchTasques(obraId: obraId);
  }

  /// Requereix que l'endpoint POST /tasques/ estigui exposat a urls.
  Future<Map<String, dynamic>> createTasca(Map<String, dynamic> payload) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.post(
      Uri.parse('$baseUrl/tasques/'),
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TascaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error creant la tasca',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const TascaServiceException('La resposta de creació de la tasca no és vàlida.');
    }

    return decoded;
  }


  Future<List<Map<String, dynamic>>> fetchAssignacionsTasca(int tascaId) async {
    final token = await _requireAuthenticatedSession();

    final uri = Uri.parse('$baseUrl/tasca_treballador/').replace(
      queryParameters: {
        'id_tasca': tascaId.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TascaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant les assignacions de la tasca',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const TascaServiceException(
        'La resposta de les assignacions de la tasca no és vàlida.',
      );
    }

    return decoded.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  Future<void> deleteAssignacionsTasca(int tascaId) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.delete(
      Uri.parse('$baseUrl/tasca_treballador/$tascaId/bulk_delete/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TascaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error eliminant les assignacions de la tasca',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<int> requireEmpresaId() async {
    await _requireAuthenticatedSession();

    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.getString('subject_id')?.trim();

    if (rawId == null || rawId.isEmpty) {
      throw const TascaServiceException(
        'No s’ha trobat l’identificador de l’empresa a la sessió.',
      );
    }

    final idEmpresa = int.tryParse(rawId);
    if (idEmpresa == null) {
      throw TascaServiceException(
        'L’identificador de l’empresa no és vàlid: $rawId',
      );
    }

    return idEmpresa;
  }

  Future<void> ensureAuthenticatedSession() async {
    await _requireAuthenticatedSession();
  }

  Future<String> _requireAuthenticatedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _readStoredToken(prefs);

    if (token == null || token.isEmpty) {
      throw const TascaServiceException('No hi ha sessió guardada.');
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
      throw TascaServiceException(
        _extractErrorMessage(
          response,
          fallback: 'La sessió ha caducat o no és vàlida. Torna a fer login.',
        ),
        statusCode: response.statusCode,
      );
    }

    throw TascaServiceException(
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

    final legacyToken = prefs.getString('session_token')?.trim();
    if (legacyToken != null && legacyToken.isNotEmpty) {
      return legacyToken;
    }

    return null;
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
        if (subjectId != null) {
          await prefs.setString('subject_id', subjectId.toString());
        }

        final tipus = decoded['tipus'];
        if (tipus is String && tipus.trim().isNotEmpty) {
          await prefs.setString('tipus', tipus);
        }

        final idEmpresa = decoded['id_empresa'];
        if (idEmpresa != null) {
          await prefs.setString('id_empresa', idEmpresa.toString());
        }
      }
    } catch (_) {
      // Si /me/ no es pot parsejar, mantenim com a mínim el token validat.
    }
  }

  Map<String, String> _authHeaders(String token) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _handleUnauthorizedIfNeeded(int statusCode) async {
    if (statusCode == 401 || statusCode == 403) {
      _validatedToken = null;
      await _clearStoredSession();
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('session_token');
    await prefs.remove('subject_id');
    await prefs.remove('tipus');
    await prefs.remove('id_empresa');
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
          return detail;
        }
      }
    } catch (_) {
      // Ignoram errors de parseig i usam el fallback.
    }

    return '$fallback (${response.statusCode})';
  }
}
