import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/empresa_models.dart';
import '../../shared/Constants/api_constants.dart';

/// Excepció pròpia per errors d'autenticació.
/// Ens permet distingir errors de sessió d'altres errors genèrics.
class AuthException implements Exception {
  final String message;
  final Map<String, List<String>> fieldErrors;

  AuthException(
    this.message, {
    this.fieldErrors = const {},
  });

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  @override
  String toString() => message;
}

/// Model senzill amb la informació de sessió que ens interessa.
/// Pots afegir-hi més camps si el teu endpoint /me/ retorna més dades útils.
class SessionData {
  final String subjectId;
  final Map<String, dynamic> raw;

  SessionData({
    required this.subjectId,
    required this.raw,
  });
}

/// Servei responsable de:
/// - llegir el token guardat
/// - preparar headers autenticats
/// - validar/carregar la sessió amb /me/
/// - guardar subject_id a SharedPreferences
///
/// IMPORTANT:
/// Aquesta classe NO ha de conèixer la UI.
/// Per tant, aquí no hi ha ni context, ni snackbars, ni setState.
class AuthService {
  final http.Client client;
  String get meUrl => ApiConstants.me;
  String get registerEmpresaUrl => ApiConstants.registerEmpresa;

  AuthService({
    required this.client,
  });

  /// Llegeix el token guardat localment.
  ///
  /// Si no hi ha token o és buit, llancem una AuthException.
  Future<String> getToken() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');

    if (token == null || token.isEmpty) {
      throw AuthException('No hi ha sessió guardada');
    }

    return token;
  }

  /// Construeix els headers estàndard per fer requests autenticades.
  ///
  /// Això evita repetir aquest bloc a tot arreu.
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Crida l'endpoint /me/ per validar que el token encara és vàlid
  /// i recuperar dades bàsiques de l'usuari.
  ///
  /// Si troba subject_id, el guarda per reutilitzar-lo després.
  Future<SessionData> carregarSessio() async {
    final sp = await SharedPreferences.getInstance();

    // Obtenim headers amb token
    final headers = await getAuthHeaders();

    // Fem la crida al backend
    final res = await client.get(
      Uri.parse(meUrl),
      headers: headers,
    );

    // Cas correcte: token vàlid i dades retornades correctament
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // Recuperem el subject_id si existeix
      final subjectId = data['subject_id']?.toString() ?? '';

      if (subjectId.isEmpty) {
        throw AuthException('La sessió és vàlida però falta subject_id');
      }

      // El guardem localment perquè altres serveis el puguin reaprofitar
      await sp.setString('subject_id', subjectId);

      return SessionData(
        subjectId: subjectId,
        raw: data,
      );
    }

    // Cas típic: token expirat o invàlid
    if (res.statusCode == 401) {
      throw AuthException('Sessió expirada o token invàlid');
    }

    // Qualsevol altre error
    throw AuthException('Error carregant sessió (${res.statusCode})');
  }

  Future<EmpresaRegisterResult> registerEmpresa(
    EmpresaRegisterInput input,
  ) async {
    final res = await client.post(
      Uri.parse(registerEmpresaUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(input.toJson()),
    );

    final rawBody = utf8.decode(res.bodyBytes);

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (res.statusCode == 201 && data != null) {
      return EmpresaRegisterResult.fromMap(data);
    }

    final fieldErrors = _extractFieldErrors(data);

    throw AuthException(
      _extractRegisterErrorMessage(
        data,
        rawBody,
        res.statusCode,
      ),
      fieldErrors: fieldErrors,
    );
  }



  //Helpers que ajuden a processar errors de registre i login, per extreure missatges d'error més útils i específics que puguem mostrar a la UI.
  Map<String, List<String>> _extractFieldErrors(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return {};

    final result = <String, List<String>>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is List) {
        final messages = value
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (messages.isNotEmpty) {
          result[key] = messages;
        }
        continue;
      }

      if (value is String && value.trim().isNotEmpty) {
        result[key] = [value.trim()];
      }
    }

    return result;
  }

  String _extractRegisterErrorMessage(
    Map<String, dynamic>? data,
    String rawBody,
    int statusCode,
  ) {
    if (data == null) {
      return 'Error $statusCode: $rawBody';
    }

    final fieldErrors = _extractFieldErrors(data);

    if (fieldErrors.isEmpty) {
      return 'No s\'ha pogut completar el registre.';
    }

    const preferredOrder = [
      'email',
      'cif',
      'password',
      'password_confirm',
      'nom_empresa',
      'non_field_errors',
      'detail',
    ];

    for (final key in preferredOrder) {
      final messages = fieldErrors[key];
      if (messages != null && messages.isNotEmpty) {
        return messages.first;
      }
    }

    final firstEntry = fieldErrors.entries.first;
    return firstEntry.value.first;
  }
}
