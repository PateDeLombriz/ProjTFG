class Tasca {
  final int id;
  final int obraId;
  final int? tascaPareId;
  final String descripcio;
  final DateTime? dataInici;
  final DateTime? dataFi;
  final int? prioritat;
  final bool visibilitatTasca;

  const Tasca({
    required this.id,
    required this.obraId,
    required this.tascaPareId,
    required this.descripcio,
    required this.dataInici,
    required this.dataFi,
    required this.prioritat,
    required this.visibilitatTasca,
  });

  factory Tasca.fromMap(Map<String, dynamic> map) {
    return Tasca(
      id: _asInt(map['id']) ?? 0,
      obraId: _asInt(map['id_obra'] ?? map['obraId']) ?? 0,
      tascaPareId: _asInt(map['id_tasca_pare'] ?? map['tascaPareId']),
      descripcio: _asString(map['descripcio']) ?? '',
      dataInici: _asDate(map['data_inici'] ?? map['dataInici']),
      dataFi: _asDate(map['data_fi'] ?? map['dataFi']),
      prioritat: _asInt(map['prioritat']),
      visibilitatTasca:
          _asBool(map['visibilitat_tasca'] ?? map['visibilitatTasca']) ?? true,
    );
  }

  factory Tasca.fromJson(Map<String, dynamic> json) => Tasca.fromMap(json);

  /// Compatibilitat amb pantalles antigues que feien servir `idObra`.
  int get idObra => obraId;

  /// Compatibilitat amb pantalles antigues que feien servir `idTascaPare`.
  int? get idTascaPare => tascaPareId;

  /// Compatibilitat amb pantalles antigues que feien servir `visibilitat`.
  bool get visibilitat => visibilitatTasca;

  String get descripcioCurta {
    final text = descripcio.trim();
    if (text.isEmpty) return 'Sense descripció';
    if (text.length <= 120) return text;
    return '${text.substring(0, 117)}...';
  }

  String get etiqueta => 'Tasca #$id';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'id_obra': obraId,
      'id_tasca_pare': tascaPareId,
      'descripcio': descripcio,
      'data_inici': _formatDate(dataInici),
      'data_fi': _formatDate(dataFi),
      'prioritat': prioritat,
      'visibilitat_tasca': visibilitatTasca,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Payload per enviar a l'API de tasques.
  Map<String, dynamic> toTascaMap() => toMap();

  TascaDTO toDTO({int defaultPrioritat = 3}) {
    return TascaDTO(
      id: id,
      idObra: obraId,
      descripcio: descripcio,
      dataInici: dataInici ?? DateTime.now(),
      dataFi: dataFi,
      prioritat: prioritat ?? defaultPrioritat,
      visibilitat: visibilitatTasca,
      idTascaPare: tascaPareId,
    );
  }
}

/// DTO usat pel formulari de creació/edició.
///
/// Es manté separat de [Tasca] perquè el formulari exigeix `dataInici` i
/// `prioritat` no nul·les, mentre que el perfil/listat pot rebre aquests camps
/// buits del backend.
class TascaDTO {
  final int id;
  final int idObra;
  final String descripcio;
  final DateTime dataInici;
  final DateTime? dataFi;
  final int prioritat;
  final bool visibilitat;
  final int? idTascaPare;

  const TascaDTO({
    required this.id,
    required this.idObra,
    required this.descripcio,
    required this.dataInici,
    this.dataFi,
    required this.prioritat,
    required this.visibilitat,
    this.idTascaPare,
  });

  factory TascaDTO.fromMap(Map<String, dynamic> map) {
    return TascaDTO(
      id: _asInt(map['id']) ?? 0,
      idObra: _asInt(map['id_obra'] ?? map['idObra']) ?? 0,
      descripcio: _asString(map['descripcio']) ?? '',
      dataInici: _asDate(map['data_inici'] ?? map['dataInici']) ?? DateTime.now(),
      dataFi: _asDate(map['data_fi'] ?? map['dataFi']),
      prioritat: _asInt(map['prioritat']) ?? 3,
      visibilitat: _asBool(map['visibilitat_tasca'] ?? map['visibilitat']) ?? true,
      idTascaPare: _asInt(map['id_tasca_pare'] ?? map['idTascaPare']),
    );
  }

  factory TascaDTO.fromJson(Map<String, dynamic> json) => TascaDTO.fromMap(json);

  factory TascaDTO.fromTasca(Tasca tasca, {int defaultPrioritat = 3}) {
    return tasca.toDTO(defaultPrioritat: defaultPrioritat);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'id_obra': idObra,
      'id_tasca_pare': idTascaPare,
      'descripcio': descripcio,
      'data_inici': _formatDate(dataInici),
      'data_fi': _formatDate(dataFi),
      'prioritat': prioritat,
      'visibilitat_tasca': visibilitat,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toTascaMap() => toMap();
}

class ObraOption {
  final int id;
  final String nom;

  const ObraOption({required this.id, required this.nom});

  factory ObraOption.fromMap(Map<String, dynamic> map) {
    return ObraOption(
      id: _asInt(map['id']) ?? 0,
      nom: _asString(map['nom']) ?? '—',
    );
  }

  factory ObraOption.fromJson(Map<String, dynamic> json) => ObraOption.fromMap(json);
}

class TascaOption {
  final int id;
  final String desc;

  const TascaOption({required this.id, required this.desc});

  factory TascaOption.fromMap(Map<String, dynamic> map) {
    return TascaOption(
      id: _asInt(map['id']) ?? 0,
      desc: _asString(map['descripcio'] ?? map['desc']) ?? '',
    );
  }

  factory TascaOption.fromJson(Map<String, dynamic> json) => TascaOption.fromMap(json);
}

class UsuariOption {
  final int id;
  final String nom;
  final String cognoms;

  const UsuariOption({
    required this.id,
    required this.nom,
    required this.cognoms,
  });

  factory UsuariOption.fromMap(Map<String, dynamic> map) {
    return UsuariOption(
      id: _asInt(map['id'] ?? map['id_treballador']) ?? 0,
      nom: _asString(map['nom'] ?? map['username'] ?? map['treballador_nom']) ?? '—',
      cognoms: _asString(map['cognoms'] ?? map['treballador_cognoms']) ?? '',
    );
  }

  factory UsuariOption.fromJson(Map<String, dynamic> json) => UsuariOption.fromMap(json);

  String get nomComplet {
    final value = '$nom $cognoms'.trim();
    return value.isEmpty ? 'Treballador' : value;
  }
}

class TascaObraInfo {
  final int id;
  final String nom;
  final String? descripcio;
  final String? estat;
  final int? ubicacioId;
  final DateTime? dataInici;
  final DateTime? dataPrevFi;
  final DateTime? dataFi;
  final int? pressupost;

  const TascaObraInfo({
    required this.id,
    required this.nom,
    required this.descripcio,
    required this.estat,
    required this.ubicacioId,
    required this.dataInici,
    required this.dataPrevFi,
    required this.dataFi,
    required this.pressupost,
  });

  factory TascaObraInfo.fromMap(Map<String, dynamic> map) {
    return TascaObraInfo(
      id: _asInt(map['id']) ?? 0,
      nom: _asString(map['nom']) ?? 'Obra sense nom',
      descripcio: _asString(map['descripcio']),
      estat: _asString(map['estat']),
      ubicacioId: _asInt(map['ubicacio'] ?? map['ubicacioId']),
      dataInici: _asDate(map['data_inici'] ?? map['dataInici']),
      dataPrevFi: _asDate(map['data_prev_fi'] ?? map['dataPrevFi']),
      dataFi: _asDate(map['data_fi'] ?? map['dataFi']),
      pressupost: _asInt(map['pressupost']),
    );
  }

  factory TascaObraInfo.fromJson(Map<String, dynamic> json) => TascaObraInfo.fromMap(json);

  Map<String, dynamic> toObraMap() {
    return <String, dynamic>{
      'id': id,
      'nom': nom,
      'descripcio': descripcio,
      'estat': estat,
      'ubicacio': ubicacioId,
      'data_inici': _formatDate(dataInici),
      'data_prev_fi': _formatDate(dataPrevFi),
      'data_fi': _formatDate(dataFi),
      'pressupost': pressupost,
    };
  }
}

class TascaIncidenciaItem {
  final int id;
  final int? obraId;
  final int? tascaId;
  final String descripcio;
  final DateTime? dataInici;
  final DateTime? dataFi;
  final int? criticitat;
  final int? prioritat;
  final int? categoria;
  final String? estat;

  const TascaIncidenciaItem({
    required this.id,
    required this.obraId,
    required this.tascaId,
    required this.descripcio,
    required this.dataInici,
    required this.dataFi,
    required this.criticitat,
    required this.prioritat,
    required this.categoria,
    required this.estat,
  });

  factory TascaIncidenciaItem.fromMap(Map<String, dynamic> map) {
    return TascaIncidenciaItem(
      id: _asInt(map['id']) ?? 0,
      obraId: _asInt(map['id_obra'] ?? map['obraId']),
      tascaId: _asInt(map['id_tasca'] ?? map['tascaId']),
      descripcio: _asString(map['descripcio']) ?? '',
      dataInici: _asDate(map['data_inici'] ?? map['dataInici']),
      dataFi: _asDate(map['data_fi'] ?? map['dataFi']),
      criticitat: _asInt(map['criticitat']),
      prioritat: _asInt(map['prioritat']),
      categoria: _asInt(map['categoria']),
      estat: _asString(map['estat']),
    );
  }

  factory TascaIncidenciaItem.fromJson(Map<String, dynamic> json) =>
      TascaIncidenciaItem.fromMap(json);

  String get descripcioCurta {
    final text = descripcio.trim();
    if (text.isEmpty) return 'Sense descripció';
    if (text.length <= 110) return text;
    return '${text.substring(0, 107)}...';
  }
}

class TascaSolucioItem {
  final int id;
  final int? incidenciaId;
  final int? tascaId;
  final String descripcio;
  final int? costMonetari;
  final int? eficacia;
  final int? costTemporal;
  final int? impacte;

  const TascaSolucioItem({
    required this.id,
    required this.incidenciaId,
    required this.tascaId,
    required this.descripcio,
    required this.costMonetari,
    required this.eficacia,
    required this.costTemporal,
    required this.impacte,
  });

  factory TascaSolucioItem.fromMap(Map<String, dynamic> map) {
    return TascaSolucioItem(
      id: _asInt(map['id']) ?? 0,
      incidenciaId: _asInt(map['id_incidencia'] ?? map['incidenciaId']),
      tascaId: _asInt(map['id_tasca'] ?? map['tascaId']),
      descripcio: _asString(map['descripcio']) ?? '',
      costMonetari: _asInt(map['cost_monetari'] ?? map['costMonetari']),
      eficacia: _asInt(map['eficacia']),
      costTemporal: _asInt(map['cost_temporal'] ?? map['costTemporal']),
      impacte: _asInt(map['impacte']),
    );
  }

  factory TascaSolucioItem.fromJson(Map<String, dynamic> json) =>
      TascaSolucioItem.fromMap(json);

  String get descripcioCurta {
    final text = descripcio.trim();
    if (text.isEmpty) return 'Sense descripció';
    if (text.length <= 110) return text;
    return '${text.substring(0, 107)}...';
  }
}

class TascaTreballadorInfo {
  final int? id;
  final String nom;
  final String? cognoms;
  final String? nickname;
  final String? telefon;
  final String? email;

  const TascaTreballadorInfo({
    required this.id,
    required this.nom,
    required this.cognoms,
    required this.nickname,
    required this.telefon,
    required this.email,
  });

  factory TascaTreballadorInfo.fromMap(Map<String, dynamic> map) {
    return TascaTreballadorInfo(
      id: _asInt(map['id'] ?? map['id_treballador']),
      nom: _asString(map['nom'] ?? map['treballador_nom']) ?? 'Treballador',
      cognoms: _asString(map['cognoms'] ?? map['treballador_cognoms']),
      nickname: _asString(map['nickname'] ?? map['username']),
      telefon: _asString(map['telefon']),
      email: _asString(map['email']),
    );
  }

  factory TascaTreballadorInfo.fromJson(Map<String, dynamic> json) =>
      TascaTreballadorInfo.fromMap(json);

  String get nomComplet {
    final parts = <String>[
      nom.trim(),
      if ((cognoms ?? '').trim().isNotEmpty) cognoms!.trim(),
    ];
    final value = parts.where((e) => e.isNotEmpty).join(' ');
    return value.isEmpty ? 'Treballador' : value;
  }
}

class TascaAssignacio {
  final TascaTreballadorInfo usuari;
  final String? comentari;

  const TascaAssignacio({
    required this.usuari,
    required this.comentari,
  });

  factory TascaAssignacio.fromMap(Map<String, dynamic> map) {
    final usuariMap = _asMap(map['usuari']) ??
        _asMap(map['treballador']) ??
        _asMap(map['user']) ??
        map;

    return TascaAssignacio(
      usuari: TascaTreballadorInfo.fromMap(usuariMap),
      comentari: _asString(map['comentari']),
    );
  }

  factory TascaAssignacio.fromJson(Map<String, dynamic> json) => TascaAssignacio.fromMap(json);
}

class TascaProfileData {
  final Tasca tasca;
  final TascaObraInfo? obra;
  final Tasca? tascaPare;
  final List<TascaIncidenciaItem> incidencies;
  final List<TascaSolucioItem> solucions;
  final TascaAssignacio? treballadorAssignat;

  const TascaProfileData({
    required this.tasca,
    required this.obra,
    required this.tascaPare,
    required this.incidencies,
    required this.solucions,
    required this.treballadorAssignat,
  });

  factory TascaProfileData.fromMap(Map<String, dynamic> map) {
    return TascaProfileData(
      tasca: Tasca.fromMap(map),
      obra: _asMap(map['obra']) != null
          ? TascaObraInfo.fromMap(_asMap(map['obra'])!)
          : null,
      tascaPare: _asMap(map['tasca_pare']) != null
          ? Tasca.fromMap(_asMap(map['tasca_pare'])!)
          : null,
      incidencies: _asList(map['incidencies'])
          .map((item) => TascaIncidenciaItem.fromMap(item))
          .toList(),
      solucions: _asList(map['solucions'])
          .map((item) => TascaSolucioItem.fromMap(item))
          .toList(),
      treballadorAssignat: _asMap(map['treballador_assignat']) != null
          ? TascaAssignacio.fromMap(_asMap(map['treballador_assignat'])!)
          : null,
    );
  }

  factory TascaProfileData.fromJson(Map<String, dynamic> json) =>
      TascaProfileData.fromMap(json);
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = _asString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

String? _formatDate(DateTime? value) {
  if (value == null) return null;
  return value.toIso8601String().split('T').first;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .map((item) => _asMap(item))
      .whereType<Map<String, dynamic>>()
      .toList();
}

class TascaProfileCapabilities {
  final bool canEdit;
  final bool canDelete;
  final bool canAssignWorkers;
  final bool canComplete;
  final bool canReportIncidencia;

  const TascaProfileCapabilities({
    required this.canEdit,
    required this.canDelete,
    required this.canAssignWorkers,
    required this.canComplete,
    required this.canReportIncidencia,
  });

  /// Capacitats per a empresa: accions de gestió completes.
  const TascaProfileCapabilities.empresa()
      : canEdit = true,
        canDelete = true,
        canAssignWorkers = true,
        canComplete = false,
        canReportIncidencia = false;

  /// Capacitats per a treballador: accions d'execució (finalitzar + incidència).
  const TascaProfileCapabilities.treballador()
      : canEdit = false,
        canDelete = false,
        canAssignWorkers = false,
        canComplete = true,
        canReportIncidencia = true;
}

