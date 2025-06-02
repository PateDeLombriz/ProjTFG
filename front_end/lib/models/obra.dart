

// Clase Dart que representa una Obra, alineada con el modelo Django
class Obra {
  late int Id;                         // Identificador único de la obra
  late String Nom;                    // Nombre de la obra
  late String? Ubicacio;              // Ubicación de la obra (opcional)
  late DateTime DataInici;            // Fecha de inicio
  late DateTime? DataPrevFi;          // Fecha prevista de finalización (opcional)
  late double? Pressupost;            // Presupuesto (opcional)
  late String? Descripcio;            // Descripción (opcional)
  late String Estat;                  // Estado actual

  // Constructor
  Obra({
    required this.Id,
    required this.Nom,
    this.Ubicacio,
    required this.DataInici,
    this.DataPrevFi,
    this.Pressupost,
    this.Descripcio,
    required this.Estat,
  });

  // Fábrica que crea una instancia desde JSON
  factory Obra.fromJson(dynamic json) {
    return Obra(
      Id: json['Id'] as int,
      Nom: json['Nom'] as String,
      Ubicacio: json['Ubicacio'] as String?,
      DataInici: DateTime.parse(json['Data_inici']),
      DataPrevFi: json['Data_prev_fi'] != null
          ? DateTime.parse(json['Data_prev_fi'])
          : null,
      Pressupost: json['Pressupost'] != null
          ? double.parse(json['Pressupost'].toString())
          : null,
      Descripcio: json['Descripcio'] as String?,
      Estat: json['Estat'] as String,
    );
  }
}