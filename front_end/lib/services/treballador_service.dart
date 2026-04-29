import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/shared/services/app_api_service.dart';

class TreballadorServiceException implements Exception {
  final String message;
  final int? statusCode;

  const TreballadorServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class TreballadorService extends AppApiService {
  TreballadorService({
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
      throw TreballadorServiceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  // =========================
  // PERFIL TREBALLADOR
  // =========================

  /// Perfil propi del treballador autenticat.
  /// Resol l'id des de la sessió i crida /treballadors/profile/<id>/
  Future<TreballadorProfileData> fetchMyProfile() async {
    final treballadorId = await _runMapped(() => requireTreballadorId());
    return fetchTreballadorProfile(treballadorId);
  }

  /// Retorna el perfil resumit d'un treballador per a ús visual.
  /// A diferència de fetchTreballadorDetail(), aquest mètode està orientat
  /// a capçalera, resum i mètriques, no a informació administrativa completa.
  Future<TreballadorProfileData> fetchTreballadorProfile(
    int treballadorId,
  ) async {
    final raw = await fetchTreballadorProfileRaw(treballadorId);
    return TreballadorProfileData.fromMap(raw);
  }

  Future<Map<String, dynamic>> fetchTreballadorProfileRaw(
    int treballadorId,
  ) {
    return _runMapped(
      () => getJsonMap(
        '/treballadors/profile/$treballadorId/',
        fallback: 'Error carregant el perfil del treballador',
        invalidResponseMessage:
            'La resposta del perfil del treballador no és vàlida.',
      ),
    );
  }

  /// Retorna el detall d'un treballador concret, perquè l'empresa pugui veure
  /// informació interna que el treballador no ha de saber.
  /// A diferència de fetchTreballadorProfile(), aquest mètode prioritza dades
  /// com contractes i informació interna, no el resum visual del perfil.
  Future<Map<String, dynamic>> fetchTreballadorDetail(int treballadorId) {
    return _runMapped(
      () => getJsonMap(
        '/treballadors/$treballadorId/',
        fallback: 'Error carregant el detall del treballador',
        invalidResponseMessage:
            'La resposta del detall del treballador no és vàlida.',
      ),
    );
  }

  /// Retorna les tasques detallades assignades a un treballador.
  /// A diferència d'un llistat d'assignacions com tasca_treballador,
  /// aquí cada element ja ve enriquit amb dades de tasca, obra i relacions.
  Future<List<Map<String, dynamic>>> fetchTreballadorTasques(
    int treballadorId,
  ) {
    return _runMapped(
      () => getJsonList(
        '/treballadors/$treballadorId/tasques/',
        fallback: 'Error carregant les tasques del treballador',
        invalidResponseMessage:
            'La resposta de les tasques del treballador no és vàlida.',
      ),
    );
  }

  /// Retorna les obres on el treballador ha participat.
  /// A diferència de fetchTreballadorTasques(), aquest mètode agrupa per obra
  /// i dona una visió resumida de participació, no el detall de cada tasca.
  Future<List<Map<String, dynamic>>> fetchTreballadorObresParticipades(
    int treballadorId,
  ) {
    return _runMapped(
      () => getJsonList(
        '/treballadors/$treballadorId/obres_participades/',
        fallback: 'Error carregant les obres participades del treballador',
        invalidResponseMessage:
            'La resposta de les obres participades no és vàlida.',
      ),
    );
  }

   Future<List<Map<String, dynamic>>> fetchMyTasques() {
    return _runMapped(
      () => getJsonList(
        '/treballadors/me/tasques/',
        fallback: 'Error carregant les teves tasques',
        invalidResponseMessage: 'La resposta de les tasques no és vàlida.',
      ),
    );
  }

  /// Obres on participa el treballador autenticat.
  /// Crida /treballadors/me/obres_participades/.
  Future<List<Map<String, dynamic>>> fetchMyObresParticipades() {
    return _runMapped(
      () => getJsonList(
        '/treballadors/me/obres_participades/',
        fallback: 'Error carregant les teves obres',
        invalidResponseMessage: 'La resposta de les obres no és vàlida.',
      ),
    );
  }

  /// Historial de registre horari del treballador autenticat.
  Future<List<Map<String, dynamic>>> fetchMyRegistreHorari() {
    return _runMapped(
      () => getJsonList(
        '/treballadors/me/registre_horari/',
        fallback: 'Error carregant el registre horari',
        invalidResponseMessage: 'La resposta del registre horari no és vàlida.',
      ),
    );
  }

  /// Ficha entrada (POST /treballadors/me/registre_horari/).
  /// [idObra] es opcional; si es null no s'envia.
  Future<Map<String, dynamic>> fitxarEntrada({int? idObra}) {
    final body = <String, dynamic>{};
    if (idObra != null) body['id_obra'] = idObra;

    return _runMapped(
      () => postJsonMap(
        '/treballadors/me/registre_horari/',
        body: body,
        expectedStatus: 201,
        fallback: 'Error en fichar entrada',
        invalidResponseMessage: 'La resposta del servidor no és vàlida.',
      ),
    );
  }

  /// Ficha sortida (PATCH /treballadors/me/registre_horari/).
  /// Tanca l'entrada oberta mes recent.
  Future<Map<String, dynamic>> fitxarSortida() {
    return _runMapped(
      () => patchJsonMap(
        '/treballadors/me/registre_horari/',
        body: {},
        expectedStatus: 200,
        fallback: 'Error en fichar sortida',
        invalidResponseMessage: 'La resposta del servidor no és vàlida.',
      ),
    );
  }

  /// Marca una tasca com a finalitzada pendent de revisio.
  /// PATCH /treballadors/me/tasques/<tascaId>/finalitzar/
  /// Comprova al backend que la tasca esta assignada al treballador autenticat.
  Future<Map<String, dynamic>> finalitzarTasca(int tascaId) {
    return _runMapped(
      () => patchJsonMap(
        '/treballadors/me/tasques/$tascaId/finalitzar/',
        body: {},
        expectedStatus: 200,
        fallback: 'Error en finalitzar la tasca',
        invalidResponseMessage: 'La resposta del servidor no és vàlida.',
      ),
    );
  }


  // =========================
  // TREBALLADORS EMPRESA
  // =========================

  Future<TreballadorListData> fetchTreballadorsEmpresaData(
    int empresaId,
  ) async {
    final raw = await fetchTreballadorsEmpresaRaw(empresaId);
    return TreballadorListData.fromEmpresaDetailMap(raw);
  }

  Future<List<TreballadorListItem>> fetchTreballadorsEmpresa(
    int empresaId,
  ) async {
    final data = await fetchTreballadorsEmpresaData(empresaId);
    return data.treballadors;
  }

  Future<TreballadorListData> fetchMyEmpresaTreballadorsData() async {
    final empresaId = await _runMapped(() => requireEmpresaId());
    return fetchTreballadorsEmpresaData(empresaId);
  }

  /// Obtiene los treballadors de la empresa.
  /// Aquest mètode es manté propi perquè la resposta es normalitza tant si
  /// el backend torna un Map com si torna directament una List.
  Future<Map<String, dynamic>> fetchTreballadorsEmpresaRaw(
    int empresaId,
  ) async {
    try {
      final token = await requireAuthenticatedSession();

      final primaryResponse = await client.get(
        buildUri('/treballadors/empresa/$empresaId/'),
        headers: authHeaders(token),
      );

      if (primaryResponse.statusCode == 200) {
        return _decodeTreballadorsEmpresaResponse(
          primaryResponse.body,
          empresaId: empresaId,
        );
      }

      if (primaryResponse.statusCode == 401 ||
          primaryResponse.statusCode == 403) {
        await clearStoredSession();
        throw TreballadorServiceException(
          extractErrorMessage(
            primaryResponse,
            fallback: 'No tens permís per carregar els treballadors de l’empresa',
          ),
          statusCode: primaryResponse.statusCode,
        );
      }

      throw TreballadorServiceException(
        extractErrorMessage(
          primaryResponse,
          fallback: 'Error carregant els treballadors de l\'empresa',
        ),
        statusCode: primaryResponse.statusCode,
      );
    } on AppApiException catch (e) {
      throw TreballadorServiceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Map<String, dynamic> _decodeTreballadorsEmpresaResponse(
    String body, {
    required int empresaId,
  }) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      final treballadors = _extractTreballadorsList(decoded['treballadors']);
      final normalizedTreballadors = treballadors
          .map(_normalizeTreballadorEmpresaItem)
          .toList();

      final result = Map<String, dynamic>.from(decoded);
      result['id'] = result['id'] ?? empresaId;
      result['treballadors'] = normalizedTreballadors;
      return result;
    }

    if (decoded is List) {
      final normalizedTreballadors = decoded
          .whereType<Object?>()
          .map(
            (item) => item is Map
                ? _normalizeTreballadorEmpresaItem(
                    Map<String, dynamic>.from(item),
                  )
                : <String, dynamic>{},
          )
          .toList();

      return <String, dynamic>{
        'id': empresaId,
        'nom_empresa': null,
        'treballadors': normalizedTreballadors,
      };
    }

    throw const TreballadorServiceException(
      'La resposta de treballadors no és vàlida.',
    );
  }

  // =========================
  // NORMALITZACIÓ TREBALLADORS EMPRESA
  // =========================

  List<Map<String, dynamic>> _extractTreballadorsList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .map(
          (item) => item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{},
        )
        .toList();
  }

  Map<String, dynamic> _normalizeTreballadorEmpresaItem(
    Map<String, dynamic> raw,
  ) {
    final normalized = Map<String, dynamic>.from(raw);

    normalized['id'] =
        _asIntOrNull(normalized['id'] ?? normalized['id_treballador']) ?? 0;
    normalized['nom'] = _asString(normalized['nom']) ?? 'Treballador';
    normalized['cognoms'] = _asNullableString(normalized['cognoms']);
    normalized['nickname'] = _asNullableString(normalized['nickname']);
    normalized['email'] = _asNullableString(normalized['email']);
    normalized['telefon'] = _asNullableString(normalized['telefon']);
    normalized['comentaris'] = _asNullableString(normalized['comentaris']);

    final contractes = _normalizeContractes(normalized['contractes']);
    normalized['contractes'] = contractes;

    normalized['carrec'] =
        _asNullableString(normalized['carrec']) ??
        _extractCarrecFromContractes(contractes);

    normalized['estat'] =
        _asNullableString(normalized['estat']) ??
        _extractEstatFromContractes(contractes);

    final fotoRaw = _asNullableString(
      normalized['foto_url'] ?? normalized['foto'],
    );
    normalized['foto'] = fotoRaw;
    normalized['foto_url'] = _buildAbsoluteUrlIfNeeded(fotoRaw);

    return normalized;
  }

  List<Map<String, dynamic>> _normalizeContractes(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .map(
          (item) => item is Map
              ? Map<String, dynamic>.from(item).map(
                  (key, val) => MapEntry(key.toString(), val),
                )
              : <String, dynamic>{},
        )
        .toList();
  }

  String? _extractCarrecFromContractes(List<Map<String, dynamic>> contractes) {
    if (contractes.isEmpty) return null;

    for (final contracte in contractes) {
      final estat = _asNullableString(contracte['estat'])?.toLowerCase();
      final carrec = _asNullableString(contracte['carrec']);

      if (estat == 'actiu' && carrec != null && carrec.isNotEmpty) {
        return carrec;
      }
    }

    return _asNullableString(contractes.first['carrec']);
  }

  String? _extractEstatFromContractes(List<Map<String, dynamic>> contractes) {
    if (contractes.isEmpty) return null;

    for (final contracte in contractes) {
      final estat = _asNullableString(contracte['estat']);
      if (estat != null && estat.isNotEmpty) {
        return estat;
      }
    }

    return null;
  }

  String? _buildAbsoluteUrlIfNeeded(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    try {
      final uri = Uri.parse(baseUrl);
      final baseOrigin =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

      if (value.startsWith('/')) {
        return '$baseOrigin$value';
      }

      return '$baseOrigin/$value';
    } catch (_) {
      return value;
    }
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _asNullableString(dynamic value) => _asString(value);

  int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }
}