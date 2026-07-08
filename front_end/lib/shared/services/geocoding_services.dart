import 'dart:convert';

import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeocodingService {
  const GeocodingService._();

  static const String _userAgent = 'TFG-Toni/1.0';
  static const String _defaultCountry = 'Espanya';
  static final Set<int> _coordinateUpdateInProgress = <int>{};

  static Future<ObraUbicacioInfo?> reverseGeocode(
      double lat, double lon) async {
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
        return fromCoordinates(lat: lat, lon: lon);
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return fromCoordinates(lat: lat, lon: lon);
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
      return fromCoordinates(lat: lat, lon: lon);
    }
  }

//Aquest metode el que s'encarrega es de fer la peticio a l'api de geocoding amb la query que li passem, si no troba res retorna null,
// si troba alguna cosa retorna un objecte LatLng amb les coordenades.
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
      print(
        '[GEOCODING REQUEST] query="$query" status=${res.statusCode} body=${res.body}',
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
    } catch (e) {
      print('[GEOCODING REQUEST ERROR] query="$normalized" error=$e');
      return null;
    }
  }

//Metodo llamado desde el widget este metodo se encarga de resolver la ubicacion para el mapa de vista previa,
// primero intenta obtener las coordenadas existentes, si no las tiene intenta geocodificar la direccion y si lo logra persiste las coordenadas en el backend.
  static Future<LatLng?> resolvePointForMapPreview(
    ObraUbicacioInfo info,
  ) async {
    final existingPoint = toLatLng(info);
    if (existingPoint != null) {
      return existingPoint;
    }

    if (!hasAddressData(info)) {
      return null;
    }

    final resolvedPoint = await geocodeAddressWithFallback(info);
    if (resolvedPoint == null) {
      return null;
    }

    await persistCoordinatesIfMissing(
      info: info,
      point: resolvedPoint,
    );

    return resolvedPoint;
  }

  static Future<LatLng?> geocodeAddressWithFallback(
    ObraUbicacioInfo info,
  ) async {
    final queries = _buildAddressQueryCandidates(info);

    for (final query in queries) {
      final point = await geocodeAddress(query);

      print('[GEOCODING FALLBACK] query="$query" point=$point');

      if (point != null) {
        return point;
      }

      await Future.delayed(const Duration(milliseconds: 900));
    }

    return null;
  }

  //Guarda less coordenades a la BD, si ja existeixen no fa res, si no existeixen i ja s'està fent una petició per a aquesta ubicació, tampoc fa res.
  static Future<void> persistCoordinatesIfMissing({
    required ObraUbicacioInfo info,
    required LatLng point,
  }) async {
    if (info.idUbicacio <= 0) {
      return;
    }

    if (hasCoordinates(info)) {
      return;
    }

    if (_coordinateUpdateInProgress.contains(info.idUbicacio)) {
      return;
    }

    _coordinateUpdateInProgress.add(info.idUbicacio);

    try {
      final token = await _requireToken();

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/ubicacio/${info.idUbicacio}/'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'latitud': _roundCoord(point.latitude),
          'longitud': _roundCoord(point.longitude),
        }),
      );

      print(
        '[UBICACIO COORDS PATCH] '
        'id=${info.idUbicacio} '
        'status=${response.statusCode} '
        'body=${response.body}',
      );
    } catch (e) {
      print(
        '[UBICACIO COORDS PATCH ERROR] '
        'id=${info.idUbicacio} '
        'error=$e',
      );
    } finally {
      _coordinateUpdateInProgress.remove(info.idUbicacio);
    }
  }

  static Future<ObraUbicacioInfo?> geocodeToUbicacioInfo(String query) async {
    final point = await geocodeAddress(query);
    print(
      '[GEOCODING RESULT] query="$query" point=$point',
    );
    if (point == null) return null;

    return reverseGeocode(point.latitude, point.longitude);
  }

  /// Crea una ubicació nova al backend i retorna l'objecte amb id_ubicacio real.
  static Future<ObraUbicacioInfo> createUbicacio(ObraUbicacioInfo info) async {
    final token = await _requireToken();

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/ubicacio/'),
      headers: _authHeaders(token),
      body: jsonEncode(_toBackendPayload(info)),
    );

    if (response.statusCode != 201) {
      throw Exception(
          _extractErrorMessage(response, 'No s’ha pogut crear la ubicació.'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('La resposta de creació de la ubicació no és vàlida.');
    }

    final created = Map<String, dynamic>.from(decoded);
    return _fromBackendMap(created, fallback: info);
  }

  /// Si la ubicació ja existeix, retorna la mateixa.
  /// Si és nova, la crea al backend i retorna la ubicació amb idUbicacio real.
  static Future<ObraUbicacioInfo> ensurePersistedUbicacio(
    ObraUbicacioInfo info,
  ) async {
    if (info.idUbicacio > 0) return info;
    return createUbicacio(info);
  }

  /// Flux convenient:
  /// text/adreça -> geocoding -> ubicació local -> POST backend -> ubicació amb id.
  static Future<ObraUbicacioInfo?> createUbicacioFromAddress(
      String query) async {
    final info = await geocodeToUbicacioInfo(query);
    if (info == null) return null;
    print('Geocoded info: $info');
    return ensurePersistedUbicacio(info);
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
  //PRimer es deixa net el text, després es normalitza la direcció per a que sigui més probable que el geocoding trobi alguna cosa,
  //// després es construeixen diferents queries amb diferents combinacions de camps i finalment es retornen les queries no buides i sense duplicats.
  static List<String> _buildAddressQueryCandidates(ObraUbicacioInfo info) {
    final adreca = _cleanText(info.adreca);
    final ciutat = _cleanText(info.ciutat);
    final codiPostal = _cleanText(info.codiPostal);
    final provincia = _cleanText(info.provincia);
    final pais = _cleanText(info.pais).isNotEmpty
        ? _cleanText(info.pais)
        : _defaultCountry;

    final normalizedAdreca = adreca
        .replaceAll(RegExp(r'\bAv\.\s*', caseSensitive: false), 'Avinguda ')
        .replaceAll(RegExp(r'\bAvda\.\s*', caseSensitive: false), 'Avinguda ')
        .replaceAll(RegExp(r'\bC/\s*', caseSensitive: false), 'Carrer ')
        .replaceAll(RegExp(r'\bC\.\s*', caseSensitive: false), 'Carrer ');

    final queries = <String>[
      buildAddressQuery(info),
      _joinQueryParts([adreca, ciutat, provincia, pais]),
      _joinQueryParts([normalizedAdreca, ciutat, provincia, pais]),
      _joinQueryParts([normalizedAdreca, ciutat, 'Mallorca', pais]),
      _joinQueryParts([adreca, ciutat, 'Mallorca', pais]),
      _joinQueryParts([codiPostal, ciutat, provincia, pais]),
    ];

    return queries
        .map((query) => query.trim())
        .where((query) => query.isNotEmpty)
        .toSet()
        .toList();
  }

  static String _joinQueryParts(List<String> parts) {
    return parts.where((part) => part.trim().isNotEmpty).join(', ');
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

  static Map<String, dynamic> _toBackendPayload(ObraUbicacioInfo info) {
    return {
      'adreca': _nullableClean(info.adreca),
      'ciutat': _nullableClean(info.ciutat),
      'codi_postal': _nullableClean(info.codiPostal),
      'provincia': _nullableClean(info.provincia),
      'pais': _nullableClean(info.pais) ?? _defaultCountry,
      'latitud': info.latitud,
      'longitud': info.longitud,
    };
  }

  static ObraUbicacioInfo _fromBackendMap(
    Map<String, dynamic> map, {
    required ObraUbicacioInfo fallback,
  }) {
    return ObraUbicacioInfo(
      idUbicacio: _asIntOrNull(map['id_ubicacio']) ??
          _asIntOrNull(map['id']) ??
          fallback.idUbicacio,
      adreca: map['adreca']?.toString() ?? fallback.adreca,
      ciutat: map['ciutat']?.toString() ?? fallback.ciutat,
      codiPostal: map['codi_postal']?.toString() ?? fallback.codiPostal,
      provincia: map['provincia']?.toString() ?? fallback.provincia,
      pais: map['pais']?.toString() ?? fallback.pais,
      latitud: _asDoubleOrNull(map['latitud']) ?? fallback.latitud,
      longitud: _asDoubleOrNull(map['longitud']) ?? fallback.longitud,
    );
  }

  static Future<String> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) return token;

    final access = prefs.getString('access')?.trim();
    if (access != null && access.isNotEmpty) return access;

    final legacy = prefs.getString('session_token')?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;

    throw Exception('No hi ha sessió guardada per crear la ubicació.');
  }

  static Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final detail =
            decoded['detail'] ?? decoded['error'] ?? decoded['message'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }

        if (decoded.isNotEmpty) return decoded.toString();
      }
    } catch (_) {}

    return fallback;
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

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  static String _cleanText(String? value) {
    if (value == null) return '';
    return value.trim();
  }

  static String? _nullableClean(String? value) {
    final cleaned = _cleanText(value);
    return cleaned.isEmpty ? null : cleaned;
  }
}
