import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:front_end/models/obra_models.dart';

class UbicacioService {
  static const String _reverseGeocodeBaseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  static Future<ObraUbicacioInfo> reverseGeocode(LatLng punt) async {
    final uri = Uri.parse(
      '$_reverseGeocodeBaseUrl'
      '?format=jsonv2'
      '&lat=${punt.latitude}'
      '&lon=${punt.longitude}'
      '&addressdetails=1',
    );

    try {
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'TFG-Toni/1.0',
        },
      );

      if (response.statusCode != 200) {
        return _fallbackUbicacio(punt);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      return ObraUbicacioInfo(
        idUbicacio: 0,
        adreca: address?['road']?.toString() ?? '',
        ciutat: address?['city']?.toString() ??
            address?['town']?.toString() ??
            address?['village']?.toString() ??
            '',
        codiPostal: address?['postcode']?.toString() ?? '',
        provincia: address?['state']?.toString() ?? '',
        pais: address?['country']?.toString() ?? 'Espanya',
        latitud: _roundCoord(punt.latitude),
        longitud: _roundCoord(punt.longitude),
      );
    } catch (_) {
      return _fallbackUbicacio(punt);
    }
  }

  static ObraUbicacioInfo _fallbackUbicacio(LatLng punt) {
    return ObraUbicacioInfo(
      idUbicacio: 0,
      adreca: '',
      ciutat: '',
      codiPostal: '',
      provincia: '',
      pais: 'Espanya',
      latitud: _roundCoord(punt.latitude),
      longitud: _roundCoord(punt.longitude),
    );
  }

  static double _roundCoord(double value) {
    return double.parse(value.toStringAsFixed(7));
  }
}