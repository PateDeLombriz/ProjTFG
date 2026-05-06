import 'dart:convert';

import 'package:front_end/models/document_models.dart';
import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/responsable_models.dart';
import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:latlong2/latlong.dart';

class Obra {
  final int id;
  final String nom;
  final ObraUbicacioRef? ubicacio;
  final ObraUbicacioInfo? ubicacioInfo;
  final DateTime? dataInici;
  final DateTime? dataPrevFi;
  final DateTime? dataFi;
  final num? pressupost;
  final String? descripcio;
  final String? estat;

  const Obra({
    required this.id,
    required this.nom,
    required this.ubicacio,
    required this.ubicacioInfo,
    required this.dataInici,
    required this.dataPrevFi,
    required this.dataFi,
    required this.pressupost,
    required this.descripcio,
    required this.estat,
  });

  factory Obra.fromMap(Map<String, dynamic> map) {
    return Obra(
      id: _asIntOrZero(map['id']),
      nom: _asString(map['nom']) ?? 'Obra',
      ubicacio: ObraUbicacioRef.fromDynamic(map['ubicacio']),
      ubicacioInfo: ObraUbicacioInfo.fromDynamic(map['ubicacio_info']),
      dataInici: _asDateOrNull(map['data_inici']),
      dataPrevFi: _asDateOrNull(map['data_prev_fi']),
      dataFi: _asDateOrNull(map['data_fi']),
      pressupost: _asNumOrNull(map['pressupost']),
      descripcio: _asString(map['descripcio']),
      estat: _asString(map['estat']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'ubicacio': ubicacio?.toMap(),
      'ubicacio_info': ubicacioInfo?.toMap(),
      'data_inici': _formatApiDateOrNull(dataInici),
      'data_prev_fi': _formatApiDateOrNull(dataPrevFi),
      'data_fi': _formatApiDateOrNull(dataFi),
      'pressupost': pressupost,
      'descripcio': descripcio,
      'estat': estat,
    };
  }

  Map<String, dynamic> toObraMap() => toMap();

  bool get hasDescription => _hasText(descripcio);

  bool get hasMapCoordinates =>
      ubicacioInfo?.latitud != null && ubicacioInfo?.longitud != null;

  bool get hasLocationData =>
      ubicacioInfo?.hasVisualData == true ||
      _hasText(ubicacio?.etiqueta) ||
      ubicacio?.id != null;

  String get locationLabel {
    final info = ubicacioInfo;
    if (info != null && info.displayLabel.isNotEmpty) {
      return info.displayLabel;
    }

    final etiqueta = ubicacio?.etiqueta?.trim();
    if (etiqueta != null && etiqueta.isNotEmpty) {
      return etiqueta;
    }

    final idUbicacio = ubicacio?.id;
    if (idUbicacio != null) {
      return 'Ubicació #$idUbicacio';
    }

    return 'Sense ubicació';
  }
}

class ObraProfileData {
  final Obra obra;
  final List<Incidencia> incidencies;
  final List<Tasca> tasques;
  final List<DocumentObraItem> documents;
  final List<SolRecurs> solRecursos;
  final List<ResponsableObra> responsables;

  const ObraProfileData({
    required this.obra,
    required this.incidencies,
    required this.tasques,
    required this.documents,
    required this.solRecursos,
    required this.responsables,
  });

  factory ObraProfileData.fromMap(Map<String, dynamic> map) {
    return ObraProfileData(
      obra: Obra.fromMap(map),
      incidencies: _mapList(map['incidencies'], Incidencia.fromMap),
      tasques: _mapList(map['tasques'], Tasca.fromMap),
      documents: _mapList(map['documents'], DocumentObraItem.fromMap),
      solRecursos: _mapList(map['sol_recursos'], SolRecurs.fromMap),
      responsables: _mapList(map['responsable'], ResponsableObra.fromMap),
    );
  }

  factory ObraProfileData.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El JSON d’obra no té un format vàlid.');
    }
    return ObraProfileData.fromMap(decoded);
  }

  Map<String, dynamic> toMap() {
    return {
      'obra': obra.toMap(),
      'incidencies': incidencies.map((e) => e.toMap()).toList(),
      'tasques': tasques.map((e) => e.toMap()).toList(),
      'documents': documents.map((e) => e.toMap()).toList(),
      'sol_recursos': solRecursos.map((e) => e.toMap()).toList(),
      'responsable': responsables.map((e) => e.toMap()).toList(),
    };
  }
}

class ObraUbicacioRef {
  final int? id;
  final String? etiqueta;

  const ObraUbicacioRef({
    required this.id,
    required this.etiqueta,
  });

  factory ObraUbicacioRef.fromDynamic(dynamic value) {
    if (value == null) {
      return const ObraUbicacioRef(id: null, etiqueta: null);
    }

    if (value is int) {
      return ObraUbicacioRef(
        id: value,
        etiqueta: 'Ubicació #$value',
      );
    }

    if (value is num) {
      final parsed = value.toInt();
      return ObraUbicacioRef(
        id: parsed,
        etiqueta: 'Ubicació #$parsed',
      );
    }

    if (value is String) {
      final parsedId = int.tryParse(value.trim());
      return ObraUbicacioRef(
        id: parsedId,
        etiqueta: value.trim().isEmpty ? null : value.trim(),
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return ObraUbicacioRef(
        id: _asIntOrNull(map['id'] ?? map['id_ubicacio']),
        etiqueta: _firstNonEmptyString([
          map['display_name'],
          map['adreca'],
          map['adreça'],
          map['nom'],
          map['ciutat'],
        ]),
      );
    }

    return ObraUbicacioRef(
      id: null,
      etiqueta: value.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'etiqueta': etiqueta,
    };
  }
}

class ObraUbicacioInfo {
  final int idUbicacio;
  final String? adreca;
  final String? ciutat;
  final String? codiPostal;
  final String? provincia;
  final String? pais;
  final double? latitud;
  final double? longitud;

  const ObraUbicacioInfo({
    required this.idUbicacio,
    required this.adreca,
    required this.ciutat,
    required this.codiPostal,
    required this.provincia,
    required this.pais,
    required this.latitud,
    required this.longitud,
  });

  factory ObraUbicacioInfo.fromDynamic(dynamic value) {
    if (value is! Map) {
      return const ObraUbicacioInfo(
        idUbicacio: 0,
        adreca: null,
        ciutat: null,
        codiPostal: null,
        provincia: null,
        pais: null,
        latitud: null,
        longitud: null,
      );
    }

    final map = Map<String, dynamic>.from(value);

    return ObraUbicacioInfo(
      idUbicacio: _asIntOrZero(map['id_ubicacio'] ?? map['id']),
      adreca: _asString(map['adreca'] ?? map['adreça']),
      ciutat: _asString(map['ciutat']),
      codiPostal: _asString(map['codi_postal']),
      provincia: _asString(map['provincia']),
      pais: _asString(map['pais'] ?? map['país']),
      latitud: _asDoubleOrNull(map['latitud']),
      longitud: _asDoubleOrNull(map['longitud']),
    );
  }
  factory ObraUbicacioInfo.fromJson(Map<String, dynamic> json) {
    final parsedId = _asIntOrZero(json['id_ubicacio'] ?? json['id']);
    final adreca = _asString(json['adreca'] ?? json['adreça']);
    final ciutat = _asString(json['ciutat']);
    final codiPostal = _asString(json['codi_postal']);
    final provincia = _asString(json['provincia']);
    final pais = _asString(json['pais'] ?? json['país']);

    final parts = <String>[
      if (_hasText(adreca)) adreca!.trim(),
      if (_hasText(ciutat)) ciutat!.trim(),
      if (_hasText(provincia)) provincia!.trim(),
    ];

    return ObraUbicacioInfo(
      idUbicacio: parsedId,
      adreca: adreca,
      ciutat: ciutat,
      codiPostal: codiPostal,
      provincia: provincia,
      pais: pais,
      latitud: _asDoubleOrNull(json['latitud']),
      longitud: _asDoubleOrNull(json['longitud']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_ubicacio': idUbicacio,
      'adreca': adreca,
      'ciutat': ciutat,
      'codi_postal': codiPostal,
      'provincia': provincia,
      'pais': pais,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  LatLng  getLatLng() {
    if (latitud != null && longitud != null) {
      return LatLng(latitud!, longitud!);
    }
    return const LatLng(0, 0);
  }
  
  bool get hasVisualData =>
      displayLabel.isNotEmpty || latitud != null || longitud != null;

  String get displayLabel =>
      _firstNonEmptyString([adreca, ciutat, provincia, pais]) ?? '';
}

class ObraCreateRequest {
  final String nom;
  final int ubicacioId;
  final DateTime dataInici;
  final DateTime dataPrevFi;
  final int pressupost;
  final String? descripcio;
  final String estat;

  const ObraCreateRequest({
    required this.nom,
    required this.ubicacioId,
    required this.dataInici,
    required this.dataPrevFi,
    required this.pressupost,
    required this.estat,
    this.descripcio,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom.trim(),
      'ubicacio': ubicacioId,
      'data_inici': _formatApiDate(dataInici),
      'data_prev_fi': _formatApiDate(dataPrevFi),
      'pressupost': pressupost,
      'descripcio': _cleanNullableText(descripcio),
      'estat': estat.trim(),
    };
  }
}

class ObraCreateResult {
  final int? obraId;
  final int? relacioId;

  const ObraCreateResult({
    this.obraId,
    this.relacioId,
  });

  factory ObraCreateResult.fromJson(Map<String, dynamic> json) {
    return ObraCreateResult(
      obraId: _asIntOrNull(json['id_obra'] ?? json['obra_id']),
      relacioId: _asIntOrNull(json['id']),
    );
  }
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromMap,
) {
  if (value is! List) return <T>[];

  return value
      .whereType<Map>()
      .map((item) => fromMap(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

String? _cleanNullableText(String? value) {
  if (value == null) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final parsed = _asString(value);
    if (parsed != null) return parsed;
  }
  return null;
}

int _asIntOrZero(dynamic value) {
  return _asIntOrNull(value) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

num? _asNumOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString().trim());
}

double? _asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

DateTime? _asDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString().trim());
}

String _formatApiDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String? _formatApiDateOrNull(DateTime? value) {
  if (value == null) return null;
  return _formatApiDate(value);
}
