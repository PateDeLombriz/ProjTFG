import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/services/geocoding_services.dart';
import 'package:front_end/shared/screen/map_selector_screen.dart';
import 'package:latlong2/latlong.dart';

class UbicacioMapPreview extends StatelessWidget {
  const UbicacioMapPreview({
    super.key,
    required this.ubicacio,
    this.height = 180,
    this.zoomInicial = 14,
    this.borderRadius = 18,
    this.permetSeleccionarEnObrir = false,
    this.onUbicacioSeleccionada,
  });

  final ObraUbicacioInfo? ubicacio;
  final double height;
  final double zoomInicial;
  final double borderRadius;

  /// false: si es toca el preview, obre pantalla només de visualització.
  /// true: si es toca el preview, obre pantalla que permet seleccionar punt.
  final bool permetSeleccionarEnObrir;

  /// Només s’usa si permetSeleccionarEnObrir és true.
  final ValueChanged<ObraUbicacioInfo>? onUbicacioSeleccionada;

  LatLng? get _punt {
    final lat = ubicacio?.latitud;
    final lon = ubicacio?.longitud;

    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }

  String get _resumUbicacio {
    final value = ubicacio;
    if (value == null) return 'Ubicació no definida';

    final resum = GeocodingService.buildAddressQuery(value);
    return resum.isEmpty ? 'Ubicació sense adreça detallada' : resum;
  }

  Future<void> _obrirMapa(BuildContext context) async {
    final selected = await Navigator.of(context).push<ObraUbicacioInfo>(
      MaterialPageRoute(
        builder: (_) => UbicacioSelectorScreen(
          ubicacioInicial: ubicacio,
          puntInicial: _punt,
          zoomInicial: zoomInicial,
          permetSeleccionar: permetSeleccionarEnObrir,
        ),
      ),
    );

    if (selected != null && permetSeleccionarEnObrir) {
      onUbicacioSeleccionada?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final punt = _punt;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: punt == null
                  ? _UbicacioMapPreviewEmptyState(
                      message: permetSeleccionarEnObrir
                          ? 'Toca per seleccionar una ubicació'
                          : 'Aquesta obra no té coordenades',
                    )
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: punt,
                        initialZoom: zoomInicial,

                        /// Això és la clau:
                        /// - tap simple: obre la pantalla completa
                        /// - moure o fer zoom: queda com a mapa petit
                        onTap: (_, __) => _obrirMapa(context),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.front_end',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: punt,
                              width: 42,
                              height: 42,
                              child: Icon(
                                Icons.location_pin,
                                size: 42,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            if (punt == null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _obrirMapa(context),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _UbicacioMapPreviewLabel(
                text: _resumUbicacio,
                icon: permetSeleccionarEnObrir
                    ? Icons.edit_location_alt_outlined
                    : Icons.open_in_full_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UbicacioMapPreviewEmptyState extends StatelessWidget {
  const _UbicacioMapPreviewEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerHighest.withOpacity(0.65),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.map_outlined,
            size: 36,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UbicacioMapPreviewLabel extends StatelessWidget {
  const _UbicacioMapPreviewLabel({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: scheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}