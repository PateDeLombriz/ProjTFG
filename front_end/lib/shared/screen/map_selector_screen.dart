import 'package:flutter/material.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/utils/ubicacio_selector_body.dart';
import 'package:latlong2/latlong.dart';

class UbicacioSelectorScreen extends StatelessWidget {
  const UbicacioSelectorScreen({
    super.key,
    this.ubicacioInicial,
    this.puntInicial,
    this.centrePerDefecte = const LatLng(39.5696, 2.6502),
    this.zoomInicial = 13,
    this.permetSeleccionar = false,
    this.title,
  });

  final ObraUbicacioInfo? ubicacioInicial;
  final LatLng? puntInicial;
  final LatLng centrePerDefecte;
  final double zoomInicial;

  /// false = només visualitzar mapa.
  /// true = permet tocar el mapa i retornar una ubicació.
  final bool permetSeleccionar;

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title ??
              (permetSeleccionar
                  ? 'Seleccionar ubicació'
                  : 'Ubicació de l’obra'),
        ),
      ),
      body: SafeArea(
        child: UbicacioSelectorBody(
          ubicacioInicial: ubicacioInicial,
          puntInicial: puntInicial,
          centrePerDefecte: centrePerDefecte,
          zoomInicial: zoomInicial,
          permetSeleccionar: permetSeleccionar,
          mostrarAccions: permetSeleccionar,
          onCancel: () => Navigator.of(context).pop(),
          onConfirmar: (ubicacio) {
            Navigator.of(context).pop(ubicacio);
          },
        ),
      ),
    );
  }
}

Future<ObraUbicacioInfo?> mostrarSelectorUbicacio(
  BuildContext context, {
  ObraUbicacioInfo? ubicacioInicial,
  LatLng? puntInicial,
  bool permetSeleccionar = true,
}) {
  return Navigator.of(context).push<ObraUbicacioInfo>(
    MaterialPageRoute(
      builder: (_) => UbicacioSelectorScreen(
        ubicacioInicial: ubicacioInicial,
        puntInicial: puntInicial,
        permetSeleccionar: permetSeleccionar,
      ),
    ),
  );
}

Future<void> mostrarMapaUbicacio(
  BuildContext context, {
  ObraUbicacioInfo? ubicacio,
  LatLng? puntInicial,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => UbicacioSelectorScreen(
        ubicacioInicial: ubicacio,
        puntInicial: puntInicial,
        permetSeleccionar: false,
      ),
    ),
  );
}