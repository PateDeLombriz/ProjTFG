import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/services/geocoding_services.dart';
import 'package:latlong2/latlong.dart';

class UbicacioSelectorBody extends StatefulWidget {
  const UbicacioSelectorBody({
    super.key,
    this.ubicacioInicial,
    this.puntInicial,
    this.centrePerDefecte = const LatLng(39.5696, 2.6502),
    this.zoomInicial = 13,
    this.permetSeleccionar = false,
    this.mostrarAccions = true,
    this.onCancel,
    this.onConfirmar,
  });

  final ObraUbicacioInfo? ubicacioInicial;
  final LatLng? puntInicial;
  final LatLng centrePerDefecte;
  final double zoomInicial;

  /// Si és false, el mapa només serveix per visualitzar.
  /// Si és true, tocar el mapa selecciona un punt.
  final bool permetSeleccionar;

  /// Normalment true dins la screen de selecció.
  /// Pot ser false si vols incrustar aquest body dins una altra pantalla.
  final bool mostrarAccions;

  final VoidCallback? onCancel;
  final ValueChanged<ObraUbicacioInfo>? onConfirmar;

  @override
  State<UbicacioSelectorBody> createState() => _UbicacioSelectorBodyState();
}

class _UbicacioSelectorBodyState extends State<UbicacioSelectorBody> {
  LatLng? _puntSeleccionat;
  ObraUbicacioInfo? _ubicacioSeleccionada;
  String _resumAdreca = 'Ubicació no seleccionada';
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

    if (ubicacio == null) {
      _resumAdreca = widget.permetSeleccionar
          ? 'Toca el mapa per seleccionar una ubicació'
          : 'Aquesta obra no té ubicació definida';
      return;
    }

    _resumAdreca = _resumDesDeUbicacio(ubicacio);
    _ubicacioSeleccionada = ubicacio;

    if (ubicacio.latitud != null && ubicacio.longitud != null) {
      _puntSeleccionat = LatLng(
        ubicacio.latitud!,
        ubicacio.longitud!,
      );
    }
  }

  String _resumDesDeUbicacio(ObraUbicacioInfo ubicacio) {
    final resum = GeocodingService.buildAddressQuery(ubicacio);
    return resum.isEmpty ? 'Ubicació existent sense coordenades' : resum;
  }

  Future<void> _onTapMapa(LatLng punt) async {
    if (!widget.permetSeleccionar) return;

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
    final ubicacio = _ubicacioSeleccionada;
    if (ubicacio == null) return;
    widget.onConfirmar?.call(ubicacio);
  }

  @override
  Widget build(BuildContext context) {
    final centre = _puntSeleccionat ?? widget.centrePerDefecte;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: centre,
              initialZoom: widget.zoomInicial,
              onTap: widget.permetSeleccionar
                  ? (_, point) => _onTapMapa(point)
                  : null,
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
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.location_pin,
                        size: 44,
                        color: scheme.primary,
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
              Icon(
                Icons.place_outlined,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _resumAdreca,
                  style: TextStyle(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.permetSeleccionar &&
            widget.ubicacioInicial != null &&
            widget.ubicacioInicial!.latitud == null &&
            widget.ubicacioInicial!.longitud == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'La ubicació existent no té coordenades. Toca el mapa per fixar-ne unes de noves.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        if (widget.permetSeleccionar && widget.mostrarAccions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel·lar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_ubicacioSeleccionada == null || _carregantAdreca)
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
    );
  }
}