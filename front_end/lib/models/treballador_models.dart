import 'dart:convert';

class TreballadorProfileData {
  final int id;
  final String nom;
  final String cognoms;
  final String? nickname;
  final String? telefon;
  final String? email;
  final String? fotoUrl;
  final TreballadorEmpresaActualRef? empresaActual;
  final String? carrecActual;
  final String? estatContracte;
  final int tasquesCount;
  final int obresCount;

  const TreballadorProfileData({
    required this.id,
    required this.nom,
    required this.cognoms,
    required this.nickname,
    required this.telefon,
    required this.email,
    required this.fotoUrl,
    required this.empresaActual,
    required this.carrecActual,
    required this.estatContracte,
    required this.tasquesCount,
    required this.obresCount,
  });

  factory TreballadorProfileData.fromMap(Map<String, dynamic> map) {
    final contracte = _asMap(map['contracte_vigent']);
    final subjecte = _asMap(map['subjecte']);

    return TreballadorProfileData(
      id: _asInt(
        map['id'] ?? subjecte?['id'] ?? map['id_treballador'],
      ),
      nom: _asString(
            map['nom'] ?? subjecte?['nom'],
          ) ??
          'Treballador',
      cognoms: _asString(
            map['cognoms'] ?? subjecte?['cognoms'],
          ) ??
          '',
      nickname: _asString(
        map['nickname'] ?? subjecte?['nickname'],
      ),
      telefon: _asString(map['telefon']),
      email: _asString(map['email']),
      fotoUrl: _resolveFotoUrl(map),
      empresaActual: TreballadorEmpresaActualRef.fromDynamic(
        map['empresa_actual'] ?? map['empresa'] ?? map['empresa_info'],
      ),
      carrecActual: _asString(
            map['carrec_actual'] ?? contracte?['carrec'] ?? map['carrec'],
          ) ??
          _extractCarrecFromContractes(_normalizeContractes(map['contractes'])),
      estatContracte: _asString(
            map['estat_contracte'] ?? contracte?['estat'] ?? map['estat'],
          ) ??
          _extractEstatFromContractes(_normalizeContractes(map['contractes'])),
      tasquesCount: _asInt(
        map['tasques_count'] ?? map['num_tasques'] ?? map['tasquesCount'],
      ),
      obresCount: _asInt(
        map['obres_count'] ?? map['num_obres'] ?? map['obresCount'],
      ),
    );
  }

  factory TreballadorProfileData.fromJson(String source) {
    return TreballadorProfileData.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  String get nomComplet {
    final parts = <String>[
      nom.trim(),
      if (cognoms.trim().isNotEmpty) cognoms.trim(),
    ];
    return parts.join(' ').trim();
  }

  String get aliasVisible {
    final nick = nickname?.trim();
    if (nick != null && nick.isNotEmpty) {
      return '@$nick';
    }
    return nomComplet;
  }

  String get empresaLabel {
    return empresaActual?.nomEmpresa?.trim().isNotEmpty == true
        ? empresaActual!.nomEmpresa!
        : 'Sense empresa activa';
  }

  String get carrecLabel {
    final value = carrecActual?.trim();
    return (value == null || value.isEmpty) ? 'Sense càrrec' : value;
  }

  String get estatLabel {
    return _estatLabel(estatContracte);
  }

  String get estatKey {
    return _normalizeEstat(estatContracte);
  }

  bool get isActiu => estatKey == 'actiu';
  bool get hasNickname => nickname?.trim().isNotEmpty == true;

  bool get hasContactInfo {
    return (telefon?.trim().isNotEmpty == true) ||
        (email?.trim().isNotEmpty == true);
  }

  bool get hasFoto {
    return fotoUrl?.trim().isNotEmpty == true;
  }

  String get tasquesCountLabel {
    return tasquesCount == 1 ? '1 tasca' : '$tasquesCount tasques';
  }

  String get obresCountLabel {
    return obresCount == 1 ? '1 obra' : '$obresCount obres';
  }

  String get metricSummary {
    return '$tasquesCountLabel · $obresCountLabel';
  }
}

class TreballadorEmpresaActualRef {
  final int? id;
  final String? nomEmpresa;

  const TreballadorEmpresaActualRef({
    required this.id,
    required this.nomEmpresa,
  });

  factory TreballadorEmpresaActualRef.fromDynamic(dynamic value) {
    if (value == null) {
      return const TreballadorEmpresaActualRef(
        id: null,
        nomEmpresa: null,
      );
    }

    if (value is int) {
      return TreballadorEmpresaActualRef(
        id: value,
        nomEmpresa: 'Empresa #$value',
      );
    }

    if (value is String) {
      final text = value.trim();
      return TreballadorEmpresaActualRef(
        id: int.tryParse(text),
        nomEmpresa: text.isEmpty ? null : text,
      );
    }

    if (value is Map<String, dynamic>) {
      return TreballadorEmpresaActualRef(
        id: _asIntOrNull(
          value['id'] ?? value['id_empresa'],
        ),
        nomEmpresa: _asString(
          value['nom_empresa'] ?? value['nom'] ?? value['display_name'],
        ),
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return TreballadorEmpresaActualRef.fromDynamic(map);
    }

    return TreballadorEmpresaActualRef(
      id: null,
      nomEmpresa: value.toString(),
    );
  }
}

class TreballadorListItem {
  final int id;
  final String nom;
  final String? cognoms;
  final String? nickname;
  final String? carrec;
  final String? estat;
  final String? fotoUrl;

  const TreballadorListItem({
    required this.id,
    required this.nom,
    required this.cognoms,
    required this.nickname,
    required this.carrec,
    required this.estat,
    required this.fotoUrl,
  });

  factory TreballadorListItem.fromMap(Map<String, dynamic> map) {
    final contractes = _normalizeContractes(map['contractes']);

    return TreballadorListItem(
      id: _asInt(map['id'] ?? map['id_treballador']),
      nom: _asString(map['nom']) ?? 'Treballador',
      cognoms: _asString(map['cognoms']),
      nickname: _asString(map['nickname']),
      carrec:
          _asString(map['carrec']) ?? _extractCarrecFromContractes(contractes),
      estat:
          _asString(map['estat']) ?? _extractEstatFromContractes(contractes),
      fotoUrl: _resolveFotoUrl(map),
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

  String get nomVisual {
    final nicknameClean = nickname?.trim();
    if (nicknameClean != null && nicknameClean.isNotEmpty) {
      return nicknameClean;
    }
    return nomComplet;
  }

  String get initials {
    final source = nomComplet.trim();
    if (source.isEmpty) return 'TR';

    final parts = source
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'TR';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get hasFoto => fotoUrl != null && fotoUrl!.trim().isNotEmpty;
  bool get hasCarrec => carrec != null && carrec!.trim().isNotEmpty;
  bool get hasNickname => nickname?.trim().isNotEmpty == true;

  String get carrecLabel {
    final value = carrec?.trim();
    return (value == null || value.isEmpty) ? 'Sense càrrec assignat' : value;
  }

  String get estatLabel {
    return _estatLabel(estat);
  }

  String get estatKey {
    return _normalizeEstat(estat);
  }

  String get carrecKey {
    final value = carrec?.trim().toLowerCase();
    return (value == null || value.isEmpty) ? 'sense_carrec' : value;
  }

  bool get isActiu => estatKey == 'actiu';

  String get searchableText {
    return <String>[
      nomComplet,
      nickname ?? '',
      carrecLabel,
      estatLabel,
    ].join(' ').toLowerCase();
  }
}

class TreballadorListData {
  final int empresaId;
  final String? empresaNom;
  final List<TreballadorListItem> treballadors;

  const TreballadorListData({
    required this.empresaId,
    required this.empresaNom,
    required this.treballadors,
  });

  factory TreballadorListData.fromEmpresaDetailMap(Map<String, dynamic> map) {
    final items = _mapList(map['treballadors'], TreballadorListItem.fromMap)
      ..sort(
        (a, b) => a.nomComplet
            .toLowerCase()
            .compareTo(b.nomComplet.toLowerCase()),
      );

    return TreballadorListData(
      empresaId: _asInt(map['id']),
      empresaNom: _asString(map['nom_empresa']),
      treballadors: items,
    );
  }

  factory TreballadorListData.fromJson(String source) {
    return TreballadorListData.fromEmpresaDetailMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  bool get hasTreballadors => treballadors.isNotEmpty;

  List<String> get estatsDisponibles {
    final values = treballadors
        .map((t) => t.estatLabel)
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> get carrecsDisponibles {
    final values = treballadors
        .map((t) => t.carrecLabel)
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  int get totalAmbFoto => treballadors.where((t) => t.hasFoto).length;
  int get totalSenseCarrec => treballadors.where((t) => !t.hasCarrec).length;
  int get totalActius => treballadors.where((t) => t.isActiu).length;
}

String? _resolveFotoUrl(Map<String, dynamic> map) {
  final directa = _firstNonEmptyString([
    map['foto_url'],
    map['foto'],
    map['imatge_perfil'],
  ]);

  if (directa != null) return directa;

  final config = _asMap(map['configuracio']);
  return _firstNonEmptyString([
    config?['imatge_perfil'],
    config?['foto'],
    config?['foto_url'],
  ]);
}

List<Map<String, dynamic>> _normalizeContractes(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];

  return value
      .map((item) => item is Map
          ? Map<String, dynamic>.from(item)
          : <String, dynamic>{})
      .toList();
}

String? _extractCarrecFromContractes(List<Map<String, dynamic>> contractes) {
  if (contractes.isEmpty) return null;

  for (final contracte in contractes) {
    final estat = _normalizeEstat(contracte['estat']);
    final carrec = _asString(contracte['carrec']);

    if (estat == 'actiu' && carrec != null && carrec.isNotEmpty) {
      return carrec;
    }
  }

  return _asString(contractes.first['carrec']);
}

String? _extractEstatFromContractes(List<Map<String, dynamic>> contractes) {
  if (contractes.isEmpty) return null;

  for (final contracte in contractes) {
    final estat = _asString(contracte['estat']);
    if (estat != null && estat.isNotEmpty) {
      return estat;
    }
  }

  return null;
}

String _estatLabel(dynamic value) {
  final key = _normalizeEstat(value);

  switch (key) {
    case 'actiu':
      return 'Actiu';
    case 'baixa':
      return 'Baixa';
    case 'acomiadat':
      return 'Acomiadat';
    default:
      final text = _asString(value);
      return (text == null || text.isEmpty) ? 'Sense estat' : text;
  }
}

String _normalizeEstat(dynamic value) {
  final text = _asString(value)?.toLowerCase();
  if (text == null || text.isEmpty) return 'sense_estat';

  switch (text) {
    case 'actiu':
    case 'activa':
      return 'actiu';
    case 'baixa':
      return 'baixa';
    case 'acomiadat':
      return 'acomiadat';
    default:
      return text;
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  return _asIntOrNull(value) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromMap,
) {
  if (value is! List) return <T>[];

  return value
      .whereType<Map>()
      .map((item) => fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final text = _asString(value);
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}