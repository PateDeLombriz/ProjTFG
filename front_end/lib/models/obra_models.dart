import 'dart:convert';

import 'package:front_end/models/document_models.dart';
import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/models/responsable_models.dart';
import 'package:front_end/models/tasca_models.dart';



class Obra {
  final int id;
  final String nom;
  final ObraUbicacioRef? ubicacio;
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
    required this.dataInici,
    required this.dataPrevFi,
    required this.dataFi,
    required this.pressupost,
    required this.descripcio,
    required this.estat,
  });

  factory Obra.fromMap(Map<String, dynamic> map) {
    return Obra(
      id: _asInt(map['id']),
      nom: _asString(map['nom']) ?? 'Obra',
      ubicacio: ObraUbicacioRef.fromDynamic(map['ubicacio']),
      dataInici: _asDate(map['data_inici']),
      dataPrevFi: _asDate(map['data_prev_fi']),
      dataFi: _asDate(map['data_fi']),
      pressupost: _asNum(map['pressupost']),
      descripcio: _asString(map['descripcio']),
      estat: _asString(map['estat']),
    );
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
    return ObraProfileData.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
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
      return ObraUbicacioRef(id: value, etiqueta: 'Ubicació #$value');
    }

    if (value is String) {
      return ObraUbicacioRef(
        id: int.tryParse(value),
        etiqueta: value,
      );
    }

    if (value is Map<String, dynamic>) {
      return ObraUbicacioRef(
        id: _asIntOrNull(value['id'] ?? value['id_ubicacio']),
        etiqueta: _firstNonEmptyString([
          value['adreca'],
          value['adreça'],
          value['nom'],
          value['ciutat'],
        ]),
      );
    }

    return ObraUbicacioRef(
      id: null,
      etiqueta: value.toString(),
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

int _asInt(dynamic value) {
  return _asIntOrNull(value) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}