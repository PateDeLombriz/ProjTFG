import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/obra_screens/obra_profile_screen.dart';
import 'package:front_end/services/tasques_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

class TascaDetailScreen extends StatefulWidget {
  final int tascaId;

  const TascaDetailScreen({
    super.key,
    required this.tascaId,
  });

  @override
  State<TascaDetailScreen> createState() => _TascaDetailScreenState();
}

class _TascaDetailScreenState extends State<TascaDetailScreen> {
  late final TascaService _service;
  late Future<TascaProfileData> _future;

  @override
  void initState() {
    super.initState();
    _service = TascaService(baseUrl: ApiConstants.baseUrl);
    _future = _service.fetchTascaProfile(widget.tascaId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchTascaProfile(widget.tascaId);
    });

    await _future;
  }

  void _openObra(Map<String, dynamic> obra) {
    final obraId = int.tryParse('${obra['id'] ?? ''}');

    if (obraId == null) {
      _showPendingNavigation('obra', 0);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ObraProfileScreen(
          obraId: obraId,
          baseUrl: ApiConstants.baseUrl,
        ),
      ),
    );
  }

  void _openTascaPare(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TascaDetailScreen(tascaId: id),
      ),
    );
  }

  void _showPendingNavigation(String label, int id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegació a $label #$id pendent de connectar.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Perfil de tasca'),
        actions: [
          IconButton(
            tooltip: 'Refresca',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<TascaProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return TascaErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return TascaEmptyState(onRetry: _reload);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                TascaHeroCard(data: data),
                const SizedBox(height: 16),

                TascaObraSection(
                  obra: data.obra,
                  onOpenObra: _openObra,
                ),
                const SizedBox(height: 16),

                TascaPareSection(
                  tascaPare: data.tascaPare,
                  onOpenTascaPare: _openTascaPare,
                ),
                const SizedBox(height: 16),

                TascaAssignacioSection(
                  assignacio: data.treballadorAssignat,
                  onOpenTreballador: (id) {
                    _showPendingNavigation('treballador', id);
                  },
                ),
                const SizedBox(height: 16),

                TascaIncidenciesSection(
                  incidencies: data.incidencies,
                  onOpenIncidencia: (id) {
                    _showPendingNavigation('incidència', id);
                  },
                ),
                const SizedBox(height: 16),

                TascaSolucionsSection(
                  solucions: data.solucions,
                  onOpenSolucio: (id) {
                    _showPendingNavigation('solució', id);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}