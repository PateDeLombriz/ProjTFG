import 'package:front_end/services/treballador_service.dart';
import 'package:http/http.dart' as http;

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/shared/services/app_api_service.dart';


class TascaServiceException implements Exception {
  final String message;
  final int? statusCode;

  const TascaServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class TascaService extends AppApiService {
  TascaService({
    String? baseUrl,
    http.Client? client,
  }) : super(
          baseUrl: baseUrl,
          client: client,
        );

  Future<T> _runMapped<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppApiException catch (e) {
      throw TascaServiceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  // ──────────────────── TASCA DETAIL / PROFILE ────────────────────

  Future<TascaProfileData> fetchTascaProfile(int tascaId) async {
    final raw = await fetchTascaRaw(tascaId);
    return TascaProfileData.fromMap(raw);
  }

  Future<Map<String, dynamic>> fetchTascaDetail(int tascaId) {
    return fetchTascaRaw(tascaId);
  }

  Future<Map<String, dynamic>> fetchTascaRaw(int tascaId) {
    return _runMapped(
      () => getJsonMap(
        '/tasca/$tascaId/',
        fallback: 'Error carregant la tasca',
        invalidResponseMessage: 'La resposta de la tasca no és vàlida.',
      ),
    );
  }

  Future<Map<String, dynamic>> fetchTascaTreballadorsRaw(int tascaId) {
    return _runMapped(
      () => getJsonMap(
        '/tasca_treballador/$tascaId/',
        fallback: 'Error carregant la tasca',
        invalidResponseMessage: 'La resposta de la tasca no és vàlida.',
      ),
    );
   
  }
   Future<TascaProfileData> fetchTascaTreballadorProfile(int tascaId) async {
    final raw = await fetchTascaTreballadorsRaw(tascaId);
    return TascaProfileData.fromMap(raw);
  }

  // ──────────────────── LLISTAT ────────────────────

  Future<List<Map<String, dynamic>>> fetchTasques({int? obraId}) {
    return _runMapped(
      () => getJsonList(
        '/tasques/',
        queryParameters: {
          if (obraId != null) 'id_obra': obraId.toString(),
        },
        fallback: 'Error carregant les tasques',
        invalidResponseMessage: 'La resposta de les tasques no és vàlida.',
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchTasquesByObra(int obraId) {
    return fetchTasques(obraId: obraId);
  }

  Future<List<TascaOption>> fetchTasquesPerObra(int obraId) async {
    final list = await fetchTasques(obraId: obraId);

    return list
        .map(
          (e) => TascaOption(
            id: _asInt(e['id']) ?? 0,
            desc: (e['descripcio'] ?? '').toString(),
          ),
        )
        .toList();
  }

  // ──────────────────── FORM OPTIONS ────────────────────

  Future<List<ObraOption>> fetchObres() async {
    int idEmpresa = await requireEmpresaId();
  if (idEmpresa == null) {
    throw const TascaServiceException(
      'No s’ha pogut carregar les obres: falta id_empresa.',
    );
  }

  return _runMapped(() async {
    final list = await getJsonList(
      '/obresEmpresa/$idEmpresa/',
      fallback: 'Error carregant les obres',
      invalidResponseMessage: 'La resposta de les obres no és vàlida.',
    );

    return list
        .map((e) {
          final obraInfo = e['obra_info'] as Map<String, dynamic>?;

          return ObraOption(
            id: _asInt(obraInfo?['id']) ?? 0,
            nom: (obraInfo?['nom'] ?? '—').toString(),
          );
        })
        .where((obra) => obra.id != 0)
        .toList();
  });
}

  Future<List<UsuariOption>> fetchTreballadors() {
  return _runMapped(() async {
    final idEmpresa = await requireEmpresaId();

    final treballadorService = TreballadorService(
      baseUrl: baseUrl,
      client: client,
    );

    final treballadors = await treballadorService.fetchTreballadorsEmpresa(idEmpresa);

    return treballadors
        .map(
          (t) => UsuariOption(
            id: t.id,
            nom: t.nom,
            cognoms: t.cognoms ?? '',
          ),
        )
        .where((u) => u.id != 0)
        .toList();
  });
}

  Future<List<UsuariOption>> fetchTreballadorsDeTasca(int tascaId) async {
    final assignacions = await fetchAssignacionsTasca(tascaId);

    return assignacions
        .map(
          (e) => UsuariOption(
            id: _asInt(e['id_treballador']) ?? 0,
            nom: (e['treballador_nom'] ?? 'Treballador').toString(),
            cognoms: (e['treballador_cognoms'] ?? '').toString(),
          ),
        )
        .toList();
  }

  // ──────────────────── CREATE / UPDATE / DELETE ────────────────────

  Future<Map<String, dynamic>> createTasca(Map<String, dynamic> payload) {
    return _runMapped(
      () => postJsonMap(
        '/tasques/',
        body: payload,
        expectedStatus: 201,
        fallback: 'Error creant la tasca',
        invalidResponseMessage:
            'La resposta de creació de la tasca no és vàlida.',
      ),
    );
  }

  Future<int> createTascaAndReturnId(Map<String, dynamic> payload) async {
    final map = await createTasca(payload);
    return _asInt(map['id']) ?? 0;
  }

  Future<void> updateTasca(int tascaId, Map<String, dynamic> payload) {
    return _runMapped(
      () => putJsonMap(
        '/tasca/$tascaId/',
        body: payload,
        expectedStatus: 200,
        fallback: 'Error actualitzant la tasca',
        invalidResponseMessage:
            'La resposta d’actualització de la tasca no és vàlida.',
      ).then((_) => null),
    );
  }

  Future<void> deleteTasca(int tascaId) {
    return _runMapped(
      () => deleteExpectNoContent(
        '/tasca/$tascaId/',
        fallback: 'Error eliminant la tasca',
      ),
    );
  }

  // ──────────────────── ASSIGNACIONS ────────────────────

  Future<List<Map<String, dynamic>>> fetchAssignacionsTasca(int tascaId) {
    return _runMapped(
      () => getJsonList(
        '/tasca_treballador/',
        queryParameters: {
          'id_tasca': tascaId.toString(),
        },
        fallback: 'Error carregant les assignacions de la tasca',
        invalidResponseMessage:
            'La resposta de les assignacions de la tasca no és vàlida.',
      ),
    );
  }

  Future<void> deleteAssignacionsTasca(int tascaId) {
    return _runMapped(
      () => deleteExpectNoContent(
        '/tasca_treballador/$tascaId/bulk_delete/',
        fallback: 'Error eliminant les assignacions de la tasca',
      ),
    );
  }

  Future<void> createAssignacionsTasca(
  int tascaId,
  List<UsuariOption> treballadors,
) async {
  for (final usuari in treballadors) {
    if (usuari.id == 0) continue;

    await assignarTreballador(
      tascaId: tascaId,
      treballadorId: usuari.id,
    );
  }
}

  Future<void> assignarTreballador({
    required int tascaId,
    required int treballadorId,
    String? comentari,
  }) {
    return _runMapped(
      () => postJsonMap(
        '/tasca_treballador/',
        body: {
          'id_tasca': tascaId,
          'id_treballador': treballadorId,
          'comentari': comentari,
        },
        expectedStatus: 201,
        fallback: 'Error assignant el treballador a la tasca',
        invalidResponseMessage:
            'La resposta de l’assignació del treballador no és vàlida.',
      ).then((_) => null),
    );
  }

 Future<void> syncTreballadors(
  int tascaId,
  List<UsuariOption> treballadors,
) async {
  await deleteAssignacionsTasca(tascaId);
  await createAssignacionsTasca(tascaId, treballadors);
}
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}