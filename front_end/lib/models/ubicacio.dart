class Ubicacio {
  final String adreca;
  final String ciutat;
  final String codiPostal;
  final String provincia;
  final String pais;
  final double latitud;
  final double longitud;
  final String displayName;

  Ubicacio({
    required this.adreca,
    required this.ciutat,
    required this.codiPostal,
    required this.provincia,
    required this.pais,
    required this.latitud,
    required this.longitud,
    required this.displayName,
  });

  factory Ubicacio.fromNominatim(
    Map<String, dynamic> data,
    double lat,
    double lon,
  ) {
    final address = data['address'] as Map<String, dynamic>?;

    return Ubicacio(
      adreca: address?['road'] ?? '',
      ciutat: address?['city'] ??
          address?['town'] ??
          address?['village'] ??
          '',
      codiPostal: address?['postcode'] ?? '',
      provincia: address?['state'] ?? '',
      pais: address?['country'] ?? 'Espanya',
      latitud: lat,
      longitud: lon,
      displayName: data['display_name'] ?? '',
    );
  }

    // Aquest mètode converteix l'objecte a Map per poder fer jsonEncode
  Map<String,dynamic> toJson() {
    return {
      'adreca': adreca,
      'ciutat': ciutat,
      'codi_postal': codiPostal,
      'provincia': provincia,
      'pais': pais,
      'latitud': latitud,
      'longitud': longitud,
      'display_name': displayName,
    };
}
}