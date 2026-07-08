import 'package:http/http.dart' as http;

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/shared/services/app_api_service.dart';

class IncidenciaServiceException implements Exception {
  final String message;
  final int? statusCode;

  const IncidenciaServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class IncidenciaService extends AppApiService {
  IncidenciaService({
    http.Client? client,
  }) : super(
        client: client,
        exceptionFactory: (message, {statusCode, body}) =>
            IncidenciaServiceException(message, statusCode: statusCode),
      );

  Future<IncidenciaProfileData> fetchIncidenciaProfile(int incidenciaId) async {
    final raw = await fetchIncidenciaRaw(incidenciaId);
    return IncidenciaProfileData.fromMap(raw);
  }

  Future<Map<String, dynamic>> fetchIncidenciaRaw(int incidenciaId) async {
    return getJsonMap(
      '/incidencia/$incidenciaId/',
      fallback: 'Error carregant la incidència',
      invalidResponseMessage: 'La resposta de la incidència no és vàlida.',
    );
  }


   /// Crea una nova incidencia.
  /// Per a treballadors: cal passar id_tasca (obligatori al backend).
  /// Per a empreses: id_obra es opcional.
  Future<Map<String, dynamic>> createIncidencia(Map<String, dynamic> payload) {
    return postJsonMap(
      '/incidencies/',
      body: payload,
      expectedStatus: 201,
      fallback: 'Error creant la incidencia',
      invalidResponseMessage: 'La resposta del servidor no es valida.',
    );
  }
  
  Future<Map<String, dynamic>> updateIncidencia(
    int incidenciaId,
    Map<String, dynamic> payload,
  ) async {
    return putJsonMap(
      '/incidencia/$incidenciaId/',
      body: payload,
      fallback: 'Error actualitzant la incidència',
      invalidResponseMessage: 'La resposta d’actualització de la incidència no és vàlida.',
    );
  }

  Future<void> deleteIncidencia(int incidenciaId) async {
    return deleteExpectNoContent(
      '/incidencia/$incidenciaId/',
      fallback: 'Error eliminant la incidència',
    );
  }

   Future<IncidenciaListData> fetchIncidenciesListData({
    int? obraId,
  }) async {
    final rawItems = await fetchIncidenciesRawList(obraId: obraId);

    final incidencies = rawItems
        .map((item) => IncidenciaListItem.fromMap(item))
        .toList();

    final obresMap = <int, String>{};

    for (final item in incidencies) {
      final nom = item.obraNom?.trim();
      obresMap[item.idObra] = (nom == null || nom.isEmpty)
          ? 'Obra #${item.idObra}'
          : nom;
    }

    final obresDisponibles = obresMap.entries
        .map(
          (entry) => IncidenciaObraFilterOption(
            id: entry.key,
            nom: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    return IncidenciaListData(
      incidencies: incidencies,
      obresDisponibles: obresDisponibles,
    );
  }

  Future<List<Map<String, dynamic>>> fetchIncidenciesRawList({
    int? obraId,
  }) async {
    return getJsonList(
      '/incidencies/',
      queryParameters: {
        if (obraId != null) 'id_obra': obraId.toString(),
      },
      fallback: 'Error carregant les incidències',
      invalidResponseMessage: 'La resposta de les incidències no és vàlida.',
    );
  }

    




  // ──────────────────── FORMULARI INCIDÈNCIA / SOLUCIONS ────────────────────

  Future<List<ObraOption>> fetchObresOptions() async {
    final empresaId = await requireEmpresaId();

    final raw = await getJsonList(
      '/obresEmpresa/$empresaId/',
      fallback: 'Error carregant les obres',
      invalidResponseMessage: 'La resposta de les obres no és vàlida.',
    );

    final options = <ObraOption>[];
    for (final item in raw) {
      final obraInfo = item['obra_info'];
      if (obraInfo is Map<String, dynamic>) {
        final id = _asInt(obraInfo['id']);
        if (id != null && id != 0) {
          options.add(
            ObraOption(
              id: id,
              nom: (obraInfo['nom'] ?? 'Obra #$id').toString(),
            ),
          );
        }
      }
    }

    options.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    return options;
  }

  Future<List<TascaOption>> fetchTasquesOptions({int? obraId}) async {
    final raw = await getJsonList(
      '/tasques/',
      queryParameters: {
        if (obraId != null) 'id_obra': obraId.toString(),
      },
      fallback: 'Error carregant les tasques',
      invalidResponseMessage: 'La resposta de les tasques no és vàlida.',
    );

    return raw
        .map(
          (item) => TascaOption(
            id: _asInt(item['id']) ?? 0,
            desc: (item['descripcio'] ?? 'Tasca').toString(),
          ),
        )
        .where((item) => item.id != 0)
        .toList()
      ..sort((a, b) => a.desc.toLowerCase().compareTo(b.desc.toLowerCase()));
  }

  Future<List<IncidenciaSolucioItem>> fetchSolucionsByIncidencia(
    int incidenciaId,
  ) async {
    final raw = await getJsonList(
      '/solucions/',
      queryParameters: {'id_incidencia': incidenciaId.toString()},
      fallback: 'Error carregant les solucions',
      invalidResponseMessage: 'La resposta de les solucions no és vàlida.',
    );

    return raw.map(IncidenciaSolucioItem.fromMap).toList();
  }

  Future<IncidenciaSolucioItem> createSolucio(
    Map<String, dynamic> payload,
  ) async {
    final raw = await postJsonMap(
      '/solucions/',
      body: payload,
      expectedStatus: 201,
      fallback: 'Error creant la solució',
      invalidResponseMessage: 'La resposta de creació de la solució no és vàlida.',
    );

    return IncidenciaSolucioItem.fromMap(raw);
  }

  Future<IncidenciaSolucioItem> updateSolucio(
    int solucioId,
    Map<String, dynamic> payload,
  ) async {
    final raw = await putJsonMap(
      '/solucions/$solucioId/',
      body: payload,
      fallback: 'Error actualitzant la solució',
      invalidResponseMessage:
          'La resposta d’actualització de la solució no és vàlida.',
    );

    return IncidenciaSolucioItem.fromMap(raw);
  }

  Future<void> deleteSolucio(int solucioId) {
    return deleteExpectNoContent(
      '/solucions/$solucioId/',
      fallback: 'Error eliminant la solució',
    );
  }

  Future<void> bulkDeleteSolucions(int incidenciaId) {
    return deleteExpectNoContent(
      '/solucions/$incidenciaId/bulk_delete/',
      fallback: 'Error eliminant les solucions de la incidència',
    );
  }


}


int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
