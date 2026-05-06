import 'dart:convert';

class SolRecurs {
  final int id;
  final int? idEmpresa;
  final int idObra;
  final int idRecurs;
  final int quantitat;
  final DateTime? dataNecessitat;
  final String? comentari;
  final DateTime? dataEntrega;
  final DateTime? dataCreacio;
  final String? proveidor;
  final SolRecursObraRef? obra;
  final SolRecursRecursRef? recurs;
  final int? id_treballador; // CANVI 1c — camp id_treballador al model
  final String estat; // CANVI 1a — camp `estat` al model, amb valors 'pendent', 'aprovada' o 'rebutjada'

  const SolRecurs({
    required this.id,
    required this.idEmpresa,
    required this.idObra,
    required this.idRecurs,
    required this.quantitat,
    required this.dataNecessitat,
    required this.comentari,
    required this.dataEntrega,
    required this.dataCreacio,
    required this.proveidor,
    required this.obra,
    required this.recurs,
    this.id_treballador,
    required this.estat,
  });

  factory SolRecurs.fromMap(Map<String, dynamic> map) {
    final obraRef = SolRecursObraRef.fromDynamic(
      map['obra'] ?? map['obra_info'],
    );
    final recursRef = SolRecursRecursRef.fromDynamic(
      map['recurs'] ?? map['recurs_info'],
    );

    return SolRecurs(
      id: _asInt(map['id']),
      idEmpresa: _asIntOrNull(map['id_empresa']),
      idObra: _asInt(map['id_obra'] ?? obraRef?.id),
      idRecurs: _asInt(map['id_recurs'] ?? recursRef?.id),
      quantitat: _asInt(map['quantitat']),
      dataNecessitat: _asDate(map['data_necessitat']),
      comentari: _asString(map['comentari']),
      dataEntrega: _asDate(map['data_entrega']),
      dataCreacio: _asDateTime(map['data_creacio']),
      proveidor: _asString(map['proveidor']),
      estat: _asString(map['estat']) ?? 'pendent',
      obra: obraRef?.hasAnyValue == true ? obraRef : null,
      recurs: recursRef?.hasAnyValue == true ? recursRef : null,
    );
  }

  factory SolRecurs.fromJson(String source) {
    return SolRecurs.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (idEmpresa != null) 'id_empresa': idEmpresa,
      'id_obra': idObra,
      'id_recurs': idRecurs,
      'quantitat': quantitat,
      'data_necessitat': _dateToApiString(dataNecessitat),
      'comentari': comentari,
      'data_entrega': _dateToApiString(dataEntrega),
      'data_creacio': dataCreacio?.toIso8601String(),
      'proveidor': proveidor,
      if (obra != null) 'obra': obra!.toMap(),
      if (recurs != null) 'recurs': recurs!.toMap(),
    };
  }

  String toJson() => jsonEncode(toMap());

  bool get hasComentari => comentari?.trim().isNotEmpty == true;
  bool get hasProveidor => proveidor?.trim().isNotEmpty == true;
  bool get hasEntrega => dataEntrega != null;
  bool get isPendent => !hasEntrega;

  String get estatLabel => hasEntrega ? 'Entregat' : 'Pendent';



  String get estatAprovacioLabel {
    switch (estat) {
      case 'aprovada':
        return 'Aprovada';
      case 'rebutjada':
        return 'Rebutjada';
      default:
        return 'Pendent';
    }
  }
  
  String get recursLabel {
    final nom = recurs?.nom?.trim();
    if (nom != null && nom.isNotEmpty) return nom;
    return 'Recurs #$idRecurs';
  }

  String get obraLabel {
    final nom = obra?.nom?.trim();
    if (nom != null && nom.isNotEmpty) return nom;
    return 'Obra #$idObra';
  }

  String get quantitatLabel {
    final unitat = recurs?.unitatsMesura?.trim();
    if (unitat != null && unitat.isNotEmpty) {
      return '$quantitat $unitat';
    }
    return '$quantitat';
  }

  String get proveidorLabel {
    final value = proveidor?.trim();
    return (value == null || value.isEmpty) ? 'Sense proveïdor' : value;
  }

  bool get esPendentAprovacio => estat == 'pendent';
  bool get esAprovada => estat == 'aprovada';
  bool get esRebutjada => estat == 'rebutjada';
}

class SolRecursListData {
  final List<SolRecurs> sollicituds;

  const SolRecursListData({
    required this.sollicituds,
  });

  factory SolRecursListData.fromList(List<dynamic> rawList) {
    final items = _mapList(rawList, SolRecurs.fromMap)
      ..sort((a, b) {
        final aDate = a.dataNecessitat ?? a.dataCreacio ?? DateTime(1970);
        final bDate = b.dataNecessitat ?? b.dataCreacio ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });

    return SolRecursListData(sollicituds: items);
  }

  factory SolRecursListData.fromJson(String source) {
    return SolRecursListData.fromList(
      jsonDecode(source) as List<dynamic>,
    );
  }

  bool get hasItems => sollicituds.isNotEmpty;
  int get total => sollicituds.length;
  int get pendentsCount => sollicituds.where((e) => e.isPendent).length;
  int get entregatsCount => sollicituds.where((e) => e.hasEntrega).length;
}

class SolRecursObraRef {
  final int? id;
  final String? nom;

  const SolRecursObraRef({
    required this.id,
    required this.nom,
  });

  factory SolRecursObraRef.fromDynamic(dynamic value) {
    if (value == null) return const SolRecursObraRef(id: null, nom: null);

    if (value is int) {
      return SolRecursObraRef(
        id: value,
        nom: 'Obra #$value',
      );
    }

    if (value is String) {
      final text = value.trim();
      return SolRecursObraRef(
        id: int.tryParse(text),
        nom: text.isEmpty ? null : text,
      );
    }

    if (value is Map<String, dynamic>) {
      return SolRecursObraRef(
        id: _asIntOrNull(value['id'] ?? value['id_obra']),
        nom: _asString(
          value['nom'] ?? value['nom_obra'] ?? value['display_name'],
        ),
      );
    }

    if (value is Map) {
      return SolRecursObraRef.fromDynamic(Map<String, dynamic>.from(value));
    }

    return SolRecursObraRef(
      id: null,
      nom: value.toString(),
    );
  }

  bool get hasAnyValue => id != null || nom?.trim().isNotEmpty == true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
    };
  }
}

class SolRecursRecursRef {
  final int? id;
  final String? nom;
  final String? unitatsMesura;
  final String? tipusRecurs;

  const SolRecursRecursRef({
    required this.id,
    required this.nom,
    required this.unitatsMesura,
    required this.tipusRecurs,
  });

  factory SolRecursRecursRef.fromDynamic(dynamic value) {
    if (value == null) {
      return const SolRecursRecursRef(
        id: null,
        nom: null,
        unitatsMesura: null,
        tipusRecurs: null,
      );
    }

    if (value is int) {
      return SolRecursRecursRef(
        id: value,
        nom: 'Recurs #$value',
        unitatsMesura: null,
        tipusRecurs: null,
      );
    }

    if (value is String) {
      final text = value.trim();
      return SolRecursRecursRef(
        id: int.tryParse(text),
        nom: text.isEmpty ? null : text,
        unitatsMesura: null,
        tipusRecurs: null,
      );
    }

    if (value is Map<String, dynamic>) {
      return SolRecursRecursRef(
        id: _asIntOrNull(value['id'] ?? value['id_recurs']),
        nom: _asString(
          value['nom'] ?? value['nom_recurs'] ?? value['display_name'],
        ),
        unitatsMesura: _asString(
          value['unitats_mesura'] ?? value['unitat_mesura'],
        ),
        tipusRecurs: _asString(
          value['tipus_recurs'] ?? value['tipus'],
        ),
      );
    }

    if (value is Map) {
      return SolRecursRecursRef.fromDynamic(Map<String, dynamic>.from(value));
    }

    return SolRecursRecursRef(
      id: null,
      nom: value.toString(),
      unitatsMesura: null,
      tipusRecurs: null,
    );
  }

  bool get hasAnyValue {
    return id != null ||
        nom?.trim().isNotEmpty == true ||
        unitatsMesura?.trim().isNotEmpty == true ||
        tipusRecurs?.trim().isNotEmpty == true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'unitats_mesura': unitatsMesura,
      'tipus_recurs': tipusRecurs,
    };
  }
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

  if (value is String) {
    return int.tryParse(value.trim());
  }

  if (value is Map<String, dynamic>) {
    return _asIntOrNull(
      value['id'] ??
          value['pk'] ??
          value['id_obra'] ??
          value['id_recurs'] ??
          value['id_empresa'],
    );
  }

  if (value is Map) {
    return _asIntOrNull(Map<String, dynamic>.from(value));
  }

  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
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

String? _dateToApiString(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}