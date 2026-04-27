import 'package:flutter/material.dart';

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/screens/treballador/treballador_detail_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/widgets/treballador_widgets.dart';

class TreballadorsListScreen extends StatefulWidget {
  const TreballadorsListScreen({
    super.key,
  });

  @override
  State<TreballadorsListScreen> createState() => _TreballadorsListScreenState();
}

class _TreballadorsListScreenState extends State<TreballadorsListScreen> {
  static final String _baseUrl = ApiConstants.baseUrl;

  late final TreballadorService _service;
  final TextEditingController _searchController = TextEditingController();

  Future<TreballadorListData>? _future;

  String _query = '';
  String? _selectedEstat;
  String? _selectedCarrec;
  String _selectedSort = TreballadorSortValues.nomAsc;

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _baseUrl);
    _future = _buildFuture();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<TreballadorListData> _buildFuture() async {
    final idEmpresa = await _service.requireEmpresaId();
    return _service.fetchTreballadorsEmpresaData(idEmpresa);
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
        (_selectedEstat?.trim().isNotEmpty == true) ||
        (_selectedCarrec?.trim().isNotEmpty == true) ||
        _selectedSort != TreballadorSortValues.nomAsc;
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _selectedEstat = null;
      _selectedCarrec = null;
      _selectedSort = TreballadorSortValues.nomAsc;
      _searchController.clear();
    });
  }

  List<TreballadorListItem> _applyFilters(List<TreballadorListItem> items) {
    final filtered = items.where((item) {
      if (!_matchesQuery(item)) return false;
      if (!_matchesEstat(item)) return false;
      if (!_matchesCarrec(item)) return false;
      return true;
    }).toList();

    _sortItems(filtered);
    return filtered;
  }

  bool _matchesQuery(TreballadorListItem item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    return item.searchableText.contains(query);
  }

  bool _matchesEstat(TreballadorListItem item) {
    final selected = _selectedEstat?.trim().toLowerCase();
    if (selected == null || selected.isEmpty) return true;

    return item.estatLabel.toLowerCase() == selected;
  }

  bool _matchesCarrec(TreballadorListItem item) {
    final selected = _selectedCarrec?.trim().toLowerCase();
    if (selected == null || selected.isEmpty) return true;

    return item.carrecLabel.toLowerCase() == selected;
  }

  void _sortItems(List<TreballadorListItem> items) {
    switch (_selectedSort) {
      case TreballadorSortValues.nomDesc:
        items.sort(
          (a, b) =>
              b.nomComplet.toLowerCase().compareTo(a.nomComplet.toLowerCase()),
        );
        return;

      case TreballadorSortValues.carrecAsc:
        items.sort((a, b) {
          final byCarrec = a.carrecLabel
              .toLowerCase()
              .compareTo(b.carrecLabel.toLowerCase());
          if (byCarrec != 0) return byCarrec;

          return a.nomComplet
              .toLowerCase()
              .compareTo(b.nomComplet.toLowerCase());
        });
        return;

      case TreballadorSortValues.estatAsc:
        items.sort((a, b) {
          final byEstat = a.estatLabel
              .toLowerCase()
              .compareTo(b.estatLabel.toLowerCase());
          if (byEstat != 0) return byEstat;

          return a.nomComplet
              .toLowerCase()
              .compareTo(b.nomComplet.toLowerCase());
        });
        return;

      case TreballadorSortValues.nomAsc:
      default:
        items.sort(
          (a, b) =>
              a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase()),
        );
        return;
    }
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
        title: const Text('Treballadors'),
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
      body: FutureBuilder<TreballadorListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return TreballadorListErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return TreballadorListErrorState(
              message: 'No s’han rebut dades de treballadors.',
              onRetry: _reload,
            );
          }

          final filtered = _applyFilters(data.treballadors);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                TreballadorListHeaderCard(
                  title: data.empresaNom != null && data.empresaNom!.trim().isNotEmpty
                      ? 'Equip de ${data.empresaNom}'
                      : 'Equip de treball',
                  subtitle:
                      'Llistat resumit dels treballadors de l’empresa amb cerca, filtres i ordenació.',
                  count: data.treballadors.length,
                  activeCount: filtered.length,
                  actiusCount: data.totalActius,
                ),
                const SizedBox(height: 16),
                TreballadorSearchField(
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
                TreballadorListFilterBar(
                  estatOptions: data.estatsDisponibles,
                  carrecOptions: data.carrecsDisponibles,
                  selectedEstat: _selectedEstat,
                  selectedCarrec: _selectedCarrec,
                  selectedSort: _selectedSort,
                  onEstatChanged: (value) {
                    setState(() {
                      _selectedEstat = value;
                    });
                  },
                  onCarrecChanged: (value) {
                    setState(() {
                      _selectedCarrec = value;
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
                  TreballadorListEmptyState(
                    title: _hasActiveFilters
                        ? 'Cap treballador coincideix amb els filtres'
                        : 'No hi ha treballadors',
                    message: _hasActiveFilters
                        ? 'Prova amb una altra cerca, un altre estat o un altre càrrec.'
                        : 'Quan tenguis treballadors disponibles, apareixeran aquí.',
                  )
                else
                  ...List.generate(filtered.length, (index) {
                    final treballador = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1 ? 0 : 12,
                      ),
                      child: TreballadorListItemCard(
                        treballador: treballador,
                        onTap: () {
                          
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => TreballadorDetailScreen(
                                 treballadorId: treballador.id,
                               ),
                             ),
                           );
                        },
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