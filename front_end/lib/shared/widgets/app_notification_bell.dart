import 'package:flutter/material.dart';

import 'package:front_end/dialogs/notifications_dropdown.dart';
import 'package:front_end/dialogs/notifications_modal.dart';
import 'package:front_end/services/notificacio_service.dart';

class AppNotificationBell extends StatefulWidget {
  final NotificacioService? service;
  final ValueChanged<NotificationItem>? onNotificationTap;

  const AppNotificationBell({super.key, this.service, this.onNotificationTap});

  @override
  State<AppNotificationBell> createState() => _AppNotificationBellState();
}

class _AppNotificationBellState extends State<AppNotificationBell> {
  late final NotificacioService _service;
  int _count = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NotificacioService();
    _refreshCount();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _refreshCount() async {
    try {
      final count = await _service.fetchNotificacionsCount();
      if (!mounted) return;
      setState(() => _count = count);
    } catch (_) {
      if (!mounted) return;
      setState(() => _count = 0);
    }
  }

  Future<void> _openNotifications() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final raw = await _service.fetchMyNotificacions();
      final notifications = raw.map(NotificationItem.fromBackend).toList();

      if (!mounted) return;
      setState(() => _loading = false);

      await showNotificationsDropdown<void>(
        context,
        notifications: notifications,
        onNotificationTap: (notification) async {
          if (!notification.isRead && notification.id > 0) {
            try {
              await _service.marcarLlegida(notification.id);
              notification.isRead = true;
              await _refreshCount();
            } catch (_) {}
          }

          if (mounted) Navigator.pop(context);
          widget.onNotificationTap?.call(notification);
        },
        onMarkAllAsRead: () async {
          final unread = notifications.where((n) => !n.isRead && n.id > 0).toList();
          for (final notification in unread) {
            try {
              await _service.marcarLlegida(notification.id);
              notification.isRead = true;
            } catch (_) {}
          }
          await _refreshCount();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificacions marcades com a llegides')));
          }
        },
      );

      await _refreshCount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No s’han pogut carregar les notificacions: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _count > 9 ? '9+' : _count.toString();

    return IconButton(
      tooltip: 'Notificacions',
      onPressed: _loading ? null : _openNotifications,
      icon: Badge(
        isLabelVisible: _count > 0,
        label: Text(label),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
