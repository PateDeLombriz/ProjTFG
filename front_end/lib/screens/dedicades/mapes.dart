import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SeleccionarUbicacioScreen extends StatefulWidget {
  const SeleccionarUbicacioScreen({super.key});

  @override
  State<SeleccionarUbicacioScreen> createState() =>
      _SeleccionarUbicacioScreenState();
}

class _SeleccionarUbicacioScreenState extends State<SeleccionarUbicacioScreen> {
  LatLng? _puntSeleccionat;
  String _resumAdreca = 'Toca el mapa per seleccionar una ubicació';
  Map<String, dynamic>? _ubicacioTemporal;

  Future<void> _onTapMapa(LatLng punt) async {
    setState(() {
      _puntSeleccionat = punt;
      _resumAdreca = 'Carregant adreça...';
      _ubicacioTemporal = null;
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2'
        '&lat=${punt.latitude}'
        '&lon=${punt.longitude}'
        '&addressdetails=1',
      );

      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'TFG-Toni/1.0',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        final adrecaCompleta = (data['display_name'] ?? '').toString();

        setState(() {
          _resumAdreca = adrecaCompleta;

          _ubicacioTemporal = {
            'adreca': address?['road']?.toString() ?? '',
            'ciutat': address?['city']?.toString() ??
                address?['town']?.toString() ??
                address?['village']?.toString() ??
                '',
            'codi_postal': address?['postcode']?.toString() ?? '',
            'provincia': address?['state']?.toString() ?? '',
            'pais': address?['country']?.toString() ?? 'Espanya',
            'latitud': punt.latitude.toStringAsFixed(7),
            'longitud': punt.longitude.toStringAsFixed(7),
            'display_name': adrecaCompleta,
          };
        });
      } else {
        setState(() {
          _resumAdreca = 'No s\'ha pogut obtenir l\'adreça';
          _ubicacioTemporal = {
            'adreca': '',
            'ciutat': '',
            'codi_postal': '',
            'provincia': '',
            'pais': 'Espanya',
            'latitud': punt.latitude.toStringAsFixed(7),
            'longitud': punt.longitude.toStringAsFixed(7),
            'display_name': '',
          };
        });
      }
    } catch (_) {
      setState(() {
        _resumAdreca = 'No s\'ha pogut obtenir l\'adreça';
        _ubicacioTemporal = {
          'adreca': '',
          'ciutat': '',
          'codi_postal': '',
          'provincia': '',
          'pais': 'Espanya',
          'latitud': punt.latitude,
          'longitud': punt.longitude,
          'display_name': '',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicació')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(39.5696, 2.6502),
                initialZoom: 13,
                onTap: (tapPosition, point) => _onTapMapa(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.front_end',
                ),
                if (_puntSeleccionat != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _puntSeleccionat!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_resumAdreca),
          ),
          ElevatedButton(
            onPressed: _ubicacioTemporal == null
                ? null
                : () {
                    Navigator.pop(context, _ubicacioTemporal);
                  },
            child: const Text('Usar aquesta ubicació'),
          ),
        ],
      ),
    );
  }
}
