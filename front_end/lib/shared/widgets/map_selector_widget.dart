import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:front_end/shared/services/geocoding_services.dart';
import 'package:latlong2/latlong.dart';

import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/services/geocoding_services.dart';

class UbicacioSelectorScreen extends StatefulWidget {
  const UbicacioSelectorScreen({
    super.key,
    this.ubicacioInicial,
    this.puntInicial,
    this.centrePerDefecte = const LatLng(39.5696, 2.6502),
    this.zoomInicial = 13,
  });

  final ObraUbicacioInfo? ubicacioInicial;
  final LatLng? puntInicial;
  final LatLng centrePerDefecte;
  final double zoomInicial;

  @override
  State<UbicacioSelectorScreen> createState() => _UbicacioSelectorScreenState();
}

class _UbicacioSelectorScreenState extends State<UbicacioSelectorScreen> {
  LatLng? _puntSeleccionat;
  ObraUbicacioInfo? _ubicacioSeleccionada;
  String _resumAdreca = 'Toca el mapa per seleccionar una ubicació';
  bool _carregantAdreca = false;

  @override
  void initState() {
    super.initState();
    _configurarValorInicial();
  }

  void _configurarValorInicial() {
    final punt = widget.puntInicial;
    final ubicacio = widget.ubicacioInicial;

    if (punt != null) {
      _puntSeleccionat = punt;
      _ubicacioSeleccionada = ubicacio ??
          GeocodingService.fromCoordinates(
            lat: punt.latitude,
            lon: punt.longitude,
          );

      _resumAdreca = ubicacio != null
          ? _resumDesDeUbicacio(ubicacio)
          : 'Punt inicial carregat';
      return;
    }

    if (ubicacio == null) return;

    _resumAdreca = _resumDesDeUbicacio(ubicacio);

    if (ubicacio.latitud != null && ubicacio.longitud != null) {
      _puntSeleccionat = LatLng(
        ubicacio.latitud!,
        ubicacio.longitud!,
      );
      _ubicacioSeleccionada = ubicacio;
    }
  }

  String _resumDesDeUbicacio(ObraUbicacioInfo ubicacio) {
    final resum = GeocodingService.buildAddressQuery(ubicacio);
    return resum.isEmpty ? 'Ubicació existent sense coordenades' : resum;
  }

  Future<void> _onTapMapa(LatLng punt) async {
    setState(() {
      _puntSeleccionat = punt;
      _ubicacioSeleccionada = null;
      _carregantAdreca = true;
      _resumAdreca = 'Carregant adreça...';
    });

    final ubicacio = await GeocodingService.reverseGeocode(
      punt.latitude,
      punt.longitude,
    );

    if (!mounted) return;

    final resolved = ubicacio ??
        GeocodingService.fromCoordinates(
          lat: punt.latitude,
          lon: punt.longitude,
        );

    setState(() {
      _ubicacioSeleccionada = resolved;
      _carregantAdreca = false;
      _resumAdreca = _resumDesDeUbicacio(resolved);
    });
  }

  void _confirmarSeleccio() {
    if (_ubicacioSeleccionada == null) return;
    Navigator.of(context).pop(_ubicacioSeleccionada);
  }

  @override
  Widget build(BuildContext context) {
    final centre = _puntSeleccionat ?? widget.centrePerDefecte;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicació'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: widget.zoomInicial,
                  onTap: (_, point) => _onTapMapa(point),
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
                          child: const Icon(
                            Icons.location_pin,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_resumAdreca),
                  ),
                ],
              ),
            ),
            if (widget.ubicacioInicial != null &&
                widget.ubicacioInicial!.latitud == null &&
                widget.ubicacioInicial!.longitud == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'La ubicació existent no té coordenades. Toca el mapa per fixar-ne unes de noves.',
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel·lar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_ubicacioSeleccionada == null || _carregantAdreca)
                          ? null
                          : _confirmarSeleccio,
                      child: _carregantAdreca
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Utilitzar aquesta ubicació'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ObraUbicacioInfo?> mostrarSelectorUbicacio(
  BuildContext context, {
  ObraUbicacioInfo? ubicacioInicial,
  LatLng? puntInicial,
}) {
  return Navigator.of(context).push<ObraUbicacioInfo>(
    MaterialPageRoute(
      builder: (_) => UbicacioSelectorScreen(
        ubicacioInicial: ubicacioInicial,
        puntInicial: puntInicial,
      ),
    ),
  );
}