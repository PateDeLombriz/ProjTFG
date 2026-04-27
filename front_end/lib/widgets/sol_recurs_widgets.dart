import 'package:flutter/material.dart';

import 'package:front_end/models/sol_recurs_models.dart';

class SolRecursListHeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final int? pendentsCount;
  final int? entregatsCount;

  const SolRecursListHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    this.pendentsCount,
    this.entregatsCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SolRecursTag(
                      icon: Icons.format_list_bulleted_rounded,
                      label: count == 1 ? '1 sol·licitud' : '$count sol·licituds',
                    ),
                    if (pendentsCount != null)
                      _SolRecursTag(
                        icon: Icons.schedule_rounded,
                        label: pendentsCount == 1
                            ? '1 pendent'
                            : '$pendentsCount pendents',
                      ),
                    if (entregatsCount != null)
                      _SolRecursTag(
                        icon: Icons.check_circle_outline_rounded,
                        label: entregatsCount == 1
                            ? '1 entregat'
                            : '$entregatsCount entregats',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SolRecursSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SolRecursSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cerca per recurs, obra o proveïdor',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outline.withOpacity(0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outline.withOpacity(0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class SolRecursSummaryCard extends StatelessWidget {
  final SolRecurs sollicitud;

  const SolRecursSummaryCard({
    super.key,
    required this.sollicitud,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resum',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SolRecursInfoPill(
                label: 'Estat',
                value: sollicitud.estatLabel,
              ),
              _SolRecursInfoPill(
                label: 'Quantitat',
                value: sollicitud.quantitatLabel,
              ),
              _SolRecursInfoPill(
                label: 'Obra',
                value: sollicitud.obraLabel,
              ),
              _SolRecursInfoPill(
                label: 'Recurs',
                value: sollicitud.recursLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SolRecursDatesCard extends StatelessWidget {
  final SolRecurs sollicitud;
  
  const SolRecursDatesCard({
    super.key,
    required this.sollicitud,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dates',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.event_available_outlined,
            label: 'Necessitat',
            value: sollicitud.dataNecessitat != null
                ? sollicitud.dataNecessitat!.toLocal().toString().split(' ')[0]
                : 'Sense data definida',
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.local_shipping_outlined,
            label: 'Entrega',
            value: sollicitud.dataEntrega != null
                ? sollicitud.dataEntrega!.toLocal().toString().split(' ')[0]
                : 'Sense entrega registrada',
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.history_rounded,
            label: 'Creació',
            value: sollicitud.dataCreacio != null
                ? sollicitud.dataCreacio!.toLocal().toString()
                : 'Sense data de registre',
          ),
        ],
      ),
    );
  }
}

class SolRecursProviderCard extends StatelessWidget {
  final SolRecurs sollicitud;

  const SolRecursProviderCard({
    super.key,
    required this.sollicitud,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proveïdor i comentari',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.storefront_outlined,
            label: 'Proveïdor',
            value: sollicitud.proveidorLabel,
          ),
          const SizedBox(height: 12),
          if (sollicitud.hasComentari)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                sollicitud.comentari!.trim(),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            )
          else
            const _SolRecursEmptyInline(
              text: 'No hi ha comentari afegit.',
            ),
        ],
      ),
    );
  }
}

class SolRecursListItemCard extends StatelessWidget {
  final SolRecurs sollicitud;
  final VoidCallback? onTap;

  const SolRecursListItemCard({
    super.key,
    required this.sollicitud,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = _accentColor(context);
    final backgroundColor = _backgroundColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SolRecursLeadingBadge(
                icon: sollicitud.hasEntrega
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
                color: accentColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sollicitud.recursLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SolRecursStatusChip(
                          label: sollicitud.estatLabel,
                          color: accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sollicitud.obraLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SolRecursTag(
                          icon: Icons.business_center_outlined,
                          label: sollicitud.obraLabel,
                        ),
                        _SolRecursTag(
                          icon: Icons.straighten_rounded,
                          label: sollicitud.quantitatLabel,
                        ),
                        if (sollicitud.hasProveidor)
                          _SolRecursTag(
                            icon: Icons.storefront_outlined,
                            label: sollicitud.proveidorLabel,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SolRecursMetaRow(
                      icon: Icons.event_available_outlined,
                      label: 'Necessitat: ${sollicitud.dataNecessitat != null ? sollicitud.dataNecessitat!.toLocal().toString().split(' ')[0] : 'Sense data'}',
                    ),
                    const SizedBox(height: 6),
                    _SolRecursMetaRow(
                      icon: sollicitud.hasEntrega
                          ? Icons.local_shipping_outlined
                          : Icons.hourglass_bottom_rounded,
                      label: sollicitud.hasEntrega
                          ? 'Entrega: ${sollicitud.dataEntrega!.toLocal().toString().split(' ')[0]}'
                          : 'Creat: ${sollicitud.dataCreacio!.toLocal().toString().split(' ')[0]}',
                    ),
                    if (sollicitud.hasComentari) ...[  
                      const SizedBox(height: 10),
                      Text(
                        (sollicitud.comentari ?? '').length > 60
                            ? '${sollicitud.comentari!.substring(0, 60)}...'
                            : sollicitud.comentari ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentColor(BuildContext context) {
    if (sollicitud.hasEntrega) {
      return Colors.green;
    }

    final necessitat = sollicitud.dataNecessitat;
    if (necessitat != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(necessitat.year, necessitat.month, necessitat.day);

      if (due.isBefore(today)) {
        return Colors.red;
      }

      final difference = due.difference(today).inDays;
      if (difference <= 2) {
        return Colors.orange;
      }
    }

    return Theme.of(context).colorScheme.primary;
  }

  Color _backgroundColor(BuildContext context) {
    final accent = _accentColor(context);
    return accent.withOpacity(0.09);
  }
}

class SolRecursListEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const SolRecursListEmptyState({
    super.key,
    this.title = 'No hi ha sol·licituds',
    this.message = 'Encara no hi ha cap sol·licitud de recurs disponible.',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SolRecursLoadingCard extends StatelessWidget {
  const SolRecursLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 160,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SolRecursListErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SolRecursListErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outline.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: scheme.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'No s’ha pogut carregar el llistat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Torna-ho a provar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolRecursLeadingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SolRecursLeadingBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }
}

class _SolRecursTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SolRecursTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolRecursStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SolRecursStatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SolRecursMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SolRecursMetaRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SolRecursInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _SolRecursInfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolRecursDateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SolRecursDateRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SolRecursEmptyInline extends StatelessWidget {
  final String text;

  const _SolRecursEmptyInline({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: Text(
        text,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}