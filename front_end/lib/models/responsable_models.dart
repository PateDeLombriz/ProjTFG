class ResponsableObra {
  final int id;
  final int idObra;
  final int idTreballador;
  final DateTime? dataInici;
  final DateTime? dataFi;

  const ResponsableObra({
    required this.id,
    required this.idObra,
    required this.idTreballador,
    required this.dataInici,
    required this.dataFi,
  });

  factory ResponsableObra.fromMap(Map<String, dynamic> map) {
    return ResponsableObra(
      id: _asInt(map['id']),
      idObra: _asInt(map['id_obra']),
      idTreballador: _asInt(map['id_treballador']),
      dataInici: _asDate(map['data_inici']),
      dataFi: _asDate(map['data_fi']),
    );
  }
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