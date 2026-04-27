import 'dart:convert';

import 'package:front_end/models/obra_models.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  const GeocodingService._();

  static const String _userAgent = 'TFG-Toni/1.0';
  static const String _defaultCountry = 'Espanya';

  static Future<ObraUbicacioInfo?> reverseGeocode(
    double lat,
    double lon,
  ) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2'
      '&lat=$lat'
      '&lon=$lon'
      '&addressdetails=1',
    );

    try {
      final res = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': _userAgent,
        },
      );

      if (res.statusCode != 200) {
        return fromCoordinates(
          lat: lat,
          lon: lon,
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return fromCoordinates(
          lat: lat,
          lon: lon,
        );
      }

      final address = decoded['address'] is Map
          ? Map<String, dynamic>.from(decoded['address'] as Map)
          : null;

      return ObraUbicacioInfo(
        idUbicacio: 0,
        adreca: address?['road']?.toString() ?? '',
        ciutat: address?['city']?.toString() ??
            address?['town']?.toString() ??
            address?['village']?.toString() ??
            '',
        codiPostal: address?['postcode']?.toString() ?? '',
        provincia: address?['state']?.toString() ?? '',
        pais: address?['country']?.toString() ?? _defaultCountry,
        latitud: _roundCoord(lat),
        longitud: _roundCoord(lon),
      );
    } catch (_) {
      return fromCoordinates(
        lat: lat,
        lon: lon,
      );
    }
  }

  static Future<LatLng?> geocodeAddress(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=jsonv2'
      '&limit=1'
      '&q=${Uri.encodeQueryComponent(normalized)}',
    );

    try {
      final res = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': _userAgent,
        },
      );

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);
      if (decoded is! List || decoded.isEmpty) return null;

      final first = decoded.first;
      if (first is! Map) return null;

      final map = Map<String, dynamic>.from(first);
      final lat = _asDoubleOrNull(map['lat']);
      final lon = _asDoubleOrNull(map['lon']);

      if (lat == null || lon == null) return null;

      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  static Future<ObraUbicacioInfo?> geocodeToUbicacioInfo(String query) async {
    final point = await geocodeAddress(query);
    if (point == null) return null;

    return reverseGeocode(point.latitude, point.longitude);
  }

  static ObraUbicacioInfo fromCoordinates({
    required double lat,
    required double lon,
    int idUbicacio = 0,
    String adreca = '',
    String ciutat = '',
    String codiPostal = '',
    String provincia = '',
    String pais = _defaultCountry,
  }) {
    return ObraUbicacioInfo(
      idUbicacio: idUbicacio,
      adreca: adreca,
      ciutat: ciutat,
      codiPostal: codiPostal,
      provincia: provincia,
      pais: pais,
      latitud: _roundCoord(lat),
      longitud: _roundCoord(lon),
    );
  }

  static String buildAddressQuery(ObraUbicacioInfo? info) {
    if (info == null) return '';

    final parts = <String>[
      _cleanText(info.adreca),
      _cleanText(info.codiPostal),
      _cleanText(info.ciutat),
      _cleanText(info.provincia),
      _cleanText(info.pais),
    ].where((e) => e.isNotEmpty).toList();

    return parts.join(', ');
  }

  static LatLng? toLatLng(ObraUbicacioInfo? info) {
    final lat = info?.latitud;
    final lon = info?.longitud;

    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  static bool hasCoordinates(ObraUbicacioInfo? info) {
    return info?.latitud != null && info?.longitud != null;
  }

  static bool hasAddressData(ObraUbicacioInfo? info) {
    if (info == null) return false;

    return _cleanText(info.adreca).isNotEmpty ||
        _cleanText(info.ciutat).isNotEmpty ||
        _cleanText(info.codiPostal).isNotEmpty ||
        _cleanText(info.provincia).isNotEmpty ||
        _cleanText(info.pais).isNotEmpty;
  }

  static double _roundCoord(double value) {
    return double.parse(value.toStringAsFixed(7));
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return double.tryParse(text);
  }

  static String _cleanText(String? value) {
    if (value == null) return '';
    return value.trim();
  }
}