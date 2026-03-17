class Tasca {
  final int id;
  final int idObra;
  final int? idTascaPare;
  final String descripcio;
  final DateTime? dataInici;
  final DateTime? dataFi;
  final int prioritat;
  final bool visibilitatTasca;

  const Tasca({
    required this.id,
    required this.idObra,
    required this.idTascaPare,
    required this.descripcio,
    required this.dataInici,
    required this.dataFi,
    required this.prioritat,
    required this.visibilitatTasca,
  });

  factory Tasca.fromMap(Map<String, dynamic> map) {
    return Tasca(
      id: _asInt(map['id']),
      idObra: _asInt(map['id_obra']),
      idTascaPare: _asIntOrNull(map['id_tasca_pare']),
      descripcio: _asString(map['descripcio']) ?? '—',
      dataInici: _asDate(map['data_inici']),
      dataFi: _asDate(map['data_fi']),
      prioritat: _asInt(map['prioritat']),
      visibilitatTasca: _asBool(map['visibilitat_tasca']),
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}