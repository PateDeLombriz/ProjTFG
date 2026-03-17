import 'package:flutter/material.dart';

Future<bool?> showObraDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar obra'),
      content: const Text('Aquesta acció és irreversible. Vols continuar?'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel·la'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}

void showObraSnack(
  BuildContext context,
  String message, {
  bool success = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? Colors.green : null,
    ),
  );
}