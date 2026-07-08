import 'package:flutter/material.dart';

class AppTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final bool labelUsesAccent;

  const AppTag({
    super.key,
    required this.icon,
    required this.label,
    this.accent,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    this.iconSize = 16.0,
    this.labelUsesAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelUsesAccent ? color : scheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
