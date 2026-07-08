import 'package:flutter/material.dart';

class AppCardActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDanger;
  final double borderRadius;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const AppCardActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isDanger = false,
    this.borderRadius = 12,
    this.size = 36,
    this.iconSize = 18,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDanger ? scheme.error : scheme.primary;

    Widget button = Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );

    if (padding != null) {
      return Padding(padding: padding!, child: button);
    }
    return button;
  }
}
