import 'package:flutter/material.dart';

class AppExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final int? count;
  final String? subtitle;
  final bool initiallyExpanded;
  final Color? accent;
  final bool accentBorder;
  final VoidCallback? onAdd;
  final String? addTooltip;

  const AppExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.subtitle,
    this.initiallyExpanded = true,
    this.accent,
    this.accentBorder = false,
    this.onAdd,
    this.addTooltip,
  });

  @override
  State<AppExpandableSection> createState() => _AppExpandableSectionState();
}

class _AppExpandableSectionState extends State<AppExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.accent ?? scheme.primary;
    final subtitle = widget.count != null
        ? (widget.count == 1 ? '1 element' : '${widget.count} elements')
        : widget.subtitle;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: widget.accentBorder
            ? Border.all(color: accent.withOpacity(0.26), width: 1.4)
            : Border.all(color: scheme.outline.withOpacity(0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: widget.accentBorder
                ? accent.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: widget.accentBorder ? 16 : 14,
            offset: widget.accentBorder
                ? const Offset(0, 8)
                : const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.18)),
            ),
            child: Icon(widget.icon, color: accent),
          ),
          title: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: subtitle == null || subtitle.trim().isEmpty
              ? null
              : Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onAdd != null) ...[
                IconButton(
                  tooltip: widget.addTooltip ?? 'Afegir',
                  onPressed: widget.onAdd,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: accent,
              ),
            ],
          ),
          children: [widget.child],
        ),
      ),
    );
  }
}
