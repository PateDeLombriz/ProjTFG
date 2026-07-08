import 'package:flutter/material.dart';

class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final double borderRadius;
  final bool showBorder;
  final double bgOpacity;
  final EdgeInsetsGeometry padding;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.borderRadius = 999,
    this.showBorder = false,
    this.bgOpacity = 0.14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: color.withOpacity(0.24)) : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
