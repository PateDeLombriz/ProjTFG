import 'package:flutter/material.dart';

Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Cancel·la',
  String confirmText = 'Confirma',
  IconData? icon,
  bool isDanger = false,
}) {
  final scheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDanger ? Colors.red : scheme.primary,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDanger
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}