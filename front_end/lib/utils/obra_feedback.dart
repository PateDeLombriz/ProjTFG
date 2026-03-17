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