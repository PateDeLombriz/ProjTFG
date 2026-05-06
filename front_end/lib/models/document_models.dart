class DocumentObraItem {
  final int id;
  final int idObra;
  final int idCreador;
  final String pathDoc;
  final String format;
  final double mida;
  final String? comentari;
  final DateTime? dataPujada;
  final String tipus;

  const DocumentObraItem({
    required this.id,
    required this.idObra,
    required this.idCreador,
    required this.pathDoc,
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
      idCreador: _asInt(map['id_creador']),
      pathDoc: _asString(map['path_doc']),
      format: _asString(map['format']),
      mida: _asDouble(map['mida']),
      comentari: map['comentari']?.toString(),
      dataPujada: _asDateTime(map['data_pujada']),
      tipus: _asString(map['tipus']).isEmpty
          ? 'general'
          : _asString(map['tipus']),
    );
  }
    Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_obra': idObra,
      'id_creador': idCreador,
      'path_doc': pathDoc,
      'format': format,
      'mida': mida,
      'comentari': comentari,
      'data_pujada': dataPujada?.toIso8601String(),
      'tipus': tipus,
    };
  }

  String get displayName {
    final comment = comentari?.trim();
    if (comment != null && comment.isNotEmpty) return comment;

    final cleanPath = pathDoc.split('?').first;
    final fileName = cleanPath.split('/').last.trim();

    if (fileName.isNotEmpty) return fileName;
    return 'Document #$id';
  }

  String get fileName {
    final cleanPath = pathDoc.split('?').first;
    final fileName = cleanPath.split('/').last.trim();
    if (fileName.isNotEmpty) return fileName;
    return 'document_$id.${format.toLowerCase()}';
  }

  String get midaLabel {
    return '${mida.toStringAsFixed(2)} MB';
  }

  String get formatLabel {
    final value = format.trim().toUpperCase();
    return value.isEmpty ? 'DOC' : value;
  }

  String get dataLabel {
    final value = dataPujada;
    if (value == null) return 'Data no disponible';

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _asDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class DocumentObraUploadRequest {
  final int obraId;
  final String tipus;
  final String? comentari;

  const DocumentObraUploadRequest({
    required this.obraId,
    required this.tipus,
    this.comentari,
  });
}


class DocumentObraListData {
  final List<DocumentObraItem> documents;

  const DocumentObraListData({
    required this.documents,
  });

  factory DocumentObraListData.fromList(List<Map<String, dynamic>> raw) {
    final documents = raw
        .map(DocumentObraItem.fromMap)
        .toList()
      ..sort((a, b) {
        final ad = a.dataPujada;
        final bd = b.dataPujada;

        if (ad == null && bd == null) return b.id.compareTo(a.id);
        if (ad == null) return 1;
        if (bd == null) return -1;

        return bd.compareTo(ad);
      });

    return DocumentObraListData(documents: documents);
  }

  int get total => documents.length;

  List<String> get tipusDisponibles {
    final values = documents
        .map((doc) => doc.tipus.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }
}

class DocumentSessionContext {
  final String tipus;
  final int subjectId;

  const DocumentSessionContext({
    required this.tipus,
    required this.subjectId,
  });

  bool get isEmpresa => tipus == 'empresa';
  bool get isTreballador => tipus == 'treballador';

  bool canModify(DocumentObraItem document) {
    if (isEmpresa) return true;
    if (isTreballador) return document.idCreador == subjectId;
    return false;
  }
}