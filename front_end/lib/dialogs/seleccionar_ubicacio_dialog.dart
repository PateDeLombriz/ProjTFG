import 'package:flutter/material.dart';
import '../models/ubicacio.dart';
import '../widgets/map_selector_widget.dart';

Future<Ubicacio?> mostrarSelectorUbicacio(BuildContext context) {
  return showDialog<Ubicacio>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return const Dialog(
        child: SizedBox(
          height: 500,
          width: 400,
          child: MapSelectorWidget(),
        ),
      );
    },
  );
}