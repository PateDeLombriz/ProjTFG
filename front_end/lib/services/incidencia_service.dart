import 'package:http/http.dart' as http;

import 'package:front_end/models/incidencia_models.dart';
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

    


}