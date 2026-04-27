import 'package:flutter/material.dart';

enum AppSnackType {
  success,
  error,
  info,
}

void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
}) {
  Color? backgroundColor;

  switch (type) {
    case AppSnackType.success:
      backgroundColor = Colors.green;
      break;
    case AppSnackType.error:
      backgroundColor = Colors.red;
      break;
    case AppSnackType.info:
      backgroundColor = null;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
    ),
  );
}


String obraFormatDate(DateTime? value) {
  if (value == null) return 'Selecciona una data';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String obraFormatMoneyPreview(String value) {
  final normalized = value.trim().replaceAll('.', '').replaceAll(',', '');
  if (normalized.isEmpty) return '—';
  final parsed = int.tryParse(normalized);
  if (parsed == null) return '—';
  return '$parsed €';
}
