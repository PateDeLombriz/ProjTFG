import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/models/treballador_models.dart';

class TreballadorServiceException implements Exception {
  final String message;
  final int? statusCode;

  const TreballadorServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class TreballadorService {
  final String baseUrl;
  final http.Client _client;

  String? _validatedToken;

  TreballadorService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Perfil propi del treballador autenticat.
  /// Resol l'id des de la sessió i crida /treballadors/profile/<id>/
  Future<TreballadorProfileData> fetchMyProfile() async {
    final treballadorId = await requireTreballadorId();
    return fetchTreballadorProfile(treballadorId);
  }

/// Retorna el perfil resumit d'un treballador per a ús visual.
/// A diferència de fetchTreballadorDetail(), aquest mètode està orientat
/// a capçalera, resum i mètriques, no a informació administrativa completa.
  Future<TreballadorProfileData> fetchTreballadorProfile(int treballadorId) async {
    final raw = await fetchTreballadorProfileRaw(treballadorId);
    return TreballadorProfileData.fromMap(raw);
  }

  Future<Map<String, dynamic>> fetchTreballadorProfileRaw(int treballadorId) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.get(
      Uri.parse('$baseUrl/treballadors/profile/$treballadorId/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TreballadorServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant el perfil del treballador',
        ),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const TreballadorServiceException(
        'La resposta del perfil del treballador no és vàlida.',
      );
    }

    return decoded;
  }
/// Retorna el detall d'un treballador concret, perque l'empresa pugui veure informació interna.Que el treballador no ha de sebre.
/// A diferència de fetchTreballadorProfile(), aquest mètode prioritza dades
/// com contractes i informació interna, no el resum visual del perfil.
  Future<Map<String, dynamic>> fetchTreballadorDetail(int treballadorId) async {
  final token = await _requireAuthenticatedSession();

  final response = await _client.get(
    Uri.parse('$baseUrl/treballadors/$treballadorId/'),
    headers: _authHeaders(token),
  );

  if (response.statusCode != 200) {
    await _handleUnauthorizedIfNeeded(response.statusCode);
    throw TreballadorServiceException(
      _extractErrorMessage(
        response,
        fallback: 'Error carregant el detall del treballador',
      ),
      statusCode: response.statusCode,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw const TreballadorServiceException(
      'La resposta del detall del treballador no és vàlida.',
    );
  }

  return decoded;
}

/// Retorna les tasques detallades assignades a un treballador.
/// A diferència d'un llistat d'assignacions com tasca_treballador,
/// aquí cada element ja ve enriquit amb dades de tasca, obra i relacions.
Future<List<Map<String, dynamic>>> fetchTreballadorTasques(
  int treballadorId,
) async {
  final token = await _requireAuthenticatedSession();

  final response = await _client.get(
    Uri.parse('$baseUrl/treballadors/$treballadorId/tasques/'),
    headers: _authHeaders(token),
  );

  if (response.statusCode != 200) {
    await _handleUnauthorizedIfNeeded(response.statusCode);
    throw TreballadorServiceException(
      _extractErrorMessage(
        response,
        fallback: 'Error carregant les tasques del treballador',
      ),
      statusCode: response.statusCode,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const TreballadorServiceException(
      'La resposta de les tasques del treballador no és vàlida.',
    );
  }

  return decoded.map((item) {
    if (item is Map<String, dynamic>) {
      return item;
    }
    return Map<String, dynamic>.from(item as Map);
  }).toList();
}

  /// Retorna les obres on el treballador ha participat.
/// A diferència de fetchTreballadorTasques(), aquest mètode agrupa per obra
/// i dona una visió resumida de participació, no el detall de cada tasca.
Future<List<Map<String, dynamic>>> fetchTreballadorObresParticipades(
  int treballadorId,
) async {
  final token = await _requireAuthenticatedSession();

  final response = await _client.get(
    Uri.parse('$baseUrl/treballadors/$treballadorId/obres_participades/'),
    headers: _authHeaders(token),
  );

  if (response.statusCode != 200) {
    await _handleUnauthorizedIfNeeded(response.statusCode);
    throw TreballadorServiceException(
      _extractErrorMessage(
        response,
        fallback: 'Error carregant les obres participades del treballador',
      ),
      statusCode: response.statusCode,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const TreballadorServiceException(
      'La resposta de les obres participades no és vàlida.',
    );
  }

  return decoded.map((item) {
    if (item is Map<String, dynamic>) {
      return item;
    }
    return Map<String, dynamic>.from(item as Map);
  }).toList();
}

  Future<void> ensureAuthenticatedSession() async {
    await _requireAuthenticatedSession();
  }

  Future<int> requireTreballadorId() async {
    await _requireAuthenticatedSession();

    final prefs = await SharedPreferences.getInstance();

    final rawString = prefs.getString('subject_id')?.trim();
    if (rawString != null && rawString.isNotEmpty) {
      final parsed = int.tryParse(rawString);
      if (parsed != null) return parsed;
    }

    final rawInt = prefs.getInt('subject_id');
    if (rawInt != null) return rawInt;

    throw const TreballadorServiceException(
      'No s’ha trobat l’identificador del treballador a la sessió.',
    );
  }

  Future<String> _requireAuthenticatedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _readStoredToken(prefs);

    if (token == null || token.isEmpty) {
      throw const TreballadorServiceException('No hi ha sessió guardada.');
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
      throw TreballadorServiceException(
        _extractErrorMessage(
          response,
          fallback: 'La sessió ha caducat o no és vàlida. Torna a fer login.',
        ),
        statusCode: response.statusCode,
      );
    }

    throw TreballadorServiceException(
      _extractErrorMessage(
        response,
        fallback: 'Error al carregar la sessió.',
      ),
      statusCode: response.statusCode,
    );
  }

  String? _readStoredToken(SharedPreferences prefs) {
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) return token;

    final legacyToken = prefs.getString('session_token')?.trim();
    if (legacyToken != null && legacyToken.isNotEmpty) return legacyToken;

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
    } catch (_) {}
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

        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    return '$fallback (${response.statusCode})';
  }
}