import 'package:flutter/material.dart';

import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/services/sol_recurs_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
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
    return _service.fetchMyEmpresaSolRecursData();
  }

  Future<void> _reload() async {
    FocusScope.of(context).unfocus();

    final nextFuture = _buildFuture();
    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<SolRecurs> _applyFilter(List<SolRecurs> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      final recurs = item.recursLabel.toLowerCase();
      final obra = item.obraLabel.toLowerCase();
      final proveidor = item.proveidorLabel.toLowerCase();
      final estat = item.estatLabel.toLowerCase();
      final comentari = (item.comentari ?? '').toLowerCase();
      final tipus = (item.recurs?.tipusRecurs ?? '').toLowerCase();
      final quantitat = item.quantitatLabel.toLowerCase();

      return recurs.contains(query) ||
          obra.contains(query) ||
          proveidor.contains(query) ||
          estat.contains(query) ||
          comentari.contains(query) ||
          tipus.contains(query) ||
          quantitat.contains(query);
    }).toList();
  }

  void _handleItemTap(SolRecurs sollicitud) {
    // TODO:
    // Quan tenguis creada la pantalla de detall, obre-la aquí.
    // Exemple:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => SolRecursDetailScreen(solRecursId: sollicitud.id),
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
        title: const Text('Sol·licituds de recursos'),
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

          final filtered = _applyFilter(data.sollicituds);

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
                  pendentsCount: data.pendentsCount,
                  entregatsCount: data.entregatsCount,
                ),
                const SizedBox(height: 16),
                SolRecursSearchField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (data.sollicituds.isEmpty)
                  const SolRecursListEmptyState(
                    title: 'Encara no hi ha sol·licituds',
                    message:
                        'Quan l’empresa o les obres registrin sol·licituds de recurs, apareixeran aquí.',
                  )
                else if (filtered.isEmpty)
                  const SolRecursListEmptyState(
                    title: 'Cap resultat per aquesta cerca',
                    message:
                        'No s’ha trobat cap sol·licitud que coincideixi amb el text introduït.',
                  )
                else
                  ...[
                    for (int i = 0; i < filtered.length; i++) ...[
                      SolRecursListItemCard(
                        sollicitud: filtered[i],
                        onTap: () => _handleItemTap(filtered[i]),
                      ),
                      if (i != filtered.length - 1) const SizedBox(height: 12),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}