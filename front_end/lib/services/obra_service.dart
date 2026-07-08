import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/services/app_api_service.dart';

class ObraServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const ObraServiceException(
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

/// Servei del domini Obra.
///
/// IMPORTANT:
/// - Aquesta classe hereta la infraestructura comuna d'AppApiService.
/// - Aquí només queda la lògica específica del domini obra.
/// - Qualsevol AppApiException es transforma a ObraServiceException
///   per no rompre el codi que ja captura excepcions d'obra.
class ObraService extends AppApiService {
  ObraService({
    String? baseUrl,
    http.Client? client,
  }) : super(
          baseUrl: baseUrl,
          client: client,
          closeClientOnDispose: client == null,
        );

  /// Manté compatibilitat amb el codi existent.
  @override
  void dispose() {
    super.dispose();
  }

  /// Assegura que hi ha una sessió vàlida.
  Future<void> ensureAuthenticatedSession() async {
    try {
      await requireAuthenticatedSession();
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  /// Retorna el perfil agregat d'una obra.
  Future<ObraProfileData> fetchObraProfile(int obraId) async {
    final raw = await fetchObraRaw(obraId);
    return ObraProfileData.fromMap(raw);
  }

  /// Retorna el detall cru d'una obra.
  Future<Map<String, dynamic>> fetchObraRaw(int obraId) async {
    try {
      return await getJsonMap(
        '/obres/$obraId/',
        fallback: 'Error carregant l’obra',
        invalidResponseMessage: 'La resposta de l’obra no és vàlida.',
      );
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  /// Retorna la llista de relacions obra-empresa d'una empresa.
  Future<List<Map<String, dynamic>>> fetchObresEmpresa(int empresaId) async {
    try {
      return await getJsonList(
        '/obresEmpresa/$empresaId/',
        fallback: 'Error carregant les obres de l’empresa',
        invalidResponseMessage: 'La resposta de les obres no és vàlida.',
      );
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  /// Resol l'empresa activa des de la sessió i en retorna les obres.
  Future<List<Map<String, dynamic>>> fetchMyEmpresaObres() async {
    try {
      final empresaId = await requireEmpresaId();
      return await fetchObresEmpresa(empresaId);
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  /// Elimina una obra concreta.
  Future<void> deleteObra(int obraId) async {
    try {
      await deleteExpectNoContent(
        '/obres/$obraId/',
        fallback: 'Error eliminant l’obra',
      );
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  /// Carrega ubicacions conegudes per id.
  ///
  /// Aquest mètode es manté específic perquè fa múltiples GET manuals
  /// i transforma cada resultat a ObraUbicacioInfo.
  Future<List<ObraUbicacioInfo>> fetchUbicacions({
    List<int> knownIds = const [],
  }) async {
    try {
      if (knownIds.isEmpty) {
        return const <ObraUbicacioInfo>[];
      }

      final token = await requireAuthenticatedSession();
      final uniqueIds = <int>{...knownIds};
      final results = <ObraUbicacioInfo>[];

      for (final id in uniqueIds) {
        final response = await client.get(
          buildUri('/ubicacio/$id/'),
          headers: authHeaders(token),
        );

        if (response.statusCode == 200) {
          final json = decodeObject(
            response.body,
            fallbackMessage: 'La ubicació rebuda no és vàlida.',
          );
          results.add(ObraUbicacioInfo.fromJson(json));
          continue;
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
    
          throw ObraServiceException(
            extractErrorMessage(
              response,
              fallback: 'No s’han pogut carregar les ubicacions.',
            ),
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      }

      return results;
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

    Future<ObraUbicacioInfo> createUbicacio(
    ObraUbicacioInfo ubicacio,
  ) async {
    try {
      final json = await postJsonMap(
        '/ubicacio/',
        body: _ubicacioCreatePayload(ubicacio),
        expectedStatus: 201,
        fallback: 'No s’ha pogut crear la ubicació.',
        invalidResponseMessage:
            'La resposta de creació de la ubicació no és vàlida.',
      );

      return ObraUbicacioInfo.fromJson(json);
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  Future<ObraUbicacioInfo> ensureUbicacioPersistida(
    ObraUbicacioInfo ubicacio,
  ) async {
    if (ubicacio.idUbicacio > 0) {
      return ubicacio;
    }

    return createUbicacio(ubicacio);
  }

  Future<Obra> createObra(
    ObraCreateRequest request,
  ) async {
    try {
      final json = await postJsonMap(
        '/obres/',
        body: request.toJson(),
        expectedStatus: 201,
        fallback: 'No s’ha pogut crear l’obra.',
        invalidResponseMessage:
            'La resposta de creació de l’obra no és vàlida.',
      );

      return Obra.fromMap(json);
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  Future<ObraCreateResult> createObraEmpresa({
    required int obraId,
    int? empresaId,
    DateTime? dataIniciRelacio,
  }) async {
    try {
      final resolvedEmpresaId = empresaId ?? await requireEmpresaId();

      final json = await postJsonMap(
        '/obresEmpresa/$resolvedEmpresaId/',
        body: <String, dynamic>{
          'id_obra': obraId,
          'data_i': (dataIniciRelacio ?? DateTime.now())
              .toUtc()
              .toIso8601String(),
        },
        expectedStatus: 201,
        fallback: 'No s’ha pogut vincular l’obra a l’empresa.',
        invalidResponseMessage:
            'La resposta de creació de la relació obra-empresa no és vàlida.',
      );

      return ObraCreateResult(
        obraId: obraId,
        relacioId: _asIntOrNull(json['id']),
      );
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  Future<ObraCreateResult> createObraAmbUbicacio({
    required ObraCreateRequest request,
    required ObraUbicacioInfo ubicacio,
    int? empresaId,
  }) async {
    final ubicacioPersistida = await ensureUbicacioPersistida(ubicacio);

    final obra = await createObra(
      request.copyWith(
        ubicacioId: ubicacioPersistida.idUbicacio,
      ),
    );

    final relacio = await createObraEmpresa(
      obraId: obra.id,
      empresaId: empresaId,
      dataIniciRelacio: DateTime.now(),
    );

    return ObraCreateResult(
      ubicacioId: ubicacioPersistida.idUbicacio,
      obraId: obra.id,
      relacioId: relacio.relacioId,
    );
  }

  Map<String, dynamic> _ubicacioCreatePayload(
    ObraUbicacioInfo ubicacio,
  ) {
    return <String, dynamic>{
      'adreca': _cleanNullableText(ubicacio.adreca),
      'ciutat': _cleanNullableText(ubicacio.ciutat),
      'codi_postal': _cleanNullableText(ubicacio.codiPostal),
      'provincia': _cleanNullableText(ubicacio.provincia),
      'pais': _cleanNullableText(ubicacio.pais) ?? 'Espanya',
      'latitud': ubicacio.latitud,
      'longitud': ubicacio.longitud,
    };
  }

  String? _cleanNullableText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  /// Actualitza una obra.
  ///
  /// Manté el contracte antic:
  /// - 200 -> retorna Map
  /// - 204 -> retorna null
  Future<Map<String, dynamic>?> updateObra({
    required int obraId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await requireAuthenticatedSession();

      final response = await client.put(
        buildUri('/obres/$obraId/'),
        headers: authHeaders(token),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return decodeObject(
          response.body,
          fallbackMessage:
              'La resposta d’actualització de l’obra no és vàlida.',
        );
      }

      if (response.statusCode == 204) {
        return null;
      }


      throw ObraServiceException(
        extractErrorMessage(
          response,
          fallback: 'No s’ha pogut actualitzar l’obra.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    } on AppApiException catch (e) {
      throw _mapAppApiException(e);
    }
  }

  /// Converteix una excepció comuna de la capa base en una excepció pròpia
  /// del domini d'obra.
  ObraServiceException _mapAppApiException(AppApiException e) {
    return ObraServiceException(
      e.message,
      statusCode: e.statusCode,
      body: e.body,
    );
  }

  /// Intenta extreure `id` o `id_obra` del request sense forçar un contracte
  /// massa rígid amb el model Dart.
  ///
  /// Això evita assumir que ObraCreateRequest tengui exactament un mètode
  /// concret mentre manté compatibilitat amb implementacions habituals.
  int? _extractObraIdFromRequest(ObraCreateRequest request) {
    final dynamic rawRequest = request;

    dynamic rawId;

    try {
      rawId = rawRequest.id;
    } catch (_) {}

    if (rawId == null) {
      try {
        rawId = rawRequest.idObra;
      } catch (_) {}
    }

    if (rawId == null) {
      try {
        rawId = rawRequest.id_obra;
      } catch (_) {}
    }

    if (rawId == null) {
      try {
        final dynamic json = rawRequest.toJson();
        if (json is Map) {
          rawId = json['id'] ?? json['id_obra'];
        }
      } catch (_) {}
    }

    if (rawId is int) {
      return rawId;
    }

    if (rawId is String) {
      return int.tryParse(rawId.trim());
    }

    return null;
  }
}

