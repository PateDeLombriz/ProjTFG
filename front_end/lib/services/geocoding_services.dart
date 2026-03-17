//és una comunicació amb un servei extern de geocoding
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ubicacio.dart';

class GeocodingService {

  static Future<Ubicacio?> reverseGeocode(
      double lat, double lon) async {

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2'
      '&lat=$lat'
      '&lon=$lon'
      '&addressdetails=1',
    );

    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'TFG-Toni/1.0',
      },
    );

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);

    return Ubicacio.fromNominatim(data, lat, lon);
  }
}