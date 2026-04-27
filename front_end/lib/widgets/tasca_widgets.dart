import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withOpacity(0.82),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroBadge(
                icon: Icons.tag_outlined,
                label: 'Tasca #${data.tasca.id}',
              ),
              _HeroBadge(
                icon: Icons.flag_outlined,
                label: 'Prioritat ${formatNullableInt(data.tasca.prioritat)}',
              ),
              _HeroBadge(
                icon: data.tasca.visibilitatTasca
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: data.tasca.visibilitatTasca ? 'Visible' : 'Oculta',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.tasca.descripcio.trim().isEmpty
                ? 'Sense descripció de tasca'
                : data.tasca.descripcio.trim(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroInfoTile(
                  label: 'Data inici',
                  value: formatDate(data.tasca.dataInici),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroInfoTile(
                  label: 'Data fi',
                  value: formatDate(data.tasca.dataFi),
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
    return TascaSectionCard(
      title: 'Obra vinculada',
      icon: Icons.business_center_outlined,
      child: obra == null
          ? const TascaSectionPlaceholder(
              message: 'Aquesta tasca no té informació d’obra ampliada.',
            )
          : TascaLinkedTile(
              title: obra!.nom,
              subtitle: 'Obre el perfil de l’obra',
              onTap: onOpenObra == null ? null : () => onOpenObra!(obra!.toObraMap()),
            ),
    );
  }
}

class TascaPareSection extends StatelessWidget {
  final Tasca? tascaPare;
  final ValueChanged<int>? onOpenTascaPare;

  const TascaPareSection({
    super.key,
    required this.tascaPare,
    this.onOpenTascaPare,
  });

  @override
  Widget build(BuildContext context) {
    return TascaSectionCard(
      title: 'Tasca pare',
      icon: Icons.account_tree_outlined,
      child: tascaPare == null
          ? const TascaSectionPlaceholder(
              message: 'Aquesta tasca no depèn de cap tasca pare.',
            )
          : TascaLinkedTile(
              title: 'Tasca #${tascaPare!.id}',
              subtitle: tascaPare!.descripcioCurta,
              metadata: [
                'Prioritat ${formatNullableInt(tascaPare!.prioritat)}',
                'Inici ${formatDate(tascaPare!.dataInici)}',
              ],
              onTap: onOpenTascaPare == null
                  ? null
                  : () => onOpenTascaPare!(tascaPare!.id),
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
    return TascaSectionCard(
      title: 'Treballador assignat',
      icon: Icons.person_outline,
      child: assignacio == null
          ? const TascaSectionPlaceholder(
              message: 'No hi ha cap assignació principal retornada per l’API.',
            )
          : TascaLinkedTile(
              title: assignacio!.usuari.nomComplet,
              subtitle: _buildAssignacioSubtitle(assignacio!),
              metadata: [
                if ((assignacio!.usuari.nickname ?? '').trim().isNotEmpty)
                  '@${assignacio!.usuari.nickname!.trim()}',
                if ((assignacio!.usuari.email ?? '').trim().isNotEmpty)
                  assignacio!.usuari.email!.trim(),
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

class TascaIncidenciesSection extends StatelessWidget {
  final List<TascaIncidenciaItem> incidencies;
  final ValueChanged<int>? onOpenIncidencia;

  const TascaIncidenciesSection({
    super.key,
    required this.incidencies,
    this.onOpenIncidencia,
  });

  @override
  Widget build(BuildContext context) {
    return TascaSectionCard(
      title: 'Incidències relacionades',
      icon: Icons.report_problem_outlined,
      child: incidencies.isEmpty
          ? const TascaSectionPlaceholder(
              message: 'Aquesta tasca no té incidències associades.',
            )
          : Column(
              children: [
                for (var i = 0; i < incidencies.length; i++) ...[
                  TascaLinkedTile(
                    title: 'Incidència #${incidencies[i].id}',
                    subtitle: incidencies[i].descripcioCurta,
                    metadata: [
                      if ((incidencies[i].estat ?? '').trim().isNotEmpty)
                        incidencies[i].estat!.trim(),
                      'Prioritat ${formatNullableInt(incidencies[i].prioritat)}',
                      'Criticitat ${formatNullableInt(incidencies[i].criticitat)}',
                    ],
                    onTap: onOpenIncidencia == null
                        ? null
                        : () => onOpenIncidencia!(incidencies[i].id),
                  ),
                  if (i != incidencies.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class TascaSolucionsSection extends StatelessWidget {
  final List<TascaSolucioItem> solucions;
  final ValueChanged<int>? onOpenSolucio;

  const TascaSolucionsSection({
    super.key,
    required this.solucions,
    this.onOpenSolucio,
  });

  @override
  Widget build(BuildContext context) {
    return TascaSectionCard(
      title: 'Solucions relacionades',
      icon: Icons.build_circle_outlined,
      child: solucions.isEmpty
          ? const TascaSectionPlaceholder(
              message: 'Aquesta tasca no té solucions associades.',
            )
          : Column(
              children: [
                for (var i = 0; i < solucions.length; i++) ...[
                  TascaLinkedTile(
                    title: 'Solució #${solucions[i].id}',
                    subtitle: solucions[i].descripcioCurta,
                    metadata: [
                      'Ef. ${formatNullableInt(solucions[i].eficacia)}',
                      'Impacte ${formatNullableInt(solucions[i].impacte)}',
                      'Cost ${formatMoney(solucions[i].costMonetari)}',
                    ],
                    onTap: onOpenSolucio == null
                        ? null
                        : () => onOpenSolucio!(solucions[i].id),
                  ),
                  if (i != solucions.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class TascaSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const TascaSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
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

  const TascaLinkedTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.metadata = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (metadata.any((item) => item.trim().isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metadata
                        .where((item) => item.trim().isNotEmpty)
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: scheme.surface,
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Text(
                              item,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            onTap == null ? Icons.circle_outlined : Icons.chevron_right_rounded,
            color: onTap == null ? scheme.outline : scheme.primary,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

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

class TascaSectionPlaceholder extends StatelessWidget {
  final String message;

  const TascaSectionPlaceholder({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withOpacity(0.30),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.onPrimaryContainer.withOpacity(0.08),
        border: Border.all(
          color: scheme.onPrimaryContainer.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _HeroInfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surface.withOpacity(0.45),
      ),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime? value) {
  if (value == null) return '—';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
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

class _SelectTreballadorsDialogState
    extends State<SelectTreballadorsDialog> {
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
      return u.nomComplet
          .toLowerCase()
          .contains(_filter.toLowerCase());
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
                          controlAffinity:
                              ListTileControlAffinity.leading,
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