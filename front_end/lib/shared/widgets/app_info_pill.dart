import 'package:flutter/material.dart';

class AppInfoPill extends StatelessWidget {
  final String label;
  final String value;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final double bgOpacity;

  const AppInfoPill({
    super.key,
    required this.label,
    required this.value,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.constraints,
    this.bgOpacity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (constraints != null) {
      return ConstrainedBox(constraints: constraints!, child: content);
    }
    return content;
  }
}
