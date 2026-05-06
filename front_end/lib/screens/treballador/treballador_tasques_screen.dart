import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/treballador/treballador_tasca_detail_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/models/app_capabilities.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorTasquesScreen extends StatefulWidget {
  final AppCapabilities? capabilities;

  const TreballadorTasquesScreen({
    super.key,
    this.capabilities,
  });

  @override
  State<TreballadorTasquesScreen> createState() =>
      _TreballadorTasquesScreenState();
}

class _TreballadorTasquesScreenState extends State<TreballadorTasquesScreen> {
  late final TreballadorService _service;
  late Future<List<Map<String, dynamic>>> _future;

  String _filterEstat = 'tots';
  String _filterPrioritat = 'totes';

  static const _estats = [
    ('tots', 'Totes'),
    ('pendent', 'Pendents'),
    ('en_curs', 'En curs'),
    ('finalitzada_pendent_revisio', 'Pend. revisió'),
    ('finalitzada', 'Finalitzades'),
  ];

  static const _prioritats = [
    ('totes', 'Totes'),
    ('alta', 'Alta prioritat'),
  ];

  AppCapabilities get _caps =>
      widget.capabilities ?? const AppCapabilities.workerDefaults();

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _future = _service.fetchMyTasques();
  }

  Future<void> _reload() async {
    final nextFuture = _service.fetchMyTasques();

    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> tasques,
  ) {
    return tasques.where((tasca) {
      final estat = _asString(tasca['estat']);
      final prioritat = _asInt(tasca['prioritat']);

      final matchesEstat = _filterEstat == 'tots' || estat == _filterEstat;
      final matchesPrioritat =
          _filterPrioritat == 'totes' || prioritat >= 7;

      return matchesEstat && matchesPrioritat;
    }).toList();
  }

  void _openTasca(BuildContext context, Map<String, dynamic> tasca) {
    final id = _asIntOrNull(tasca['id']);
    if (id == null) return;

    final tascaCaps = TascaProfileCapabilities(
      canEdit: false,
      canDelete: false,
      canAssignWorkers: false,
      canComplete: _caps.canCompleteTask,
      canReportIncidencia: _caps.canReportIncidencia,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TascaTreballadorDetailScreen(
          tascaId: id,
          capabilities: tascaCaps,
        ),
      ),
    ).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Les meves tasques'),
        automaticallyImplyLeading: false,
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant tasques...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              children: [
                _TasquesHeaderCard(tasques: all),
                const SizedBox(height: AppSpacing.md),
                _FiltersPanel(
                  selectedEstat: _filterEstat,
                  selectedPrioritat: _filterPrioritat,
                  estats: _estats,
                  prioritats: _prioritats,
                  onEstatChanged: (value) {
                    setState(() {
                      _filterEstat = value;
                    });
                  },
                  onPrioritatChanged: (value) {
                    setState(() {
                      _filterPrioritat = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  _emptyState(all.isEmpty)
                else
                  ...List.generate(filtered.length, (index) {
                    final tasca = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _WorkerTaskCard(
                        tasca: tasca,
                        onTap: () => _openTasca(context, tasca),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(bool noData) {
    if (noData) {
      return const AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Cap tasca assignada',
        message: 'Encara no tens cap tasca assignada.',
      );
    }

    return const AppEmptyState(
      icon: Icons.filter_list_off_rounded,
      title: 'Sense resultats',
      message: 'No hi ha tasques que coincideixin amb els filtres seleccionats.',
    );
  }
}

class _TasquesHeaderCard extends StatelessWidget {
  final List<Map<String, dynamic>> tasques;

  const _TasquesHeaderCard({
    required this.tasques,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _TaskSummary.from(tasques);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            color: scheme.onPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tasques assignades',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Consulta el teu volum de feina i obre cada tasca per veure’n el detall.',
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Total',
                  value: summary.total.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'En curs',
                  value: summary.enCursLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'Alta prioritat',
                  value: summary.altaPrioritat.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onPrimary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.78),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final String selectedEstat;
  final String selectedPrioritat;
  final List<(String, String)> estats;
  final List<(String, String)> prioritats;
  final ValueChanged<String> onEstatChanged;
  final ValueChanged<String> onPrioritatChanged;

  const _FiltersPanel({
    required this.selectedEstat,
    required this.selectedPrioritat,
    required this.estats,
    required this.prioritats,
    required this.onEstatChanged,
    required this.onPrioritatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterGroup(
            title: 'Estat',
            selected: selectedEstat,
            options: estats,
            onChanged: onEstatChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterGroup(
            title: 'Prioritat',
            selected: selectedPrioritat,
            options: prioritats,
            onChanged: onPrioritatChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final String selected;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _FilterGroup({
    required this.title,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final (key, label) = opt;
              final isSelected = selected == key;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(key),
                  selectedColor: scheme.primaryContainer,
                  backgroundColor: scheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _WorkerTaskCard extends StatelessWidget {
  final Map<String, dynamic> tasca;
  final VoidCallback onTap;

  const _WorkerTaskCard({
    required this.tasca,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final title = _taskTitle(tasca);
    final estat = _asString(tasca['estat']);
    final prioritat = _asInt(tasca['prioritat']);
    final obraName = _obraName(tasca);
    final startDate = _formatDate(_firstValue(tasca, const [
      'data_inici',
      'data_inici_prevista',
    ]));
    final endDate = _formatDate(_firstValue(tasca, const [
      'data_fi',
      'data_prev_fi',
      'data_finalitzacio',
    ]));

    final incidenciesCount = _listCount(tasca['incidencies']);
    final accent = _priorityColor(context, prioritat);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.75),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.045),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                constraints: const BoxConstraints(minHeight: 132),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TaskIcon(accent: accent),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.20,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  obraName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _TaskTag(
                            icon: Icons.flag_outlined,
                            label: _estatLabel(estat),
                            color: _statusColor(context, estat),
                          ),
                          _TaskTag(
                            icon: Icons.priority_high_rounded,
                            label: prioritat > 0
                                ? 'Prioritat $prioritat'
                                : 'Sense prioritat',
                            color: accent,
                          ),
                          if (incidenciesCount > 0)
                            _TaskTag(
                              icon: Icons.report_problem_outlined,
                              label: '$incidenciesCount incid.',
                              color: scheme.error,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _TaskMetaLine(
                              icon: Icons.calendar_today_outlined,
                              label: 'Inici',
                              value: startDate,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _TaskMetaLine(
                              icon: Icons.event_available_outlined,
                              label: 'Fi',
                              value: endDate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  final Color accent;

  const _TaskIcon({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.task_alt_rounded,
        size: 21,
        color: accent,
      ),
    );
  }
}

class _TaskTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TaskTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TaskMetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.32),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _TaskSummary {
  final int total;
  final int enCurs;
  final int altaPrioritat;
  final bool hasEstat;

  const _TaskSummary({
    required this.total,
    required this.enCurs,
    required this.altaPrioritat,
    required this.hasEstat,
  });

  String get enCursLabel => hasEstat ? enCurs.toString() : '—';

  factory _TaskSummary.from(List<Map<String, dynamic>> tasques) {
    var enCurs = 0;
    var altaPrioritat = 0;
    var hasEstat = false;

    for (final tasca in tasques) {
      final estat = _asString(tasca['estat']);
      final prioritat = _asInt(tasca['prioritat']);

      if (estat != null) {
        hasEstat = true;
      }

      if (estat == 'en_curs') {
        enCurs++;
      }

      if (prioritat >= 7) {
        altaPrioritat++;
      }
    }

    return _TaskSummary(
      total: tasques.length,
      enCurs: enCurs,
      altaPrioritat: altaPrioritat,
      hasEstat: hasEstat,
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

String _taskTitle(Map<String, dynamic> tasca) {
  return _asString(tasca['descripcio']) ??
      _asString(tasca['titol']) ??
      _asString(tasca['nom']) ??
      'Tasca sense descripció';
}

String _obraName(Map<String, dynamic> tasca) {
  final obra = tasca['obra'];

  if (obra is Map<String, dynamic>) {
    return _asString(obra['nom']) ??
        _asString(obra['nom_obra']) ??
        'Obra sense nom';
  }

  if (obra is Map) {
    final parsed = Map<String, dynamic>.from(obra);
    return _asString(parsed['nom']) ??
        _asString(parsed['nom_obra']) ??
        'Obra sense nom';
  }

  return 'Obra no indicada';
}

dynamic _firstValue(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value;
    }
  }

  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _listCount(dynamic value) {
  if (value is List) return value.length;
  return 0;
}

String _formatDate(dynamic value) {
  if (value == null) return '—';

  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();

  return '$day/$month/$year';
}

String _estatLabel(String? value) {
  switch (value) {
    case 'pendent':
      return 'Pendent';
    case 'en_curs':
      return 'En curs';
    case 'finalitzada_pendent_revisio':
      return 'Pend. revisió';
    case 'finalitzada':
      return 'Finalitzada';
    case 'cancelada':
      return 'Cancel·lada';
    case null:
      return 'Sense estat';
    default:
      return value;
  }
}

Color _statusColor(BuildContext context, String? value) {
  final scheme = Theme.of(context).colorScheme;

  switch (value) {
    case 'pendent':
      return scheme.error;
    case 'en_curs':
      return scheme.primary;
    case 'finalitzada_pendent_revisio':
      return scheme.tertiary;
    case 'finalitzada':
      return Colors.green.shade700;
    default:
      return scheme.onSurfaceVariant;
  }
}

Color _priorityColor(BuildContext context, int value) {
  final scheme = Theme.of(context).colorScheme;

  if (value >= 7) return scheme.error;
  if (value >= 4) return scheme.tertiary;
  return scheme.primary;
}