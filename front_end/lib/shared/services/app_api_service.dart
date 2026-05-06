import 'dart:convert';

import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Excepció base compartida de la capa HTTP.
///
/// Pots usar-la directament o bé mapar-la a l'excepció pròpia de cada servei
/// amb [exceptionFactory].
class AppApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const AppApiException(
    this.message, {
    this.statusCode,
    this.body,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);

    if (statusCode != null) {
      buffer.write(' [$statusCode]');
    }

    final cleanedBody = body?.trim();
    if (cleanedBody != null && cleanedBody.isNotEmpty) {
      buffer.write(' $cleanedBody');
    }

    return buffer.toString();
  }
}

/// Signatura opcional per convertir una [AppApiException] en l'excepció
/// específica del servei de domini.
typedef AppApiExceptionFactory = Exception Function(
  String message, {
  int? statusCode,
  String? body,
});

/// Servei base compartit per a tots els `_service.dart` autenticats.
///
/// Què centralitza:
/// - validació de sessió amb `/me/`
/// - lectura i neteja de token
/// - `subject_id`, `tipus`, `id_empresa`
/// - headers `Bearer`
/// - parseig d'errors del backend
/// - helpers GET / POST / PUT / DELETE amb JSON
///
/// Què NO hauria de contenir:
/// - lògica d'obra, tasca, incidència, recurs, etc.
/// - normalitzacions pròpies de cada domini
/// - models de domini
abstract class AppApiService {
  final String baseUrl;
  final http.Client client;

  /// Si és `true`, en fer [dispose] també es tanca el client HTTP.
  ///
  /// Deixa-ho a `false` si el client arriba des de fora i el gestiona una altra
  /// capa de l'app.
  final bool closeClientOnDispose;

  /// Factor opcional per seguir retornant excepcions del domini.
  ///
  /// Exemple a `ObraService`:
  /// ```dart
  /// super(
  ///   baseUrl: baseUrl,
  ///   client: client,
  ///   exceptionFactory: ({required message, int? statusCode, String? body}) =>
  ///       ObraServiceException(message, statusCode: statusCode, body: body),
  /// )
  /// ```
  final AppApiExceptionFactory? exceptionFactory;

  String? _validatedToken;

  AppApiService({
    String? baseUrl,
    http.Client? client,
    this.closeClientOnDispose = false,
    this.exceptionFactory,
  })  : baseUrl = baseUrl ?? ApiConstants.baseUrl,
        client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // SESSIÓ / CONTEXT AUTENTICAT
  // ---------------------------------------------------------------------------

  /// Força que hi hagi una sessió vàlida guardada.
  Future<void> ensureAuthenticatedSession() async {
    await requireAuthenticatedSession();
  }

  /// Retorna el token vàlid de la sessió actual.
  ///
  /// Flux:
  /// 1. Llegeix token de preferències.
  /// 2. Si ja s'ha validat abans, el reutilitza.
  /// 3. Si no, valida el token contra `/me/`.
  /// 4. Desa `subject_id`, `tipus` i `id_empresa` si el backend els retorna.
  Future<String> requireAuthenticatedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _readStoredToken(prefs);

    if (token == null || token.isEmpty) {
      _throwServiceException(
        'No hi ha sessió guardada.',
      );
    }

    if (_validatedToken == token) {
      return token!;
    }

    final response = await client.get(
      buildUri('/me/'),
      headers: authHeaders(token!),
    );

    if (response.statusCode == 200) {
      await _storeSessionContext(prefs, token, response.body);
      _validatedToken = token;
      return token;
    }

    _validatedToken = null;
    await _handleUnauthorizedIfNeeded(response.statusCode);

    _throwServiceException(
      extractErrorMessage(
        response,
        fallback: response.statusCode == 401 || response.statusCode == 403
            ? 'La sessió ha caducat o no és vàlida. Torna a fer login.'
            : 'Error al carregar la sessió.',
      ),
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Retorna l'id de l'empresa del context actiu.
  ///
  /// Prioritza `id_empresa` i, si no existeix, fa fallback a `subject_id`.
  /// Això evita la inconsistència que tenies a alguns serveis on només es mirava
  /// `subject_id`.
  Future<int> requireEmpresaId() async {
    await requireAuthenticatedSession();

    final prefs = await SharedPreferences.getInstance();

    final tipus = prefs.getString('tipus')?.trim().toLowerCase();

    if (tipus != null && tipus.isNotEmpty && tipus != 'empresa') {
      _throwServiceException(
        'La sessió actual no correspon a una empresa.',
      );
    }
    final rawEmpresaId = prefs.getString('id_empresa')?.trim() ??
        prefs.getString('subject_id')?.trim();

    if (rawEmpresaId == null || rawEmpresaId.isEmpty) {
      _throwServiceException(
        'No s’ha trobat l’identificador de l’empresa a la sessió.',
      );
    }

    final empresaId = int.tryParse(rawEmpresaId!);
    if (empresaId == null) {
      _throwServiceException(
        'L’identificador de l’empresa no és vàlid: $rawEmpresaId',
      );
    }

    return empresaId!;
  }

  /// Retorna l'id del treballador autenticat.
  Future<int> requireTreballadorId() async {
    await requireAuthenticatedSession();

    final prefs = await SharedPreferences.getInstance();
    final tipus = prefs.getString('tipus')?.trim().toLowerCase();

    if (tipus != null && tipus.isNotEmpty && tipus != 'treballador') {
      _throwServiceException(
        'La sessió actual no correspon a un treballador.',
      );
    }

    final rawString = prefs.getString('subject_id')?.trim();
    if (rawString != null && rawString.isNotEmpty) {
      final parsed = int.tryParse(rawString);
      if (parsed != null) {
        return parsed;
      }
    }

    final rawInt = prefs.getInt('subject_id');
    if (rawInt != null) {
      return rawInt;
    }

    _throwServiceException(
      'No s’ha trobat l’identificador del treballador a la sessió.',
    );
  }

  /// Esborra la sessió guardada i invalida el token memorizat.
  //Future<void> clearStoredSession() async {
  //  final prefs = await SharedPreferences.getInstance();
  //  await prefs.remove('token');
  //  await prefs.remove('access');
  //  await prefs.remove('refresh');
  //  await prefs.remove('session_token');
  //  await prefs.remove('subject_id');
  //  await prefs.remove('tipus');
  //  await prefs.remove('id_empresa');
  //  _validatedToken = null;
  //}

  // ---------------------------------------------------------------------------
  // CONSTRUCCIÓ D'URI I HEADERS
  // ---------------------------------------------------------------------------

  /// Construeix una URI a partir del `baseUrl` i un path relatiu.
  ///
  /// Exemple:
  /// `buildUri('/incidencies/', queryParameters: {'id_obra': '4'})`
  Uri buildUri(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$baseUrl/$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final cleaned = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null && value.trim().isNotEmpty) {
        cleaned[key] = value;
      }
    });

    return uri.replace(
      queryParameters: cleaned.isEmpty ? null : cleaned,
    );
  }

  /// Headers JSON + Bearer comuns a tots els serveis autenticats.
  Map<String, String> authHeaders(String token) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // HELPERS HTTP GENÈRICS
  // ---------------------------------------------------------------------------

  /// GET que espera un objecte JSON.
  Future<Map<String, dynamic>> getJsonMap(
    String path, {
    Map<String, String?>? queryParameters,
    int expectedStatus = 200,
    required String fallback,
    required String invalidResponseMessage,
  }) async {
    final token = await requireAuthenticatedSession();

    final response = await client.get(
      buildUri(path, queryParameters: queryParameters),
      headers: authHeaders(token),
    );

    if (response.statusCode != expectedStatus) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      _throwServiceException(
        extractErrorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return decodeObject(
      response.body,
      fallbackMessage: invalidResponseMessage,
    );
  }

  /// GET que espera una llista JSON.
  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    Map<String, String?>? queryParameters,
    int expectedStatus = 200,
    required String fallback,
    required String invalidResponseMessage,
  }) async {
    final token = await requireAuthenticatedSession();

    final response = await client.get(
      buildUri(path, queryParameters: queryParameters),
      headers: authHeaders(token),
    );

    if (response.statusCode != expectedStatus) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      _throwServiceException(
        extractErrorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return decodeObjectList(
      response.body,
      fallbackMessage: invalidResponseMessage,
    );
  }

  /// POST que envia JSON i espera un objecte JSON.
  Future<Map<String, dynamic>> postJsonMap(
    String path, {
    required Object body,
    Map<String, String?>? queryParameters,
    int expectedStatus = 201,
    required String fallback,
    required String invalidResponseMessage,
  }) async {
    final token = await requireAuthenticatedSession();

    final response = await client.post(
      buildUri(path, queryParameters: queryParameters),
      headers: authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != expectedStatus) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      _throwServiceException(
        extractErrorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return decodeObject(
      response.body,
      fallbackMessage: invalidResponseMessage,
    );
  }

  /// PUT que envia JSON i espera un objecte JSON.
  Future<Map<String, dynamic>> putJsonMap(
    String path, {
    required Object body,
    Map<String, String?>? queryParameters,
    int expectedStatus = 200,
    required String fallback,
    required String invalidResponseMessage,
  }) async {
    final token = await requireAuthenticatedSession();

    final response = await client.put(
      buildUri(path, queryParameters: queryParameters),
      headers: authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != expectedStatus) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      _throwServiceException(
        extractErrorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return decodeObject(
      response.body,
      fallbackMessage: invalidResponseMessage,
    );
  }

  /// Variant de PUT per als casos on el backend pot tornar 200 amb JSON o 204
  /// sense body.
  Future<Map<String, dynamic>?> putJsonMapOrNull(
    String path, {
    required Object body,
    Map<String, String?>? queryParameters,
    int jsonStatus = 200,
    int emptyStatus = 204,
    required String fallback,
    required String invalidResponseMessage,
  }) async {
    final token = await requireAuthenticatedSession();

    final response = await client.put(
      buildUri(path, queryParameters: queryParameters),
      headers: authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == jsonStatus) {
      return decodeObject(
        response.body,
        fallbackMessage: invalidResponseMessage,
      );
    }

    if (response.statusCode == emptyStatus) {
      return null;
    }

    await _handleUnauthorizedIfNeeded(response.statusCode);
    _throwServiceException(
      extractErrorMessage(response, fallback: fallback),
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<Map<String, dynamic>> patchJsonMap(
    String path, {
    required Object body,
    Map<String, String?>? queryParameters,
    int expectedStatus = 200,
    required String fallback,
    required String invalidResponseMessage,
  }) async {
    final token = await requireAuthenticatedSession();

    final response = await client.patch(
      buildUri(path, queryParameters: queryParameters),
      headers: authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != expectedStatus) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      _throwServiceException(
        extractErrorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return decodeObject(
      response.body,
      fallbackMessage: invalidResponseMessage,
    );
  }

  /// DELETE que espera 204 No Content.
  // Future<void> deleteExpectNoContent(
  //   String path, {
  //   Map<String, String?>? queryParameters,
  //   int expectedStatus = 204,
  //   required String fallback,
  // }) async {
  //   final token = await requireAuthenticatedSession();
//
  //   final response = await client.delete(
  //     buildUri(path, queryParameters: queryParameters),
  //     headers: authHeaders(token),
  //   );
//
  //   if (response.statusCode != expectedStatus) {
  //     await _handleUnauthorizedIfNeeded(response.statusCode);
  //     _throwServiceException(
  //       extractErrorMessage(response, fallback: fallback),
  //       statusCode: response.statusCode,
  //       body: response.body,
  //     );
  //   }
  // }

  Future<void> deleteExpectNoContent(
    String path, {
    Map<String, String?>? queryParameters,
    int expectedStatus = 204,
    required String fallback,
  }) async {
    final token = await requireAuthenticatedSession();
    final uri = buildUri(path, queryParameters: queryParameters);
    final headers = authHeaders(token);

    print('DELETE URI: $uri');
    print('TOKEN PRESENT: ${token.trim().isNotEmpty}');
    print('AUTH HEADER PRESENT: ${headers.containsKey('Authorization')}');
    print('AUTH HEADER PREFIX: ${headers['Authorization']?.split(' ').first}');

    final response = await client.delete(
      uri,
      headers: headers,
    );

    print('DELETE STATUS: ${response.statusCode}');
    print('DELETE BODY: ${response.body}');

    if (response.statusCode != expectedStatus) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      _throwServiceException(
        extractErrorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DECODE / ERROR PARSING
  // ---------------------------------------------------------------------------

  /// Converteix el body en `Map<String, dynamic>` o llança excepció.
  Map<String, dynamic> decodeObject(
    String body, {
    required String fallbackMessage,
  }) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    _throwServiceException(fallbackMessage);
  }

  /// Converteix el body en `List<Map<String, dynamic>>` o llança excepció.
  List<Map<String, dynamic>> decodeObjectList(
    String body, {
    required String fallbackMessage,
  }) {
    final decoded = jsonDecode(body);

    if (decoded is! List) {
      _throwServiceException(fallbackMessage);
    }

    return (decoded as List).map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      _throwServiceException(fallbackMessage);
    }).toList();
  }

  /// Intenta extreure el missatge més útil possible de la resposta del backend.
  String extractErrorMessage(
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

        final errors = <String>[];
        decoded.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors.add('$key: ${value.join(' ')}');
          } else if (value is String && value.trim().isNotEmpty) {
            errors.add('$key: ${value.trim()}');
          }
        });

        if (errors.isNotEmpty) {
          return errors.join(' | ');
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

    return '$fallback (${response.statusCode})';
  }

  // ---------------------------------------------------------------------------
  // CICLE DE VIDA
  // ---------------------------------------------------------------------------

  /// Tanca el client només si aquest servei l'ha creat i així s'ha indicat.
  void dispose() {
    if (closeClientOnDispose) {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // MÈTODES PRIVATS
  // ---------------------------------------------------------------------------

  Future<void> _storeSessionContext(
    SharedPreferences prefs,
    String token,
    String body,
  ) async {
    await prefs.setString('token', token);

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final subjectId = decoded['subject_id'];
      if (subjectId != null) {
        await prefs.setString('subject_id', subjectId.toString());
      }

      final tipus = decoded['tipus'];
      if (tipus != null && tipus.toString().trim().isNotEmpty) {
        await prefs.setString('tipus', tipus.toString().trim());
      }

      final idEmpresa = decoded['id_empresa'];
      if (idEmpresa != null) {
        await prefs.setString('id_empresa', idEmpresa.toString());
      }
    } catch (_) {
      // Si /me/ retorna un body inesperat, mantenim almenys el token.
    }
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

  Future<void> _handleUnauthorizedIfNeeded(int statusCode) async {
    if (statusCode == 401 || statusCode == 403) {
      //await clearStoredSession();
    }
  }

  Never _throwServiceException(
    String message, {
    int? statusCode,
    String? body,
  }) {
    if (exceptionFactory != null) {
      throw exceptionFactory!(
        message,
        statusCode: statusCode,
        body: body,
      );
    }

    throw AppApiException(
      message,
      statusCode: statusCode,
      body: body,
    );
  }
}
