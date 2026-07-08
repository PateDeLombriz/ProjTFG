import 'package:flutter/material.dart';

import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/services/sol_recurs_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_search_field.dart';
import 'package:front_end/widgets/sol_recurs_widgets.dart';

class SolRecursListScreen extends StatefulWidget {
  const SolRecursListScreen({
    super.key,
  });

  @override
  State<SolRecursListScreen> createState() => _SolRecursListScreenState();
}

class _SolRecursListScreenState extends State<SolRecursListScreen> {
  static final String _baseUrl = ApiConstants.baseUrl;

  late final SolRecursService _service;
  final TextEditingController _searchController = TextEditingController();

  Future<SolRecursListData>? _future;
  String _query = '';
  String? _selectedAprovacio;
  String? _selectedEntrega;
  String? _selectedObra;
  String _selectedSort = SolRecursSortValues.dataNecessitatAsc;

  @override
  void initState() {
    super.initState();
    _service = SolRecursService(baseUrl: _baseUrl);
    _future = _buildFuture();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<SolRecursListData> _buildFuture() async {
    await _service.requireEmpresaId();
    return _service.fetchEmpresaSolRecursData();
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
        (_selectedAprovacio?.trim().isNotEmpty == true) ||
        (_selectedEntrega?.trim().isNotEmpty == true) ||
        (_selectedObra?.trim().isNotEmpty == true) ||
        _selectedSort != SolRecursSortValues.dataNecessitatAsc;
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _selectedAprovacio = null;
      _selectedEntrega = null;
      _selectedObra = null;
      _selectedSort = SolRecursSortValues.dataNecessitatAsc;
      _searchController.clear();
    });
  }

  List<SolRecurs> _applyFilters(List<SolRecurs> items) {
    final filtered = items.where((item) {
      if (!_matchesQuery(item)) return false;
      if (!_matchesAprovacio(item)) return false;
      if (!_matchesEntrega(item)) return false;
      if (!_matchesObra(item)) return false;
      return true;
    }).toList();

    _sortItems(filtered);
    return filtered;
  }

  bool _matchesQuery(SolRecurs item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    final values = <String>[
      item.recursLabel,
      item.obraLabel,
      item.proveidorLabel,
      item.estatLabel,
      item.estatAprovacioLabel,
      item.quantitatLabel,
      item.comentari ?? '',
      item.recurs?.tipusRecurs ?? '',
      item.recurs?.unitatsMesura ?? '',
    ];

    return values.any((value) => value.toLowerCase().contains(query));
  }

  bool _matchesAprovacio(SolRecurs item) {
    final selected = _selectedAprovacio?.trim().toLowerCase();
    if (selected == null || selected.isEmpty) return true;

    return item.estat.trim().toLowerCase() == selected;
  }

  bool _matchesEntrega(SolRecurs item) {
    final selected = _selectedEntrega?.trim().toLowerCase();
    if (selected == null || selected.isEmpty) return true;

    switch (selected) {
      case SolRecursEntregaFilter.entregat:
        return item.hasEntrega;
      case SolRecursEntregaFilter.pendent:
        return !item.hasEntrega;
      default:
        return true;
    }
  }

  bool _matchesObra(SolRecurs item) {
    final selected = _selectedObra?.trim().toLowerCase();
    if (selected == null || selected.isEmpty) return true;

    return item.obraLabel.trim().toLowerCase() == selected;
  }

  void _sortItems(List<SolRecurs> items) {
    switch (_selectedSort) {
      case SolRecursSortValues.dataNecessitatDesc:
        items.sort((a, b) => _dateForNeed(b).compareTo(_dateForNeed(a)));
        return;

      case SolRecursSortValues.dataCreacioDesc:
        items.sort((a, b) => _dateForCreation(b).compareTo(_dateForCreation(a)));
        return;

      case SolRecursSortValues.recursAsc:
        items.sort((a, b) {
          final byRecurs = a.recursLabel
              .toLowerCase()
              .compareTo(b.recursLabel.toLowerCase());
          if (byRecurs != 0) return byRecurs;
          return a.obraLabel.toLowerCase().compareTo(b.obraLabel.toLowerCase());
        });
        return;

      case SolRecursSortValues.obraAsc:
        items.sort((a, b) {
          final byObra = a.obraLabel
              .toLowerCase()
              .compareTo(b.obraLabel.toLowerCase());
          if (byObra != 0) return byObra;
          return a.recursLabel
              .toLowerCase()
              .compareTo(b.recursLabel.toLowerCase());
        });
        return;

      case SolRecursSortValues.aprovacioAsc:
        items.sort((a, b) {
          final byAprovacio = _aprovacioRank(a).compareTo(_aprovacioRank(b));
          if (byAprovacio != 0) return byAprovacio;
          return _dateForNeed(a).compareTo(_dateForNeed(b));
        });
        return;

      case SolRecursSortValues.dataNecessitatAsc:
      default:
        items.sort((a, b) => _dateForNeed(a).compareTo(_dateForNeed(b)));
        return;
    }
  }

  DateTime _dateForNeed(SolRecurs item) {
    return item.dataNecessitat ?? item.dataCreacio ?? DateTime(1970);
  }

  DateTime _dateForCreation(SolRecurs item) {
    return item.dataCreacio ?? item.dataNecessitat ?? DateTime(1970);
  }

  int _aprovacioRank(SolRecurs item) {
    switch (item.estat) {
      case 'pendent':
        return 0;
      case 'aprovada':
        return 1;
      case 'rebutjada':
        return 2;
      default:
        return 3;
    }
  }

  List<String> _obraOptions(List<SolRecurs> items) {
    final values = items
        .map((item) => item.obraLabel.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return values;
  }

  Future<void> _handleItemTap(SolRecurs sollicitud) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SolRecursDetailBottomSheet(
          sollicitud: sollicitud,
          onSaveEstat: (estat) => _updateSolRecursEstat(sollicitud, estat),
        );
      },
    );

    if (updated == true) {
      await _reload();
    }
  }

  Future<void> _updateSolRecursEstat(
    SolRecurs sollicitud,
    String estat,
  ) async {
    await _service.aprovarSolRecurs(sollicitud.id, estat);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estat de la sol·licitud actualitzat correctament.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primaryContainer.withOpacity(0.06),
      appBar: AppBar(
        title: const Text('Sol·licituds de recursos'),
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
      body: FutureBuilder<SolRecursListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                SolRecursLoadingCard(),
                SizedBox(height: 12),
                SolRecursLoadingCard(),
                SizedBox(height: 12),
                SolRecursLoadingCard(),
              ],
            );
          }

          if (snapshot.hasError) {
            return SolRecursListErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return SolRecursListErrorState(
              message: 'No s’han rebut dades de sol·licituds de recursos.',
              onRetry: _reload,
            );
          }

          final filtered = _applyFilters(data.sollicituds);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                SolRecursListHeaderCard(
                  title: 'Sol·licituds de recursos',
                  subtitle:
                      'Llistat resumit de peticions de material i recursos associades a les obres de l’empresa.',
                  count: data.total,
                  activeCount: filtered.length,
                  pendentsCount: data.pendentsCount,
                  entregatsCount: data.entregatsCount,
                ),
                const SizedBox(height: 16),
                AppSearchField(
                  controller: _searchController,
                  hintText: 'Cerca per recurs, obra, estat o proveïdor',
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
                SolRecursListFilterBar(
                  obraOptions: _obraOptions(data.sollicituds),
                  selectedAprovacio: _selectedAprovacio,
                  selectedEntrega: _selectedEntrega,
                  selectedObra: _selectedObra,
                  selectedSort: _selectedSort,
                  onAprovacioChanged: (value) {
                    setState(() {
                      _selectedAprovacio = value;
                    });
                  },
                  onEntregaChanged: (value) {
                    setState(() {
                      _selectedEntrega = value;
                    });
                  },
                  onObraChanged: (value) {
                    setState(() {
                      _selectedObra = value;
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
                if (data.sollicituds.isEmpty)
                  const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Encara no hi ha sol·licituds',
                    message:
                        'Quan l\’empresa o les obres registrin sol·licituds de recurs, apareixeran aquí.',
                  )
                else if (filtered.isEmpty)
                  AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Cap sol·licitud coincideix amb els filtres',
                    message:
                        _hasActiveFilters
                            ? 'Prova amb una altra cerca, un altre estat, una altra obra o un altre criteri d\’ordenació.'
                            : 'No s\’ha trobat cap sol·licitud disponible.',
                  )
                else
                  ...List.generate(filtered.length, (index) {
                    final sollicitud = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1 ? 0 : 12,
                      ),
                      child: SolRecursListItemCard(
                        sollicitud: sollicitud,
                        onTap: () => _handleItemTap(sollicitud),
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
