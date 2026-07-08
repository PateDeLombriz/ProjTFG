import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/screens/empresa/incidencia/incidenciaDetail_screen.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/shared/widgets/app_search_field.dart';
import 'package:front_end/widgets/incidencia_widgets.dart';

class IncidenciesListScreen extends StatefulWidget {
  const IncidenciesListScreen({super.key});

  @override
  State<IncidenciesListScreen> createState() => _IncidenciesListScreenState();
}

class _IncidenciesListScreenState extends State<IncidenciesListScreen> {
  late final IncidenciaService _service;
  final TextEditingController _searchController = TextEditingController();

  Future<IncidenciaListData>? _future;

  String _query = '';
  int? _selectedObraId;
  String? _selectedEstat;
  int? _selectedPrioritat;
  String? _selectedCriticitat;
  String _selectedSort = IncidenciaSortValues.mesRecents;

  @override
  void initState() {
    super.initState();
    _service = IncidenciaService();
    _future = _buildFuture();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<IncidenciaListData> _buildFuture() async {
    return _service.fetchIncidenciesListData();
  }

  Future<void> _reload() async {
    FocusScope.of(context).unfocus();

    final nextFuture = _buildFuture();
    setState(() {
      _future = nextFuture;
    });
    await nextFuture;
  }

  bool get _hasActiveFilters {
    return _query.trim().isNotEmpty ||
        _selectedObraId != null ||
        (_selectedEstat?.trim().isNotEmpty == true) ||
        _selectedPrioritat != null ||
        (_selectedCriticitat?.trim().isNotEmpty == true) ||
        _selectedSort != IncidenciaSortValues.mesRecents;
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _selectedObraId = null;
      _selectedEstat = null;
      _selectedPrioritat = null;
      _selectedCriticitat = null;
      _selectedSort = IncidenciaSortValues.mesRecents;
      _searchController.clear();
    });
  }

  List<IncidenciaListItem> _applyFilters(List<IncidenciaListItem> items) {
    final filtered = items.where((item) {
      if (!_matchesQuery(item)) return false;
      if (!_matchesObra(item)) return false;
      if (!_matchesEstat(item)) return false;
      if (!_matchesPrioritat(item)) return false;
      if (!_matchesCriticitat(item)) return false;
      return true;
    }).toList();

    _sortItems(filtered);
    return filtered;
  }

  bool _matchesQuery(IncidenciaListItem item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    final values = <String>[
      item.descripcio,
      item.obraNom ?? '',
      item.estat ?? '',
      item.categoria?.toString() ?? '',
      item.id.toString(),
      item.idObra.toString(),
      item.idTasca?.toString() ?? '',
    ];

    return values.any((value) => value.toLowerCase().contains(query));
  }

  bool _matchesObra(IncidenciaListItem item) {
    if (_selectedObraId == null) return true;
    return item.idObra == _selectedObraId;
  }

  bool _matchesEstat(IncidenciaListItem item) {
    final filter = _selectedEstat?.trim().toLowerCase();
    if (filter == null || filter.isEmpty) return true;

    final current = _normalizeEstat(item.estat);
    return current == filter;
  }

  bool _matchesPrioritat(IncidenciaListItem item) {
    if (_selectedPrioritat == null) return true;
    return item.prioritat == _selectedPrioritat;
  }

  bool _matchesCriticitat(IncidenciaListItem item) {
    final filter = _selectedCriticitat?.trim().toLowerCase();
    if (filter == null || filter.isEmpty) return true;

    final criticitat = item.criticitat;

    switch (filter) {
      case 'alta':
        return criticitat >= 7;
      case 'mitjana':
        return criticitat >= 4 && criticitat < 7;
      case 'baixa':
        return criticitat < 4;
      default:
        return true;
    }
  }

  void _sortItems(List<IncidenciaListItem> items) {
    switch (_selectedSort) {
      case IncidenciaSortValues.mesAntigues:
        items.sort((a, b) => _compareDateAsc(a.dataInici, b.dataInici));
        return;

      case IncidenciaSortValues.criticitatDesc:
        items.sort((a, b) {
          final criticitat = b.criticitat.compareTo(a.criticitat);
          if (criticitat != 0) return criticitat;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case IncidenciaSortValues.prioritatDesc:
        items.sort((a, b) {
          final prioritat = b.prioritat.compareTo(a.prioritat);
          if (prioritat != 0) return prioritat;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case IncidenciaSortValues.obraAsc:
        items.sort((a, b) {
          final obra = (a.obraNom ?? '')
              .toLowerCase()
              .compareTo((b.obraNom ?? '').toLowerCase());
          if (obra != 0) return obra;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case IncidenciaSortValues.estatAsc:
        items.sort((a, b) {
          final estat = _normalizeEstat(a.estat).compareTo(_normalizeEstat(b.estat));
          if (estat != 0) return estat;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case IncidenciaSortValues.mesRecents:
      default:
        items.sort((a, b) => _compareDateDesc(a.dataInici, b.dataInici));
        return;
    }
  }

  int _compareDateDesc(DateTime? a, DateTime? b) {
    final aa = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bb = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bb.compareTo(aa);
  }

  int _compareDateAsc(DateTime? a, DateTime? b) {
    final aa = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bb = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aa.compareTo(bb);
  }

  String _normalizeEstat(String? estat) {
    final value = estat?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return '';

    if (value == 'en curs') return 'en_curs';
    return value;
  }

  int _criticalCount(List<IncidenciaListItem> items) {
    return items.where((item) => item.criticitat >= 7).length;
  }

  int _pendingCount(List<IncidenciaListItem> items) {
    return items.where((item) => _normalizeEstat(item.estat) == 'pendent').length;
  }

  Future<void> _handleCardTap(IncidenciaListItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidenciaProfileScreen(
          incidenciaId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Incidències'),
        actions: [
          IconButton(
            tooltip: 'Recarrega',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Neteja filtres',
            onPressed: _hasActiveFilters ? _clearFilters : null,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      body: FutureBuilder<IncidenciaListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator();
          }

          if (snapshot.hasError) {
            return IncidenciaListErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return IncidenciaListErrorState(
              message: 'No s’han rebut dades d’incidències.',
              onRetry: _reload,
            );
          }

          final filtered = _applyFilters(data.incidencies);
          final allItems = data.incidencies;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                IncidenciaListHeaderCard(
                  title: 'Problemes i incidències',
                  subtitle:
                      'Revisa i localitza ràpidament les incidències vinculades a les obres de l’empresa.',
                  count: allItems.length,
                  activeCount: filtered.length,
                  criticalCount: _criticalCount(allItems),
                  pendingCount: _pendingCount(allItems),
                ),
                const SizedBox(height: 16),
                AppSearchField(
                  controller: _searchController,
                  hintText: 'Cerca incidències...',
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  onClear: () {
                    setState(() {
                      _query = '';
                      _searchController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                IncidenciaFilterBar(
                  obres: data.obresDisponibles,
                  selectedObraId: _selectedObraId,
                  selectedEstat: _selectedEstat,
                  selectedPrioritat: _selectedPrioritat,
                  selectedCriticitat: _selectedCriticitat,
                  selectedSort: _selectedSort,
                  onObraChanged: (value) {
                    setState(() {
                      _selectedObraId = value;
                    });
                  },
                  onEstatChanged: (value) {
                    setState(() {
                      _selectedEstat = value;
                    });
                  },
                  onPrioritatChanged: (value) {
                    setState(() {
                      _selectedPrioritat = value;
                    });
                  },
                  onCriticitatChanged: (value) {
                    setState(() {
                      _selectedCriticitat = value;
                    });
                  },
                  onSortChanged: (value) {
                    setState(() {
                      _selectedSort = value;
                    });
                  },
                  onClearFilters: _hasActiveFilters ? _clearFilters : null,
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  IncidenciaListEmptyState(
                    title: _hasActiveFilters
                        ? 'Cap incidència coincideix amb els filtres'
                        : 'No hi ha incidències disponibles',
                    message: _hasActiveFilters
                        ? 'Prova de canviar la cerca o llevar algun filtre.'
                        : 'Quan l’empresa tengui incidències registrades, apareixeran aquí.',
                    icon: _hasActiveFilters
                        ? Icons.search_off_rounded
                        : Icons.inbox_outlined,
                  )
                else
                  ...List.generate(filtered.length, (index) {
                    final item = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1 ? 0 : 12,
                      ),
                      child: IncidenciaListItemCard(
                        item: item,
                        onTap: () => _handleCardTap(item),
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
