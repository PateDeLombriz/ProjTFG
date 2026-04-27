import 'package:http/http.dart' as http;

import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/shared/services/app_api_service.dart';

class SolRecursServiceException implements Exception {
  final String message;
  final int? statusCode;

  const SolRecursServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SolRecursService extends AppApiService {
  SolRecursService({
    String? baseUrl,
    http.Client? client,
  }) : super(
         baseUrl: baseUrl,
         client: client,
       );

  /// Converteix les excepcions genèriques de [AppApiService]
  /// en l'excepció pròpia del domini de sol·licituds de recursos.
  Future<T> _runMapped<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppApiException catch (e) {
      throw SolRecursServiceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  // =========================
  // LLISTA / DETALL
  // =========================

  /// Retorna la llista de sol·licituds de recursos visibles per a l’empresa.
  /// El backend ja filtra pel context autenticat i admet id_obra i id_recurs.
  Future<SolRecursListData> fetchSolRecursData({
    int? obraId,
    int? recursId,
  }) async {
    final raw = await fetchSolRecursRaw(
      obraId: obraId,
      recursId: recursId,
    );
    return SolRecursListData.fromList(raw);
  }

  /// Variant convenient que retorna només la llista tipada.
  Future<List<SolRecurs>> fetchSolRecurs({
    int? obraId,
    int? recursId,
  }) async {
    final data = await fetchSolRecursData(
      obraId: obraId,
      recursId: recursId,
    );
    return data.sollicituds;
  }

  /// Llegeix les sol·licituds de recursos de l’empresa activa de la sessió.
  /// La comprovació d'empresa es resol amb el mètode heretat del servei compartit.
  Future<SolRecursListData> fetchMyEmpresaSolRecursData({
    int? obraId,
    int? recursId,
  }) async {
    await requireEmpresaId();
    return fetchSolRecursData(
      obraId: obraId,
      recursId: recursId,
    );
  }

  /// Retorna el detall tipat d’una sol·licitud concreta.
  Future<SolRecurs> fetchSolRecursDetail(int solRecursId) async {
    final raw = await fetchSolRecursDetailRaw(solRecursId);
    return SolRecurs.fromMap(raw);
  }

  Future<List<Map<String, dynamic>>> fetchSolRecursRaw({
    int? obraId,
    int? recursId,
  }) {
    return _runMapped(
      () => getJsonList(
        '/sol_recurs/',
        queryParameters: {
          if (obraId != null) 'id_obra': obraId.toString(),
          if (recursId != null) 'id_recurs': recursId.toString(),
        },
        fallback: 'Error carregant les sol·licituds de recursos',
        invalidResponseMessage:
            'La resposta de les sol·licituds de recursos no és vàlida.',
      ),
    );
  }

  Future<Map<String, dynamic>> fetchSolRecursDetailRaw(int solRecursId) {
    return _runMapped(
      () => getJsonMap(
        '/sol_recurs/$solRecursId/',
        fallback: 'Error carregant el detall de la sol·licitud',
        invalidResponseMessage:
            'La resposta del detall de la sol·licitud no és vàlida.',
      ),
    );
  }

  Future<List<SolRecurs>> fetchSolRecursByObra(int obraId) {
    return fetchSolRecurs(obraId: obraId);
  }

  Future<List<SolRecurs>> fetchSolRecursByRecurs(int recursId) {
    return fetchSolRecurs(recursId: recursId);
  }

  // =========================
  // CREACIÓ / EDICIÓ / ELIMINACIÓ
  // =========================

  /// Crea una nova sol·licitud de recurs.
  /// Si el payload no inclou id_empresa, s’injecta des de la sessió.
  Future<SolRecurs> createSolRecurs(Map<String, dynamic> payload) async {
    final normalizedPayload = Map<String, dynamic>.from(payload);
    normalizedPayload['id_empresa'] ??= await requireEmpresaId();

    final raw = await _runMapped(
      () => postJsonMap(
        '/sol_recurs/',
        body: normalizedPayload,
        expectedStatus: 201,
        fallback: 'Error creant la sol·licitud de recurs',
        invalidResponseMessage:
            'La resposta de creació de la sol·licitud no és vàlida.',
      ),
    );

    return SolRecurs.fromMap(raw);
  }

  Future<SolRecurs> createSolRecursFromModel(SolRecurs sollicitud) {
    return createSolRecurs(sollicitud.toMap());
  }

  /// Actualitza completament una sol·licitud concreta.
  Future<SolRecurs> updateSolRecurs(
    int solRecursId,
    Map<String, dynamic> payload,
  ) async {
    final normalizedPayload = Map<String, dynamic>.from(payload);
    normalizedPayload['id_empresa'] ??= await requireEmpresaId();

    final raw = await _runMapped(
      () => putJsonMap(
        '/sol_recurs/$solRecursId/',
        body: normalizedPayload,
        fallback: 'Error actualitzant la sol·licitud de recurs',
        invalidResponseMessage:
            'La resposta d’actualització de la sol·licitud no és vàlida.',
      ),
    );

    return SolRecurs.fromMap(raw);
  }

  Future<SolRecurs> updateSolRecursFromModel(SolRecurs sollicitud) {
    return updateSolRecurs(sollicitud.id, sollicitud.toMap());
  }

  Future<void> deleteSolRecurs(int solRecursId) {
    return _runMapped(
      () => deleteExpectNoContent(
        '/sol_recurs/$solRecursId/',
        fallback: 'Error eliminant la sol·licitud de recurs',
      ),
    );
  }
}