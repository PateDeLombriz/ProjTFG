class DocumentObraItem {
  final int id;
  final int idObra;
  final String? idCreador;
  final String nom;
  final String? format;
  final double mida;
  final String? comentari;
  final DateTime? dataPujada;
  final String? tipus;

  const DocumentObraItem({
    required this.id,
    required this.idObra,
    required this.idCreador,
    required this.nom,
    required this.format,
    required this.mida,
    required this.comentari,
    required this.dataPujada,
    required this.tipus,
  });

  factory DocumentObraItem.fromMap(Map<String, dynamic> map) {
    return DocumentObraItem(
      id: _asInt(map['id']),
      idObra: _asInt(map['id_obra']),
      idCreador: _asString(map['id_creador']),
      nom: _asString(map['nom']) ?? '—',
      format: _asString(map['format']),
      mida: _asDouble(map['mida']),
      comentari: _asString(map['comentari']),
      dataPujada: _asDateTime(map['data_pujada']),
      tipus: _asString(map['tipus']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_obra': idObra,
      'id_creador': idCreador,
      'nom': nom,
      'format': format,
      'mida': mida,
      'comentari': comentari,
      'data_pujada': dataPujada,
      'tipus': tipus,
    };
  }

  Map<String, dynamic> toDocumentMap() => toMap();
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

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
