import 'package:flutter/material.dart';
import 'notifications_dropdown.dart';

/// Widget que mostra el dropdown de notificacions com un modal.
class NotificationsDropdownModal extends StatefulWidget {
  final List<NotificationItem> notifications;
  final ValueChanged<NotificationItem> onNotificationTap;
  final VoidCallback onMarkAllAsRead;

  const NotificationsDropdownModal({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllAsRead,
  });

  @override
  State<NotificationsDropdownModal> createState() => _NotificationsDropdownModalState();
}

class _NotificationsDropdownModalState extends State<NotificationsDropdownModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: NotificationsDropdown(
        notifications: widget.notifications,
        onNotificationTap: widget.onNotificationTap,
        onMarkAllAsRead: () {
          widget.onMarkAllAsRead();
          setState(() {});
        },
        onClearAll: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Esborrar totes les notificacions'),
              content: const Text('Aquesta acció encara no està connectada al backend.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entesos')),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<T?> showNotificationsDropdown<T>(
  BuildContext context, {
  required List<NotificationItem> notifications,
  required ValueChanged<NotificationItem> onNotificationTap,
  required VoidCallback onMarkAllAsRead,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black26,
    builder: (context) => Center(
      child: NotificationsDropdownModal(
        notifications: notifications,
        onNotificationTap: onNotificationTap,
        onMarkAllAsRead: onMarkAllAsRead,
      ),
    ),
  );
}

/// Versió alternativa: dropdown posicionat relatiu al botó.
class AnchoredNotificationsDropdown extends StatelessWidget {
  final List<NotificationItem> notifications;
  final Offset position;
  final ValueChanged<NotificationItem> onNotificationTap;
  final VoidCallback onMarkAllAsRead;

  const AnchoredNotificationsDropdown({
    super.key,
    required this.notifications,
    required this.position,
    required this.onNotificationTap,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.dy,
      right: position.dx,
      child: Material(
        color: Colors.transparent,
        child: NotificationsDropdown(
          notifications: notifications,
          onNotificationTap: onNotificationTap,
          onMarkAllAsRead: onMarkAllAsRead,
          onClearAll: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
