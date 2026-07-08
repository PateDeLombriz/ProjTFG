import 'package:flutter/material.dart';

class AppAvatarFallback extends StatelessWidget {
  final String initials;
  final IconData fallbackIcon;
  final double size;

  const AppAvatarFallback({
    super.key,
    required this.initials,
    this.fallbackIcon = Icons.person,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (initials.isEmpty) {
      return Icon(fallbackIcon, color: scheme.primary, size: size);
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.65,
        ),
      ),
    );
  }
}
