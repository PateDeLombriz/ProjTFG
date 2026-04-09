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
      obraId: _asInt(map['id_obra']) ?? 0,
      tascaPareId: _asInt(map['id_tasca_pare']),
      descripcio: _asString(map['descripcio']) ?? '',
      dataInici: _asDate(map['data_inici']),
      dataFi: _asDate(map['data_fi']),
      prioritat: _asInt(map['prioritat']),
      visibilitatTasca: _asBool(map['visibilitat_tasca']) ?? true,
    );
  }

  String get descripcioCurta {
    final text = descripcio.trim();
    if (text.isEmpty) return 'Sense descripció';
    if (text.length <= 120) return text;
    return '${text.substring(0, 117)}...';
  }

  String get etiqueta => 'Tasca #$id';
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
      ubicacioId: _asInt(map['ubicacio']),
      dataInici: _asDate(map['data_inici']),
      dataPrevFi: _asDate(map['data_prev_fi']),
      dataFi: _asDate(map['data_fi']),
      pressupost: _asInt(map['pressupost']),
    );
  }

  Map<String, dynamic> toObraMap() {
  return <String, dynamic>{
    'id': id,
    'nom': nom,
    'descripcio': descripcio,
    'estat': estat,
    'ubicacio': ubicacioId,
    'data_inici': dataInici,
    'data_prev_fi': dataPrevFi,
    'data_fi': dataFi,
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
      obraId: _asInt(map['id_obra']),
      tascaId: _asInt(map['id_tasca']),
      descripcio: _asString(map['descripcio']) ?? '',
      dataInici: _asDate(map['data_inici']),
      dataFi: _asDate(map['data_fi']),
      criticitat: _asInt(map['criticitat']),
      prioritat: _asInt(map['prioritat']),
      categoria: _asInt(map['categoria']),
      estat: _asString(map['estat']),
    );
  }

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
      incidenciaId: _asInt(map['id_incidencia']),
      tascaId: _asInt(map['id_tasca']),
      descripcio: _asString(map['descripcio']) ?? '',
      costMonetari: _asInt(map['cost_monetari']),
      eficacia: _asInt(map['eficacia']),
      costTemporal: _asInt(map['cost_temporal']),
      impacte: _asInt(map['impacte']),
    );
  }

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
      id: _asInt(map['id']),
      nom: _asString(map['nom']) ?? 'Treballador',
      cognoms: _asString(map['cognoms']),
      nickname: _asString(map['nickname']),
      telefon: _asString(map['telefon']),
      email: _asString(map['email']),
    );
  }

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
    final usuariMap = _asMap(map['usuari']) ?? const <String, dynamic>{};
    return TascaAssignacio(
      usuari: TascaTreballadorInfo.fromMap(usuariMap),
      comentari: _asString(map['comentari']),
    );
  }
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
  final text = _asString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val),
    );
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
