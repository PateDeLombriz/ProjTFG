import 'package:flutter/material.dart';
import 'package:front_end/models/obra_models.dart';

import 'package:front_end/screens/treballador/treballador_obra_info_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/models/app_capabilities.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorObresScreen extends StatefulWidget {
  final AppCapabilities? capabilities;

  const TreballadorObresScreen({
    super.key,
    this.capabilities,
  });

  @override
  State<TreballadorObresScreen> createState() => _TreballadorObresScreenState();
}

class _TreballadorObresScreenState extends State<TreballadorObresScreen> {
  late final TreballadorService _service;
  late Future<List<Map<String, dynamic>>> _future;

  final TextEditingController _searchController = TextEditingController();

  String _filterEstat = 'totes';
  String _query = '';

  static const _estatOptions = [
    ('totes', 'Totes'),
    ('res_firmat', 'Res firmat'),
    ('en_curs', 'En execució'),
    ('finalitzada', 'Finalitzades'),
  ];

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _future = _service.fetchMyObresParticipades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    FocusScope.of(context).unfocus();

    final nextFuture = _service.fetchMyObresParticipades();

    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> obres) {
    final query = _query.trim().toLowerCase();

    return obres.where((obra) {
      final estat = _normalizeEstat(_asString(obra['estat']));
      final matchesEstat = _filterEstat == 'totes' || estat == _filterEstat;

      final nom = _asString(obra['nom'])?.toLowerCase() ?? '';
      final descripcio = _asString(obra['descripcio'])?.toLowerCase() ?? '';
      final ubicacio = _locationLabel(obra).toLowerCase();

      final matchesQuery = query.isEmpty ||
          nom.contains(query) ||
          descripcio.contains(query) ||
          ubicacio.contains(query);

      return matchesEstat && matchesQuery;
    }).toList();
  }

  void _openObra(BuildContext context, Map<String, dynamic> obra) {
    Obra o = Obra.fromMap(obra);
    final id = _asIntOrNull(obra['id']);
    if (id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreballadorObraInfoScreen(
          obra: o,
          capabilities: widget.capabilities,
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
        title: const Text('Les meves obres'),
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
            return const AppLoadingIndicator(message: 'Carregant obres...');
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
                _ObresHeaderCard(obres: all),
                const SizedBox(height: AppSpacing.md),
                _ObresFilterPanel(
                  selectedEstat: _filterEstat,
                  estatOptions: _estatOptions,
                  searchController: _searchController,
                  onEstatChanged: (value) {
                    setState(() {
                      _filterEstat = value;
                    });
                  },
                  onSearchChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  _emptyState(all.isEmpty)
                else
                  ...List.generate(filtered.length, (index) {
                    final obra = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _WorkerObraCard(
                        obra: obra,
                        onTap: () => _openObra(context, obra),
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
        icon: Icons.location_city_outlined,
        title: 'Cap obra assignada',
        message: 'Encara no participes en cap obra.',
      );
    }

    return const AppEmptyState(
      icon: Icons.filter_list_off_rounded,
      title: 'Sense resultats',
      message: 'No hi ha obres que coincideixin amb els filtres seleccionats.',
    );
  }
}

class _ObresHeaderCard extends StatelessWidget {
  final List<Map<String, dynamic>> obres;

  const _ObresHeaderCard({
    required this.obres,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _ObresSummary.from(obres);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
            Icons.location_city_rounded,
            color: scheme.onPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Obres participades',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Consulta les obres on tens participació. El detall complet queda dins la fitxa de cada obra.',
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                  label: 'En execució',
                  value: summary.enCurs.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'Finalitzades',
                  value: summary.finalitzades.toString(),
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

class _ObresFilterPanel extends StatelessWidget {
  final String selectedEstat;
  final List<(String, String)> estatOptions;
  final TextEditingController searchController;
  final ValueChanged<String> onEstatChanged;
  final ValueChanged<String> onSearchChanged;

  const _ObresFilterPanel({
    required this.selectedEstat,
    required this.estatOptions,
    required this.searchController,
    required this.onEstatChanged,
    required this.onSearchChanged,
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
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cerca per nom o ubicació',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surfaceVariant.withOpacity(0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Estat',
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
              children: estatOptions.map((option) {
                final key = option.$1;
                final label = option.$2;
                final isSelected = selectedEstat == key;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => onEstatChanged(key),
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
      ),
    );
  }
}

class _WorkerObraCard extends StatelessWidget {
  final Map<String, dynamic> obra;
  final VoidCallback onTap;

  const _WorkerObraCard({
    required this.obra,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final nom = _asString(obra['nom']) ?? 'Obra sense nom';
    final estat = _asString(obra['estat']);
    final normalizedEstat = _normalizeEstat(estat);
    final estatLabel = _estatLabel(normalizedEstat, fallback: estat);
    final startDate = _formatDate(obra['data_inici']);
    final endDate = _formatDate(
      obra['data_prev_fi'] ?? obra['data_fi'],
    );
    final location = _locationLabel(obra);
    final description = _asString(obra['descripcio']);

    final accent = _estatColor(context, normalizedEstat);

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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ObraIcon(accent: accent),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nom,
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
                                  location,
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
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.30,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _ObraTag(
                            icon: Icons.flag_outlined,
                            label: estatLabel,
                            color: accent,
                          ),
                          _ObraTag(
                            icon: Icons.calendar_today_outlined,
                            label: 'Inici $startDate',
                            color: scheme.primary,
                          ),
                          if (endDate != '—')
                            _ObraTag(
                              icon: Icons.event_available_outlined,
                              label: 'Fi $endDate',
                              color: scheme.tertiary,
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

class _ObraIcon extends StatelessWidget {
  final Color accent;

  const _ObraIcon({
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
        Icons.apartment_rounded,
        color: accent,
        size: 22,
      ),
    );
  }
}

class _ObraTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ObraTag({
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

class _ObresSummary {
  final int total;
  final int enCurs;
  final int finalitzades;

  const _ObresSummary({
    required this.total,
    required this.enCurs,
    required this.finalitzades,
  });

  factory _ObresSummary.from(List<Map<String, dynamic>> obres) {
    var enCurs = 0;
    var finalitzades = 0;

    for (final obra in obres) {
      final estat = _normalizeEstat(_asString(obra['estat']));

      if (estat == 'en_curs') {
        enCurs++;
      } else if (estat == 'finalitzada') {
        finalitzades++;
      }
    }

    return _ObresSummary(
      total: obres.length,
      enCurs: enCurs,
      finalitzades: finalitzades,
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String _normalizeEstat(String? value) {
  if (value == null) return 'sense_estat';

  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  switch (normalized) {
    case 'res firmat':
      return 'res_firmat';
    case 'en curs':
    case 'en execucio':
    case 'en execució':
      return 'en_curs';
    case 'finalitzada':
    case 'finalitzat':
      return 'finalitzada';
    case 'pendent':
      return 'pendent';
    default:
      return normalized.replaceAll(' ', '_');
  }
}

String _estatLabel(String normalized, {String? fallback}) {
  switch (normalized) {
    case 'res_firmat':
      return 'Res firmat';
    case 'en_curs':
      return 'En execució';
    case 'finalitzada':
      return 'Finalitzada';
    case 'pendent':
      return 'Pendent';
    case 'sense_estat':
      return 'Sense estat';
    default:
      return fallback ?? normalized;
  }
}

Color _estatColor(BuildContext context, String normalized) {
  final scheme = Theme.of(context).colorScheme;

  switch (normalized) {
    case 'res_firmat':
      return scheme.onSurfaceVariant;
    case 'en_curs':
      return scheme.primary;
    case 'finalitzada':
      return Colors.green.shade700;
    case 'pendent':
      return scheme.tertiary;
    default:
      return scheme.primary;
  }
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

String _locationLabel(Map<String, dynamic> obra) {
  final direct = _asString(obra['ubicacio_label']) ??
      _asString(obra['ubicacio']) ??
      _asString(obra['adreca']);

  if (direct != null) return direct;

  final infoRaw = obra['ubicacio_info'];

  if (infoRaw is Map<String, dynamic>) {
    return _locationFromMap(infoRaw);
  }

  if (infoRaw is Map) {
    return _locationFromMap(Map<String, dynamic>.from(infoRaw));
  }

  return 'Ubicació no indicada';
}

String _locationFromMap(Map<String, dynamic> info) {
  final parts = <String>[
    if (_asString(info['adreca']) != null) _asString(info['adreca'])!,
    if (_asString(info['ciutat']) != null) _asString(info['ciutat'])!,
    if (_asString(info['provincia']) != null) _asString(info['provincia'])!,
  ];

  if (parts.isEmpty) return 'Ubicació no indicada';

  return parts.join(', ');
}