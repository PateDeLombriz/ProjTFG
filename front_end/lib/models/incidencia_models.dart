import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/models/obra_models.dart';

class Incidencia {
  final int id;
  final int idObra;
  final int? idTasca;
  final String descripcio;
  final DateTime? dataInici;
  final DateTime? dataFi;
  final int criticitat;
  final int prioritat;
  final int? categoria;
  final String? estat;
  final String? obraNom;

  const Incidencia({
    required this.id,
    required this.idObra,
    required this.idTasca,
    required this.descripcio,
    required this.dataInici,
    required this.dataFi,
    required this.criticitat,
    required this.prioritat,
    required this.categoria,
    required this.estat,
    required this.obraNom,
  });

  factory Incidencia.fromMap(Map<String, dynamic> map) {
    return Incidencia(
      id: _asInt(map['id']),
      idObra: _asInt(map['id_obra']),
      idTasca: _asIntOrNull(map['id_tasca']),
      descripcio: _asString(map['descripcio']) ?? '—',
      dataInici: _asDate(map['data_inici']),
      dataFi: _asDate(map['data_fi']),
      criticitat: _asInt(map['criticitat']),
      prioritat: _asInt(map['prioritat']),
      categoria: _asIntOrNull(map['categoria']),
      estat: _asString(map['estat']),
      obraNom: _asString(map['obra_nom']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_obra': idObra,
      'id_tasca': idTasca,
      'descripcio': descripcio,
      'data_inici': _encodeDate(dataInici),
      'data_fi': _encodeDate(dataFi),
      'criticitat': criticitat,
      'prioritat': prioritat,
      'categoria': categoria,
      'estat': estat,
    };
  }

  Map<String, dynamic> toIncidenciaMap() => toMap();

  String get estatLabel {
    final value = estat?.trim().toLowerCase();
    if (value == null || value.isEmpty) return 'Sense estat';

    switch (value) {
      case 'pendent':
        return 'Pendent';
      case 'en_curs':
      case 'en curs':
        return 'En curs';
      case 'resolta':
        return 'Resolta';
      case 'tancada':
        return 'Tancada';
      default:
        return estat!.trim();
    }
  }

  String get categoriaLabel {
    switch (categoria) {
      case 1:
        return 'Material';
      case 2:
        return 'Tècnica';
      case 3:
        return 'Seguretat';
      case 4:
        return 'Planificació';
      default:
        return 'Sense categoria';
    }
  }

  String get descripcioCurta {
    final text = descripcio.trim();
    if (text.isEmpty) return '—';
    if (text.length <= 120) return text;
    return '${text.substring(0, 117)}...';
  }

  bool get teTascaAssociada => idTasca != null;
}

/// Referència lleugera d'obra per enriquir el llistat d'incidències
/// a partir de la resposta d'obresEmpresa/<idEmpresa>/.
class IncidenciaObraRef {
  final int id;
  final String nom;
  final String? estat;
  final String? ciutat;
  final String? adreca;

  const IncidenciaObraRef({
    required this.id,
    required this.nom,
    required this.estat,
    required this.ciutat,
    required this.adreca,
  });

  factory IncidenciaObraRef.fromObraEmpresaMap(Map<String, dynamic> map) {
    final obraInfo = _asMap(map['obra_info']) ?? const <String, dynamic>{};
    final ubicacioInfo =
        _asMap(obraInfo['ubicacio_info']) ?? const <String, dynamic>{};

    final obraId = _asInt(obraInfo['id']);

    return IncidenciaObraRef(
      id: obraId,
      nom: _asString(obraInfo['nom']) ?? 'Obra #$obraId',
      estat: _asString(obraInfo['estat']),
      ciutat: _asString(ubicacioInfo['ciutat']),
      adreca: _asString(ubicacioInfo['adreca']) ??
          _asString(ubicacioInfo['adreça']),
    );
  }

  String get ubicacioLabel {
    final parts = <String>[
      if (ciutat != null && ciutat!.trim().isNotEmpty) ciutat!.trim(),
      if (adreca != null && adreca!.trim().isNotEmpty) adreca!.trim(),
    ];

    if (parts.isEmpty) return 'Sense ubicació';
    return parts.join(' · ');
  }
}

/// Model específic per al llistat.
/// Manté la incidència base i hi afegeix el context mínim d'obra
/// necessari per pintar cards útils sense dependre del detail screen.
class IncidenciaListItem {
  final Incidencia incidencia;

  const IncidenciaListItem({
    required this.incidencia,
  });

  factory IncidenciaListItem.fromMap(Map<String, dynamic> map) {
    return IncidenciaListItem(
      incidencia: Incidencia.fromMap(map),
    );
  }

  int get id => incidencia.id;
  int get idObra => incidencia.idObra;
  int? get idTasca => incidencia.idTasca;
  String get descripcio => incidencia.descripcio;
  DateTime? get dataInici => incidencia.dataInici;
  DateTime? get dataFi => incidencia.dataFi;
  int get criticitat => incidencia.criticitat;
  int get prioritat => incidencia.prioritat;
  int? get categoria => incidencia.categoria;
  String? get estat => incidencia.estat;
  String? get obraNom => incidencia.obraNom;
}

class IncidenciaListData {
  final List<IncidenciaListItem> incidencies;
  final List<IncidenciaObraFilterOption> obresDisponibles;

  const IncidenciaListData({
    required this.incidencies,
    required this.obresDisponibles,
  });
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

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) builder,
) {
  if (raw is! List) return <T>[];

  final result = <T>[];

  for (final item in raw) {
    final map = _asMap(item);
    if (map != null) {
      result.add(builder(map));
    }
  }

  return result;
}

class IncidenciaSolucioItem {
  final int id;
  final String descripcio;
  final int? eficacia;
  final int? costMonetari;
  final int? costTemporal;
  final int? impacte;

  const IncidenciaSolucioItem({
    required this.id,
    required this.descripcio,
    required this.eficacia,
    required this.costMonetari,
    required this.costTemporal,
    required this.impacte,
  });

  factory IncidenciaSolucioItem.fromMap(Map<String, dynamic> map) {
    return IncidenciaSolucioItem(
      id: _asInt(map['id']),
      descripcio: _asString(map['descripcio']) ?? '',
      eficacia: _asIntOrNull(map['eficacia']),
      costMonetari: _asIntOrNull(map['cost_monetari']),
      costTemporal: _asIntOrNull(map['cost_temporal']),
      impacte: _asIntOrNull(map['impacte']),
    );
  }
}

class IncidenciaProfileData {
  final Incidencia incidencia;
  final Obra? obra;
  final Tasca? tasca;
  final List<IncidenciaSolucioItem> solucions;

  const IncidenciaProfileData({
    required this.incidencia,
    required this.obra,
    required this.tasca,
    required this.solucions,
  });

  factory IncidenciaProfileData.fromMap(Map<String, dynamic> map) {
    return IncidenciaProfileData(
      incidencia: Incidencia.fromMap(map),
      obra: map['obra'] != null ? Obra.fromMap(map['obra']) : null,
      tasca: map['tasca'] != null ? Tasca.fromMap(map['tasca']) : null,
      solucions: _mapList(
        map['solucions'],
        IncidenciaSolucioItem.fromMap,
      ),
    );
  }
}

String? _encodeDate(DateTime? value) {
  if (value == null) return null;
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class IncidenciaObraFilterOption {
  final int id;
  final String nom;

  const IncidenciaObraFilterOption({
    required this.id,
    required this.nom,
  });
}

