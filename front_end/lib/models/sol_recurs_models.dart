class SolRecurs {
  final int id;
  final int idObra;
  final int idRecurs;
  final int quantitat;
  final DateTime? dataNecessitat;
  final String? comentari;
  final DateTime? dataEntrega;
  final DateTime? dataCreacio;
  final String? proveidor;

  const SolRecurs({
    required this.id,
    required this.idObra,
    required this.idRecurs,
    required this.quantitat,
    required this.dataNecessitat,
    required this.comentari,
    required this.dataEntrega,
    required this.dataCreacio,
    required this.proveidor,
  });

  factory SolRecurs.fromMap(Map<String, dynamic> map) {
    return SolRecurs(
      id: _asInt(map['id']),
      idObra: _asInt(map['id_obra']),
      idRecurs: _asInt(map['id_recurs']),
      quantitat: _asInt(map['quantitat']),
      dataNecessitat: _asDate(map['data_necessitat']),
      comentari: _asString(map['comentari']),
      dataEntrega: _asDate(map['data_entrega']),
      dataCreacio: _asDateTime(map['data_creacio']),
      proveidor: _asString(map['proveidor']),
    );
  }
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}