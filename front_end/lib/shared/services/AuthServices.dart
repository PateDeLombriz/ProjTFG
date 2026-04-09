import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Excepció pròpia per errors d'autenticació.
/// Ens permet distingir errors de sessió d'altres errors genèrics.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

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
  final String baseUrl;
  final http.Client client;

  AuthService({
    required this.baseUrl,
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
      Uri.parse('$baseUrl/me/'),
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
}