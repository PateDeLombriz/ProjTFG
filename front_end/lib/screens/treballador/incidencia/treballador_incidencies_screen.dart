import 'package:flutter/material.dart';

import 'package:front_end/screens/empresa/incidencia/incidenciaDetail_screen.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorIncidenciesScreen extends StatefulWidget {
  const TreballadorIncidenciesScreen({super.key});

  @override
  State<TreballadorIncidenciesScreen> createState() =>
      _TreballadorIncidenciesScreenState();
}

class _TreballadorIncidenciesScreenState
    extends State<TreballadorIncidenciesScreen> {
  late final IncidenciaService _service;
  late Future<List<Map<String, dynamic>>> _future;

  String _filterEstat = 'totes';
  String _filterCriticitat = 'totes';

  static const _estatOptions = [
    ('totes', 'Totes'),
    ('oberta', 'Obertes'),
    ('en_resolucio', 'En resolució'),
    ('resolta', 'Resoltes'),
  ];

  static const _criticitatOptions = [
    ('totes', 'Totes'),
    ('baixa', 'Baixa'),
    ('mitjana', 'Mitjana'),
    ('alta', 'Alta'),
  ];

  @override
  void initState() {
    super.initState();
    _service = IncidenciaService();
    _future = _service.fetchIncidenciesRawList();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final nextFuture = _service.fetchIncidenciesRawList();

    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final estat = _normalizeEstat(_asString(item['estat']));
      final criticitat = _criticitatLevel(_asInt(item['criticitat']));

      final matchesEstat =
          _filterEstat == 'totes' || estat == _filterEstat;
      final matchesCriticitat =
          _filterCriticitat == 'totes' || criticitat == _filterCriticitat;

      return matchesEstat && matchesCriticitat;
    }).toList()
      ..sort((a, b) {
        final aDate = _asDateTime(a['data_inici']);
        final bDate = _asDateTime(b['data_inici']);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });
  }

  void _openIncidencia(BuildContext context, Map<String, dynamic> item) {
    final id = _asIntOrNull(item['id']);
    if (id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidenciaProfileScreen(
          incidenciaId: id,
          workerView: true,
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
        title: const Text('Les meves incidències'),
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
            return const AppLoadingIndicator(
              message: 'Carregant incidències...',
            );
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilters(all);

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
                _IncidenciesHeaderCard(items: all),
                const SizedBox(height: AppSpacing.md),

                if (all.isNotEmpty) ...[
                  _IncidenciesFilterPanel(
                    selectedEstat: _filterEstat,
                    selectedCriticitat: _filterCriticitat,
                    estatOptions: _estatOptions,
                    criticitatOptions: _criticitatOptions,
                    onEstatChanged: (value) {
                      setState(() {
                        _filterEstat = value;
                      });
                    },
                    onCriticitatChanged: (value) {
                      setState(() {
                        _filterCriticitat = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (all.isEmpty)
                  const AppEmptyState(
                    icon: Icons.report_problem_outlined,
                    title: 'Cap incidència',
                    message:
                        'No tens incidències associades a les teves tasques.',
                  )
                else if (filtered.isEmpty)
                  const AppEmptyState(
                    icon: Icons.filter_list_off_rounded,
                    title: 'Sense resultats',
                    message:
                        'No hi ha incidències que coincideixin amb els filtres seleccionats.',
                  )
                else
                  ...List.generate(filtered.length, (index) {
                    final item = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _IncidenciaCard(
                        item: item,
                        onTap: () => _openIncidencia(context, item),
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
}

class _IncidenciesHeaderCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _IncidenciesHeaderCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _IncidenciesSummary.from(items);

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
            Icons.report_problem_outlined,
            color: scheme.onPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Incidències',
            style: AppTextStyles.headlineMedium.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              height: 1.10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Seguiment dels problemes relacionats amb les teves tasques i obres.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onPrimary.withOpacity(0.80),
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
                  label: 'Obertes',
                  value: summary.obertes.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'Resoltes',
                  value: summary.resoltes.toString(),
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

class _IncidenciesFilterPanel extends StatelessWidget {
  final String selectedEstat;
  final String selectedCriticitat;
  final List<(String, String)> estatOptions;
  final List<(String, String)> criticitatOptions;
  final ValueChanged<String> onEstatChanged;
  final ValueChanged<String> onCriticitatChanged;

  const _IncidenciesFilterPanel({
    required this.selectedEstat,
    required this.selectedCriticitat,
    required this.estatOptions,
    required this.criticitatOptions,
    required this.onEstatChanged,
    required this.onCriticitatChanged,
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
            options: estatOptions,
            onChanged: onEstatChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterGroup(
            title: 'Criticitat',
            selected: selectedCriticitat,
            options: criticitatOptions,
            onChanged: onCriticitatChanged,
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
            children: options.map((option) {
              final key = option.$1;
              final label = option.$2;
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

class _IncidenciaCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _IncidenciaCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final id = _asIntOrNull(item['id']);
    final descripcio = _asString(item['descripcio']) ?? 'Sense descripció';
    final estat = _normalizeEstat(_asString(item['estat']));
    final estatLabel = _estatLabel(estat, fallback: _asString(item['estat']));
    final criticitat = _asInt(item['criticitat']);
    final prioritat = _asInt(item['prioritat']);
    final dataInici = _formatDate(item['data_inici']);
    final dataFi = _formatDate(item['data_fi']);
    final obra = _obraLabel(item);
    final tasca = _tascaLabel(item);
    final isResolved = _isResolved(item);
    final solution = _solutionText(item);
    final accent = _criticitatColor(context, criticitat);

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
                constraints: BoxConstraints(
                  minHeight: isResolved && solution != null ? 198 : 148,
                ),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IncidenciaIcon(accent: accent),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  id == null
                                      ? 'Incidència'
                                      : 'Incidència #$id',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    height: 1.18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  obra,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: scheme.onSurfaceVariant,
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

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        descripcio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _InfoTag(
                            icon: Icons.flag_outlined,
                            label: estatLabel,
                            color: _estatColor(context, estat),
                          ),
                          _InfoTag(
                            icon: Icons.priority_high_rounded,
                            label: criticitat > 0
                                ? 'Criticitat $criticitat'
                                : 'Sense criticitat',
                            color: accent,
                          ),
                          if (prioritat > 0)
                            _InfoTag(
                              icon: Icons.low_priority_rounded,
                              label: 'Prioritat $prioritat',
                              color: scheme.tertiary,
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      _MetaLine(
                        icon: Icons.task_alt_outlined,
                        label: 'Tasca',
                        value: tasca,
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: _DateBox(
                              label: 'Inici',
                              value: dataInici,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _DateBox(
                              label: isResolved ? 'Resolució' : 'Fi',
                              value: dataFi,
                            ),
                          ),
                        ],
                      ),

                      if (isResolved && solution != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _SolutionBox(solution: solution),
                      ],
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

class _IncidenciaIcon extends StatelessWidget {
  final Color accent;

  const _IncidenciaIcon({
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
        Icons.report_problem_outlined,
        color: accent,
        size: 21,
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
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
          Icon(icon, size: 14, color: color),
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

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
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

class _DateBox extends StatelessWidget {
  final String label;
  final String value;

  const _DateBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionBox extends StatelessWidget {
  final String solution;

  const _SolutionBox({
    required this.solution,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: scheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solució aplicada',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  solution,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.32,
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

class _IncidenciesSummary {
  final int total;
  final int obertes;
  final int resoltes;

  const _IncidenciesSummary({
    required this.total,
    required this.obertes,
    required this.resoltes,
  });

  factory _IncidenciesSummary.from(List<Map<String, dynamic>> items) {
    var obertes = 0;
    var resoltes = 0;

    for (final item in items) {
      if (_isResolved(item)) {
        resoltes++;
      } else {
        obertes++;
      }
    }

    return _IncidenciesSummary(
      total: items.length,
      obertes: obertes,
      resoltes: resoltes,
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

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

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
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

String _normalizeEstat(String? value) {
  if (value == null) return 'sense_estat';

  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  switch (normalized) {
    case 'oberta':
    case 'obert':
    case 'pendent':
      return 'oberta';
    case 'en resolucio':
    case 'en resolució':
    case 'en curs':
      return 'en_resolucio';
    case 'tancada':
    case 'tancat':
    case 'resolta':
    case 'resolt':
    case 'finalitzada':
    case 'finalitzat':
      return 'resolta';
    default:
      return normalized.replaceAll(' ', '_');
  }
}

String _estatLabel(String key, {String? fallback}) {
  switch (key) {
    case 'oberta':
      return 'Oberta';
    case 'en_resolucio':
      return 'En resolució';
    case 'resolta':
      return 'Resolta';
    case 'sense_estat':
      return 'Sense estat';
    default:
      return fallback ?? key;
  }
}

Color _estatColor(BuildContext context, String key) {
  final scheme = Theme.of(context).colorScheme;

  switch (key) {
    case 'oberta':
      return scheme.error;
    case 'en_resolucio':
      return scheme.tertiary;
    case 'resolta':
      return Colors.green.shade700;
    default:
      return scheme.onSurfaceVariant;
  }
}

String _criticitatLevel(int criticitat) {
  if (criticitat >= 7) return 'alta';
  if (criticitat >= 4) return 'mitjana';
  if (criticitat > 0) return 'baixa';
  return 'baixa';
}

Color _criticitatColor(BuildContext context, int criticitat) {
  final scheme = Theme.of(context).colorScheme;

  if (criticitat >= 7) return scheme.error;
  if (criticitat >= 4) return scheme.tertiary;
  if (criticitat > 0) return Colors.green.shade700;

  return scheme.onSurfaceVariant;
}

bool _isResolved(Map<String, dynamic> item) {
  final estat = _normalizeEstat(_asString(item['estat']));
  final dataFi = _asString(item['data_fi']);

  return estat == 'resolta' || dataFi != null;
}

String _obraLabel(Map<String, dynamic> item) {
  final direct = _asString(item['obra_nom']) ??
      _asString(item['nom_obra']) ??
      _asString(item['obra']);

  if (direct != null) return direct;

  final rawObra = item['obra'];

  if (rawObra is Map<String, dynamic>) {
    return _asString(rawObra['nom']) ??
        _asString(rawObra['nom_obra']) ??
        'Obra no indicada';
  }

  if (rawObra is Map) {
    final obra = Map<String, dynamic>.from(rawObra);
    return _asString(obra['nom']) ??
        _asString(obra['nom_obra']) ??
        'Obra no indicada';
  }

  return 'Obra no indicada';
}

String _tascaLabel(Map<String, dynamic> item) {
  final direct = _asString(item['tasca_nom']) ??
      _asString(item['tasca_descripcio']);

  if (direct != null) return direct;

  final rawTasca = item['tasca'];

  if (rawTasca is Map<String, dynamic>) {
    return _asString(rawTasca['descripcio']) ??
        _asString(rawTasca['titol']) ??
        'Tasca associada';
  }

  if (rawTasca is Map) {
    final tasca = Map<String, dynamic>.from(rawTasca);
    return _asString(tasca['descripcio']) ??
        _asString(tasca['titol']) ??
        'Tasca associada';
  }

  final tascaId = _asIntOrNull(item['id_tasca']);
  if (tascaId != null) return 'Tasca #$tascaId';

  return 'No indicada';
}

String? _solutionText(Map<String, dynamic> item) {
  final direct = _asString(item['solucio_descripcio']) ??
      _asString(item['resolucio']);

  if (direct != null) return direct;

  final rawSingle = item['solucio'];
  if (rawSingle is String) return _asString(rawSingle);

  if (rawSingle is Map<String, dynamic>) {
    return _asString(rawSingle['descripcio']) ??
        _asString(rawSingle['comentari']);
  }

  if (rawSingle is Map) {
    final parsed = Map<String, dynamic>.from(rawSingle);
    return _asString(parsed['descripcio']) ??
        _asString(parsed['comentari']);
  }

  final rawList = item['solucions'];
  if (rawList is List && rawList.isNotEmpty) {
    for (final entry in rawList) {
      if (entry is Map<String, dynamic>) {
        final text = _asString(entry['descripcio']) ??
            _asString(entry['comentari']);
        if (text != null) return text;
      }

      if (entry is Map) {
        final parsed = Map<String, dynamic>.from(entry);
        final text = _asString(parsed['descripcio']) ??
            _asString(parsed['comentari']);
        if (text != null) return text;
      }
    }
  }

  return null;
}