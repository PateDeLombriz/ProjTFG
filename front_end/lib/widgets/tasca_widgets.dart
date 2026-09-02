import 'package:flutter/material.dart';
import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/shared/widgets/app_card_action_button.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/utils/date_formatter.dart';
import 'package:front_end/shared/widgets/app_badge.dart';
import 'package:front_end/shared/widgets/app_expandable_section.dart';
import 'package:front_end/shared/widgets/app_form_header_card.dart';

class TascaHeroCard extends StatelessWidget {
  final TascaProfileData data;

  const TascaHeroCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _priorityAccent(scheme, data.tasca.prioritat);
    final visibilityAccent =
        data.tasca.visibilitatTasca ? Colors.green : scheme.outline;
    final description = data.tasca.descripcio.trim().isEmpty
        ? 'Sense descripció de tasca'
        : data.tasca.descripcio.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.18),
            scheme.primaryContainer.withOpacity(0.28),
            scheme.surface,
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.24), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.20)),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil de tasca',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                icon: Icons.tag_outlined,
                label: 'Tasca #${data.tasca.id}',
                color: scheme.primary,
              ),
              AppBadge(
                icon: Icons.flag_outlined,
                label: 'Prioritat ${formatNullableInt(data.tasca.prioritat)}',
                color: accent,
              ),
              AppBadge(
                icon: data.tasca.visibilitatTasca
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: data.tasca.visibilitatTasca ? 'Visible' : 'Oculta',
                color: visibilityAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroInfoTile(
                  icon: Icons.play_arrow_rounded,
                  label: 'Data inici',
                  value: formatDate(data.tasca.dataInici),
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroInfoTile(
                  icon: Icons.flag_circle_rounded,
                  label: 'Data fi',
                  value: formatDate(data.tasca.dataFi),
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TascaObraSection extends StatelessWidget {
  final TascaObraInfo? obra;
  final ValueChanged<Map<String, dynamic>>? onOpenObra;

  const TascaObraSection({
    super.key,
    required this.obra,
    this.onOpenObra,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;

    return AppExpandableSection(accentBorder: true,
      title: 'Obra vinculada',
      icon: Icons.business_center_outlined,
      count: obra == null ? 0 : 1,
      accent: accent,
      child: obra == null
          ? TascaSectionPlaceholder(
              message: 'Aquesta tasca no té informació d’obra ampliada.',
              accent: accent,
            )
          : TascaLinkedTile(
              title: obra!.nom,
              subtitle: (obra!.descripcio ?? '').trim().isNotEmpty
                  ? obra!.descripcio!.trim()
                  : 'Obre el perfil de l’obra',
              icon: Icons.apartment_rounded,
              accent: accent,
              metadata: [
                if ((obra!.estat ?? '').trim().isNotEmpty)
                  'Estat: ${obra!.estat!.trim()}',
                'Inici: ${formatDate(obra!.dataInici)}',
                'Fi prev.: ${formatDate(obra!.dataPrevFi)}',
              ],
              onTap: onOpenObra == null
                  ? null
                  : () => onOpenObra!(obra!.toObraMap()),
            ),
    );
  }
}

class TascaPareSection extends StatelessWidget {
  final Tasca? tascaPare;
  final ValueChanged<int>? onOpenTascaPare;
  final VoidCallback? onSelectTascaPare;
  final VoidCallback? onUnlinkTascaPare;

  const TascaPareSection({
    super.key,
    required this.tascaPare,
    this.onOpenTascaPare,
    this.onSelectTascaPare,
    this.onUnlinkTascaPare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;

    return AppExpandableSection(
      accentBorder: true,
      title: 'Tasca pare',
      icon: Icons.account_tree_outlined,
      count: tascaPare == null ? 0 : 1,
      accent: accent,
      onAdd: onSelectTascaPare,
      addTooltip: tascaPare == null ? 'Seleccionar tasca pare' : 'Canviar tasca pare',
      child: tascaPare == null
          ? TascaSectionPlaceholder(
              message: 'Aquesta tasca no depèn de cap tasca pare.',
              accent: accent,
            )
          : TascaLinkedTile(
              title: tascaPare!.descripcioCurta,
              subtitle: 'Tasca pare vinculada',
              icon: Icons.account_tree_rounded,
              accent: accent,
              metadata: [
                'Prioritat: ${formatNullableInt(tascaPare!.prioritat)}',
                'Inici: ${formatDate(tascaPare!.dataInici)}',
                'Fi: ${formatDate(tascaPare!.dataFi)}',
              ],
              onTap: onOpenTascaPare == null ? null : () => onOpenTascaPare!(tascaPare!.id),
              onEdit: onSelectTascaPare,
              editTooltip: 'Canviar tasca pare',
              onUnlink: onUnlinkTascaPare,
              unlinkTooltip: 'Desvincular tasca pare',
            ),
    );
  }
}
class TascaTreballadorsSection extends StatelessWidget {
  final List<TreballadorListItem> treballadors;
  final VoidCallback? onAddTreballadors;
  final ValueChanged<int>? onOpenTreballador;
  final ValueChanged<TreballadorListItem>? onRemoveTreballador;

  const TascaTreballadorsSection({
    super.key,
    required this.treballadors,
    this.onAddTreballadors,
    this.onOpenTreballador,
    this.onRemoveTreballador,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.tertiary;

    return AppExpandableSection(
      accentBorder: true,
      title: 'Treballadors assignats',
      icon: Icons.groups_outlined,
      count: treballadors.length,
      accent: accent,
      onAdd: onAddTreballadors,
      addTooltip: 'Afegir treballadors',
      child: treballadors.isEmpty
          ? TascaSectionPlaceholder(
              message: 'Aquesta tasca encara no té treballadors assignats.',
              accent: accent,
            )
          : Column(
              children: [
                for (var i = 0; i < treballadors.length; i++) ...[
                  TascaLinkedTile(
                    title: treballadors[i].nomComplet,
                    subtitle: treballadors[i].carrec?.trim().isNotEmpty == true
                        ? treballadors[i].carrec!.trim()
                        : '',
                    icon: Icons.person_rounded,
                    accent: accent,
                    metadata: [
                      'Malnom: #${treballadors[i].nickname ?? '—'}',
                    ],
                    onTap: onOpenTreballador == null
                        ? null
                        : () => onOpenTreballador!(treballadors[i].id),
                    onDelete: onRemoveTreballador == null
                        ? null
                        : () => onRemoveTreballador!(treballadors[i]),
                    deleteTooltip: 'Desassignar treballador',
                  ),
                  if (i != treballadors.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
class TascaIncidenciesSection extends StatelessWidget {
  final List<TascaIncidenciaItem> incidencies;
  final ValueChanged<int>? onOpenIncidencia;
  final VoidCallback? onCreateIncidencia;
  final ValueChanged<TascaIncidenciaItem>? onEditIncidencia;
  final ValueChanged<TascaIncidenciaItem>? onDeleteIncidencia;

  const TascaIncidenciesSection({
    super.key,
    required this.incidencies,
    this.onOpenIncidencia,
    this.onCreateIncidencia,
    this.onEditIncidencia,
    this.onDeleteIncidencia,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sectionAccent = _incidenciesAccent(scheme, incidencies);

    return AppExpandableSection(
      accentBorder: true,
      title: 'Incidències causades per aquesta tasca',
      icon: Icons.report_problem_outlined,
      count: incidencies.length,
      accent: sectionAccent,
      onAdd: onCreateIncidencia,
      addTooltip: 'Crear incidència',
      child: incidencies.isEmpty
          ? TascaSectionPlaceholder(
              message: 'Aquesta tasca no té incidències associades.',
              accent: sectionAccent,
            )
          : Column(
              children: [
                for (var i = 0; i < incidencies.length; i++) ...[
                  TascaLinkedTile(
                    title: incidencies[i].descripcioCurta,
                    subtitle: 'Incidència associada a aquesta tasca',
                    icon: Icons.warning_amber_rounded,
                    accent: _criticitatAccent(scheme, incidencies[i].criticitat),
                    metadata: [
                      if ((incidencies[i].estat ?? '').trim().isNotEmpty)
                        'Estat: ${incidencies[i].estat!.trim()}',
                      'Prioritat: ${formatNullableInt(incidencies[i].prioritat)}',
                      'Criticitat: ${formatNullableInt(incidencies[i].criticitat)}',
                      'Inici: ${formatDate(incidencies[i].dataInici)}',
                    ],
                    onTap: onOpenIncidencia == null
                        ? null
                        : () => onOpenIncidencia!(incidencies[i].id),
                    onEdit: onEditIncidencia == null
                        ? null
                        : () => onEditIncidencia!(incidencies[i]),
                    editTooltip: 'Editar incidència',
                    onDelete: onDeleteIncidencia == null
                        ? null
                        : () => onDeleteIncidencia!(incidencies[i]),
                    deleteTooltip: 'Eliminar incidència',
                  ),
                  if (i != incidencies.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
class TascaLinkedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> metadata;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accent;

  final VoidCallback? onEdit;
  final VoidCallback? onUnlink;
  final VoidCallback? onDelete;
  final String editTooltip;
  final String unlinkTooltip;
  final String deleteTooltip;

  const TascaLinkedTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.metadata = const [],
    this.onTap,
    this.icon,
    this.accent,
    this.onEdit,
    this.onUnlink,
    this.onDelete,
    this.editTooltip = 'Editar',
    this.unlinkTooltip = 'Desvincular',
    this.deleteTooltip = 'Eliminar',
  });

  bool get _hasActions => onEdit != null || onUnlink != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveAccent = accent ?? scheme.primary;
    final visibleMetadata = metadata.where((item) => item.trim().isNotEmpty).toList();

    final content = Ink(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: effectiveAccent.withOpacity(0.055),
        border: Border.all(color: effectiveAccent.withOpacity(0.18)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  color: effectiveAccent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon ?? Icons.link_rounded,
                    color: effectiveAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.trim().isEmpty ? 'Sense títol' : title.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.32,
                          ),
                        ),
                      ],
                      if (visibleMetadata.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: visibleMetadata
                              .map(
                                (item) => _TascaInfoPill(
                                  label: item,
                                  accent: effectiveAccent,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasActions)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        AppCardActionButton(
                          tooltip: editTooltip,
                          icon: Icons.edit_outlined,
                          onPressed: onEdit!,
                        ),
                      if (onUnlink != null) ...[
                        const SizedBox(height: 6),
                        AppCardActionButton(
                          tooltip: unlinkTooltip,
                          icon: Icons.link_off_rounded,
                          onPressed: onUnlink!,
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(height: 6),
                        AppCardActionButton(
                          tooltip: deleteTooltip,
                          icon: Icons.delete_outline,
                          isDanger: true,
                          onPressed: onDelete!,
                        ),
                      ],
                    ],
                  )
                else
                  Icon(
                    onTap == null ? Icons.circle_outlined : Icons.chevron_right_rounded,
                    color: onTap == null ? scheme.outline : effectiveAccent,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class TascaAssignacioSection extends StatelessWidget {
  final TascaAssignacio? assignacio;
  final ValueChanged<int>? onOpenTreballador;

  const TascaAssignacioSection({
    super.key,
    required this.assignacio,
    this.onOpenTreballador,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.tertiary;

    return AppExpandableSection(accentBorder: true,
      title: 'Treballador assignat',
      icon: Icons.person_outline,
      count: assignacio == null ? 0 : 1,
      accent: accent,
      child: assignacio == null
          ? TascaSectionPlaceholder(
              message: 'No hi ha cap assignació principal retornada per l’API.',
              accent: accent,
            )
          : TascaLinkedTile(
              title: assignacio!.usuari.nomComplet,
              subtitle: _buildAssignacioSubtitle(assignacio!),
              icon: Icons.person_rounded,
              accent: accent,
              metadata: [
                if ((assignacio!.usuari.nickname ?? '').trim().isNotEmpty)
                  '@${assignacio!.usuari.nickname!.trim()}',
                if ((assignacio!.usuari.email ?? '').trim().isNotEmpty)
                  assignacio!.usuari.email!.trim(),
                if ((assignacio!.usuari.telefon ?? '').trim().isNotEmpty)
                  'Tel.: ${assignacio!.usuari.telefon!.trim()}',
              ],
              onTap: assignacio!.usuari.id == null || onOpenTreballador == null
                  ? null
                  : () => onOpenTreballador!(assignacio!.usuari.id!),
            ),
    );
  }

  String _buildAssignacioSubtitle(TascaAssignacio assignacio) {
    final comentari = (assignacio.comentari ?? '').trim();
    if (comentari.isNotEmpty) {
      return comentari.length <= 120
          ? comentari
          : '${comentari.substring(0, 117)}...';
    }

    final telefon = (assignacio.usuari.telefon ?? '').trim();
    if (telefon.isNotEmpty) {
      return 'Tel. $telefon';
    }

    return 'Obre el perfil del treballador';
  }
}

class TascaSectionPlaceholder extends StatelessWidget {
  final String message;
  final Color? accent;

  const TascaSectionPlaceholder({
    super.key,
    required this.message,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveAccent = accent ?? scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: effectiveAccent.withOpacity(0.055),
        border: Border.all(color: effectiveAccent.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: effectiveAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TascaErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const TascaErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 54),
            const SizedBox(height: 12),
            Text(
              'No s’ha pogut carregar la tasca',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Torna-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}

class TascaEmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const TascaEmptyState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              'No hi ha dades de la tasca',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresca'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surface.withOpacity(0.68),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
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

class _TascaInfoPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _TascaInfoPill({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withOpacity(0.10),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _priorityAccent(ColorScheme scheme, int? priority) {
  if (priority == null) return scheme.primary;
  if (priority <= 2) return Colors.green;
  if (priority <= 4) return Colors.orange;
  return Colors.redAccent;
}

Color _criticitatAccent(ColorScheme scheme, int? criticitat) {
  if (criticitat == null) return scheme.primary;
  if (criticitat >= 7) return Colors.redAccent;
  if (criticitat >= 4) return Colors.orange;
  return Colors.green;
}

Color _incidenciesAccent(
    ColorScheme scheme, List<TascaIncidenciaItem> incidencies) {
  if (incidencies.isEmpty) return scheme.error;
  final maxCriticitat = incidencies
      .map((item) => item.criticitat ?? 0)
      .fold<int>(0, (max, value) => value > max ? value : max);
  return _criticitatAccent(scheme, maxCriticitat);
}

String formatNullableInt(int? value) {
  return value?.toString() ?? '—';
}

String formatMoney(int? value) {
  if (value == null) return '—';
  return '$value €';
}

class SelectTreballadorsDialog extends StatefulWidget {
  final List<UsuariOption> tots;
  final List<UsuariOption> seleccionats;

  const SelectTreballadorsDialog({
    super.key,
    required this.tots,
    required this.seleccionats,
  });

  @override
  State<SelectTreballadorsDialog> createState() =>
      _SelectTreballadorsDialogState();
}

class _SelectTreballadorsDialogState extends State<SelectTreballadorsDialog> {
  late List<UsuariOption> _temp;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _temp = List.of(widget.seleccionats);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final filtrats = widget.tots.where((u) {
      return u.nomComplet.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Selecciona treballadors'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Cerca treballador...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtrats.isEmpty
                  ? const Center(
                      child: Text(
                        'No s’han trobat treballadors',
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtrats.length,
                      itemBuilder: (context, index) {
                        final usuari = filtrats[index];

                        final selected = _temp.any(
                          (s) => s.id == usuari.id,
                        );

                        return CheckboxListTile(
                          value: selected,
                          title: Text(usuari.nomComplet),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!_temp.any(
                                  (e) => e.id == usuari.id,
                                )) {
                                  _temp.add(usuari);
                                }
                              } else {
                                _temp.removeWhere(
                                  (e) => e.id == usuari.id,
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel·la'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _temp);
          },
          child: const Text('Aplica'),
        ),
      ],
    );
  }
}

class TascaStatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> tasques;

  const TascaStatsHeader({
    super.key,
    required this.tasques,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final totals = tasques.length;
    final visibles = tasques.where((t) {
      return t['visibilitat_tasca'] == true;
    }).length;

    final prioritatAlta = tasques.where((t) {
      final prioritat = int.tryParse('${t['prioritat'] ?? ''}') ?? 99;
      return prioritat <= 2;
    }).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TascaStatCard(
            label: 'Totals',
            value: totals,
            icon: Icons.list_alt,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          _TascaStatCard(
            label: 'Visibles',
            value: visibles,
            icon: Icons.visibility,
            color: Colors.teal,
          ),
          const SizedBox(width: 8),
          _TascaStatCard(
            label: 'Alta Prio.',
            value: prioritatAlta,
            icon: Icons.priority_high,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _TascaStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _TascaStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 100,
        height: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.onPrimary),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: scheme.onPrimary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TascaCard extends StatelessWidget {
  final Map<String, dynamic> tasca;
  final ValueChanged<int>? onOpen;
  final ValueChanged<Map<String, dynamic>>? onEdit;
  final ValueChanged<int>? onDelete;

  const TascaCard({
    super.key,
    required this.tasca,
    this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final id = int.tryParse('${tasca['id'] ?? ''}') ?? 0;
    final descripcio = (tasca['descripcio'] ?? '—').toString();
    final dataInici = _formatRawDate(tasca['data_inici']);
    final dataFi = _formatRawDate(tasca['data_fi']);
    final prioritat = int.tryParse('${tasca['prioritat'] ?? ''}');
    final visible = tasca['visibilitat_tasca'] == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visible ? Colors.green : Colors.grey,
          child: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          descripcio,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Inici: $dataInici · Fi: $dataFi\nPrioritat: ${prioritat ?? '—'}',
        ),
        isThreeLine: true,
        onTap: id <= 0 || onOpen == null ? null : () => onOpen!(id),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit?.call(tasca);
            }

            if (value == 'delete' && id > 0) {
              onDelete?.call(id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text('Edita'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Elimina'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRawDate(dynamic value) {
  if (value == null) return 'N/D';

  if (value is DateTime) {
    return formatDate(value);
  }

  final parsed = DateTime.tryParse(value.toString());
  if (parsed != null) {
    return formatDate(parsed);
  }

  final text = value.toString().trim();
  return text.isEmpty ? 'N/D' : text;
}

class TascaWorkerCard extends StatelessWidget {
  final Map<String, dynamic> tasca;
  final VoidCallback? onTap;

  const TascaWorkerCard({
    super.key,
    required this.tasca,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final descripcio = (tasca['descripcio'] ?? '—').toString().trim();
    final estat = (tasca['estat'] ?? '').toString();
    final dataInici = _formatRawDate(tasca['data_inici']);
    final dataFi = _formatRawDate(tasca['data_fi']);
    final config = _estatWorkerConfig(estat, scheme);

    final obraMap = tasca['obra'];
    final String? nomObra = obraMap is Map
        ? (obraMap['nom'] ?? '').toString().trim().isEmpty
            ? null
            : obraMap['nom'].toString().trim()
        : null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: config.borderColor, width: 1),
      ),
      color: scheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: config.badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      config.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: config.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.outline,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                descripcio.isEmpty ? 'Sense descripció' : descripcio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$dataInici → $dataFi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (nomObra != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        nomObra,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

//Classe per contrlar el color de les tasques del treballador segons el seu estat. Es pot ampliar fàcilment per nous estats o canviar colors.
class _EstatConfig {
  final String label;
  final Color badgeColor;
  final Color textColor;
  final Color borderColor;

  const _EstatConfig({
    required this.label,
    required this.badgeColor,
    required this.textColor,
    required this.borderColor,
  });
}

_EstatConfig _estatWorkerConfig(String estat, ColorScheme scheme) {
  switch (estat) {
    case 'en_curs':
      return _EstatConfig(
        label: 'En curs',
        badgeColor: const Color(0xFFE7F0FA),
        textColor: const Color(0xFF2B6CB0),
        borderColor: const Color(0xFF2B6CB0).withOpacity(0.25),
      );
    case 'finalitzada_pendent_revisio':
      return _EstatConfig(
        label: 'Pendent revisió',
        badgeColor: const Color(0xFFEEF2F5),
        textColor: const Color(0xFF5E7486),
        borderColor: const Color(0xFF5E7486).withOpacity(0.25),
      );
    case 'finalitzada':
      return _EstatConfig(
        label: 'Finalitzada',
        badgeColor: const Color(0xFFE6F4EC),
        textColor: const Color(0xFF2F855A),
        borderColor: const Color(0xFF2F855A).withOpacity(0.25),
      );
    case 'pendent':
    default:
      return _EstatConfig(
        label: estat == 'pendent'
            ? 'Pendent'
            : (estat.isEmpty ? 'Desconegut' : estat),
        badgeColor: const Color(0xFFFBF1DE),
        textColor: const Color(0xFFB7791F),
        borderColor: const Color(0xFFB7791F).withOpacity(0.25),
      );
  }
}

class TascaFormHeaderCard extends StatelessWidget {
  final bool editing;
  final String description;
  final String obraLabel;
  final int prioritat;
  final bool visible;

  const TascaFormHeaderCard({
    super.key,
    required this.editing,
    required this.description,
    required this.obraLabel,
    required this.prioritat,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _priorityAccent(scheme, prioritat);
    final cleanDescription = description.trim();
    return AppFormHeaderCard(
      title: editing ? 'Editar tasca' : 'Nova tasca',
      subtitle: cleanDescription.isEmpty
          ? 'Defineix les dades principals, la planificació i els treballadors assignats.'
          : cleanDescription,
      icon: editing ? Icons.edit_note_rounded : Icons.add_task_rounded,
      accent: accent,
      accentBorder: true,
      iconContainerSize: 54,
      badges: [
        AppBadge(icon: Icons.apartment_rounded, label: obraLabel, color: scheme.primary),
        AppBadge(icon: Icons.flag_outlined, label: 'Prioritat $prioritat', color: accent),
        AppBadge(
          icon: visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          label: visible ? 'Visible' : 'Oculta',
          color: visible ? Colors.green : scheme.outline,
        ),
      ],
    );
  }
}

class TascaFormDateTile extends StatelessWidget {
  final String title;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isRequired;

  const TascaFormDateTile({
    super.key,
    required this.title,
    required this.date,
    required this.onTap,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = isRequired ? scheme.primary : scheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.calendar_today_outlined, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date == null ? 'Selecciona una data' : formatDate(date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_calendar_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class TascaFormReadOnlyTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const TascaFormReadOnlyTile({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
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

class TascaFormMetricSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final IconData icon;

  const TascaFormMetricSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 5,
    this.icon = Icons.flag_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _priorityAccent(scheme, value);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppBadge(
                icon: Icons.tag_rounded,
                label: '$value',
                color: accent,
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged: (next) => onChanged(next.toInt()),
          ),
        ],
      ),
    );
  }
}

class TascaAssignedWorkerCard extends StatelessWidget {
  final UsuariOption usuari;
  final VoidCallback? onRemove;

  const TascaAssignedWorkerCard({
    super.key,
    required this.usuari,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 17, color: accent),
          const SizedBox(width: 6),
          Text(
            usuari.nomComplet,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 17, color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class TascaFormEmptyState extends StatelessWidget {
  final String text;
  final IconData icon;

  const TascaFormEmptyState({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

