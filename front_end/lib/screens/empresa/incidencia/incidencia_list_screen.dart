import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
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
  String _selectedSort = _IncidenciaListSort.mesRecents;

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

  void _clearFilters() {
    setState(() {
      _query = '';
      _selectedObraId = null;
      _selectedEstat = null;
      _selectedPrioritat = null;
      _selectedCriticitat = null;
      _selectedSort = _IncidenciaListSort.mesRecents;
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

    final descripcio = item.descripcio.toLowerCase();
    final obraNom = (item.obraNom ?? '').toLowerCase();
   
    final estat = (item.estat ?? '').toLowerCase();
    final categoria = (item.categoria?.toString() ?? '');
    final id = item.id.toString();
    final idObra = item.idObra.toString();
    final idTasca = item.idTasca?.toString() ?? '';

    return descripcio.contains(query) ||
        obraNom.contains(query) ||
        estat.contains(query) ||
        categoria.contains(query) ||
        id.contains(query) ||
        idObra.contains(query) ||
        idTasca.contains(query);
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
      case _IncidenciaListSort.mesAntigues:
        items.sort((a, b) => _compareDateAsc(a.dataInici, b.dataInici));
        return;

      case _IncidenciaListSort.criticitatDesc:
        items.sort((a, b) {
          final criticitat = b.criticitat.compareTo(a.criticitat);
          if (criticitat != 0) return criticitat;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case _IncidenciaListSort.prioritatDesc:
        items.sort((a, b) {
          final prioritat = b.prioritat.compareTo(a.prioritat);
          if (prioritat != 0) return prioritat;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case _IncidenciaListSort.obraAsc:
        items.sort((a, b) {
          final obra = (a.obraNom ?? '').toLowerCase().compareTo((b.obraNom ?? '').toLowerCase());
          if (obra != 0) return obra;
          return _compareDateDesc(a.dataInici, b.dataInici);
        });
        return;

      case _IncidenciaListSort.mesRecents:
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

  Future<void> _handleCardTap(IncidenciaListItem item) async {
    // Aquí pots connectar directament amb el teu detail screen existent.
    //
    // Exemple quan vulguis activar-ho:
    //
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => IncidenciaDetailScreen(
    //       incidenciaId: item.id,
    //     ),
    //   ),
    // );
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
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      body: FutureBuilder<IncidenciaListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                IncidenciaListHeaderCard(
                  title: 'Problemes i incidències',
                  subtitle:
                      'Vista resumida de les incidències vinculades a les obres de l’empresa, amb filtres per localitzar ràpidament els casos més rellevants.',
                  count: filtered.length,
                ),
                const SizedBox(height: 16),
                IncidenciaSearchField(
                  controller: _searchController,
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
                  onClearFilters: _clearFilters,
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  IncidenciaListEmptyState(
                    title: _query.trim().isEmpty &&
                            _selectedObraId == null &&
                            _selectedEstat == null &&
                            _selectedPrioritat == null &&
                            _selectedCriticitat == null
                        ? 'No hi ha incidències disponibles'
                        : 'Cap incidència coincideix amb els filtres',
                    message: _query.trim().isEmpty &&
                            _selectedObraId == null &&
                            _selectedEstat == null &&
                            _selectedPrioritat == null &&
                            _selectedCriticitat == null
                        ? 'Quan l’empresa tengui incidències registrades, apareixeran aquí.'
                        : 'Prova de canviar la cerca o llevar algun filtre.',
                    icon: _query.trim().isEmpty &&
                            _selectedObraId == null &&
                            _selectedEstat == null &&
                            _selectedPrioritat == null &&
                            _selectedCriticitat == null
                        ? Icons.inbox_outlined
                        : Icons.search_off_rounded,
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

abstract final class _IncidenciaListSort {
  static const String mesRecents = 'mes_recents';
  static const String mesAntigues = 'mes_antigues';
  static const String criticitatDesc = 'criticitat_desc';
  static const String prioritatDesc = 'prioritat_desc';
  static const String obraAsc = 'obra_asc';
}