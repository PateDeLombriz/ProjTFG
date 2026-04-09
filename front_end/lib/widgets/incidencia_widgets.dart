import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/tasca_models.dart';

class IncidenciaHeaderCard extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaHeaderCard({
    super.key,
    required this.incidencia,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _criticitatColor(incidencia.criticitat);

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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: accent,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incidència #${incidencia.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _textOrFallback(incidencia.descripcio),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _IncidenciaTag(
                      icon: Icons.flag_outlined,
                      label: _estatLabel(incidencia.estat),
                    ),
                    _IncidenciaTag(
                      icon: Icons.priority_high_rounded,
                      label: 'Prioritat ${incidencia.prioritat}',
                    ),
                    _IncidenciaTag(
                      icon: Icons.crisis_alert_outlined,
                      label: 'Criticitat ${incidencia.criticitat}',
                      accent: accent,
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

class IncidenciaCompactInfoPanel extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaCompactInfoPanel({
    super.key,
    required this.incidencia,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
            'Informació general',
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
              _IncidenciaInfoPill(
                label: 'Estat',
                value: _estatLabel(incidencia.estat),
              ),
              _IncidenciaInfoPill(
                label: 'Inici',
                value: _formatDate(incidencia.dataInici),
              ),
              _IncidenciaInfoPill(
                label: 'Fi',
                value: _formatDate(incidencia.dataFi),
              ),
              _IncidenciaInfoPill(
                label: 'Prioritat',
                value: incidencia.prioritat.toString(),
              ),
              _IncidenciaInfoPill(
                label: 'Criticitat',
                value: incidencia.criticitat.toString(),
              ),
              _IncidenciaInfoPill(
                label: 'Categoria',
                value: incidencia.categoria?.toString() ?? '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IncidenciaSectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Widget child;
  final bool initiallyExpanded;

  const IncidenciaSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final subtitle = count == null
        ? null
        : (count == 1 ? '1 element' : '$count elements');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: scheme.primary),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
          children: [child],
        ),
      ),
    );
  }
}

class IncidenciaEmptyState extends StatelessWidget {
  final String text;

  const IncidenciaEmptyState({
    super.key,
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

class IncidenciaObraCard extends StatelessWidget {
  final Obra obra;
  final VoidCallback? onTap;

  const IncidenciaObraCard({
    super.key,
    required this.obra,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _IncidenciaRelationCard(
      title: obra.nom,
      subtitle: obra.hasDescription ? obra.descripcio : null,
      icon: Icons.apartment_rounded,
      chips: [
        _IncidenciaRelationChip(
          icon: Icons.flag_outlined,
          label: _textOrFallback(obra.estat),
        ),
        _IncidenciaRelationChip(
          icon: Icons.location_on_outlined,
          label: obra.locationLabel,
        ),
      ],
      onTap: onTap,
    );
  }
}

class IncidenciaTascaCard extends StatelessWidget {
  final Tasca tasca;
  final VoidCallback? onTap;

  const IncidenciaTascaCard({
    super.key,
    required this.tasca,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _IncidenciaRelationCard(
      title: tasca.etiqueta,
      subtitle: tasca.descripcioCurta,
      icon: Icons.task_alt_outlined,
      chips: [
        _IncidenciaRelationChip(
          icon: Icons.assignment_outlined,
          label: tasca.descripcioCurta,
        ),
        _IncidenciaRelationChip(
          icon: Icons.visibility_outlined,
          label: tasca.visibilitatTasca ? 'Visible' : 'Oculta',
        ),
      ],
      onTap: onTap,
    );
  }
}

class IncidenciaSolucioCard extends StatelessWidget {
  final IncidenciaSolucioItem solucio;
  final VoidCallback? onTap;

  const IncidenciaSolucioCard({
    super.key,
    required this.solucio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solució #${solucio.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _textOrFallback(solucio.descripcio),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IncidenciaInfoPill(
                  label: 'Eficàcia',
                  value: solucio.eficacia?.toString() ?? '—',
                ),
                _IncidenciaInfoPill(
                  label: 'Cost monetari',
                  value: solucio.costMonetari?.toString() ?? '—',
                ),
                _IncidenciaInfoPill(
                  label: 'Cost temporal',
                  value: solucio.costTemporal?.toString() ?? '—',
                ),
                _IncidenciaInfoPill(
                  label: 'Impacte',
                  value: solucio.impacte?.toString() ?? '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IncidenciaSolucionsSectionBody extends StatelessWidget {
  final List<IncidenciaSolucioItem> solucions;
  final void Function(IncidenciaSolucioItem item)? onTapItem;

  const IncidenciaSolucionsSectionBody({
    super.key,
    required this.solucions,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (solucions.isEmpty) {
      return const IncidenciaEmptyState(
        text: 'Aquesta incidència no té solucions registrades.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < solucions.length; i++) ...[
          IncidenciaSolucioCard(
            solucio: solucions[i],
            onTap: onTapItem == null ? null : () => onTapItem!(solucions[i]),
          ),
          if (i != solucions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/* ───────────────────────── PRIVATS ───────────────────────── */

class _IncidenciaRelationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<_IncidenciaRelationChip> chips;
  final VoidCallback? onTap;

  const _IncidenciaRelationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidenciaRelationChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IncidenciaRelationChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidenciaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _IncidenciaTag({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidenciaInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _IncidenciaInfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
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
              fontWeight: FontWeight.w500,
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

Color _criticitatColor(int criticitat) {
  if (criticitat >= 7) return Colors.red;
  if (criticitat >= 4) return Colors.orange;
  return Colors.green;
}

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

String _estatLabel(String? estat) {
  final text = estat?.trim();
  if (text == null || text.isEmpty) return 'Sense estat';
  return text;
}

String _textOrFallback(String? text) {
  final value = text?.trim();
  if (value == null || value.isEmpty) return '—';
  return value;
}