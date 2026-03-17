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
    );
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
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}