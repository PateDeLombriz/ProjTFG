import 'package:flutter/material.dart';
import 'notifications_dropdown.dart';

/// Widget que muestra el dropdown de notificaciones como un modal
class NotificationsDropdownModal extends StatefulWidget {
  final List<NotificationItem> notifications;
  final VoidCallback onMarkAllAsRead;

  const NotificationsDropdownModal({
    super.key,
    required this.notifications,
    required this.onMarkAllAsRead,
  });

  @override
  State<NotificationsDropdownModal> createState() =>
      _NotificationsDropdownModalState();
}

class _NotificationsDropdownModalState
    extends State<NotificationsDropdownModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: NotificationsDropdown(
        notifications: widget.notifications,
        onNotificationTap: () {
          // Aquí puedes navegar a la pantalla de detalles si es necesario
          Navigator.pop(context);
        },
        onMarkAllAsRead: () {
          widget.onMarkAllAsRead();
          setState(() {});
        },
        onClearAll: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Esborrar totes les notificacions'),
              content: const Text('Estàs segur que vols esborrar-les totes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel·lar'),
                ),
                TextButton(
                  onPressed: () {
                    // Aquí puedes implementar la lógica de borrado
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Esborrar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Función helper para mostrar el dropdown como modal animado
void showNotificationsDropdown(
  BuildContext context, {
  required List<NotificationItem> notifications,
  required VoidCallback onMarkAllAsRead,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black26,
    builder: (context) {
      return Center(
        child: NotificationsDropdownModal(
          notifications: notifications,
          onMarkAllAsRead: onMarkAllAsRead,
        ),
      );
    },
  );
}

/// Versión alternativa: Dropdown posicionado relativo al botón
class AnchoredNotificationsDropdown extends StatelessWidget {
  final List<NotificationItem> notifications;
  final Offset position;
  final VoidCallback onNotificationTap;
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
          onClearAll: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
