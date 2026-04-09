import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/obra_screens/obra_profile_screen.dart';
import 'package:front_end/services/tasques_service.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

class TascaProfileScreen extends StatefulWidget {
  final int tascaId;
  final String baseUrl;
  const TascaProfileScreen({
    super.key,
    required this.tascaId,
    required this.baseUrl,
  });

  @override
  State<TascaProfileScreen> createState() => _TascaProfileScreenState();
}

class _TascaProfileScreenState extends State<TascaProfileScreen> {
  late final TascaService _service;
  late Future<TascaProfileData> _future;

  @override
  void initState() {
    super.initState();
    _service = TascaService(baseUrl: _resolveApiBaseUrl());
    _future = _service.fetchTascaProfile(widget.tascaId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchTascaProfile(widget.tascaId);
    });
    await _future;
  }

  void _openObraInt(int obra) {
    print('Id de lobra: '+ obra.toString());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ObraProfileScreen(obraId: obra, baseUrl: '',),
      ),
    );
  }

   void _openObraMap(Map<String, dynamic> obra) {
    print('Id de lobra: '+ obra['id'].toString());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ObraProfileScreen(obraId: obra['id'], baseUrl: '',),
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
            onPressed: () {
              _reload();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<TascaProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  onOpenObra: _openObraMap,
                ),
                const SizedBox(height: 16),
                TascaPareSection(
                  tascaPare: data.tascaPare,
                  onOpenTascaPare: (id) => _showPendingNavigation('tasca', id),
                ),
                const SizedBox(height: 16),
                TascaAssignacioSection(
                  assignacio: data.treballadorAssignat,
                  onOpenTreballador: (id) =>
                      _showPendingNavigation('treballador', id),
                ),
                const SizedBox(height: 16),
                TascaIncidenciesSection(
                  incidencies: data.incidencies,
                  onOpenIncidencia: (id) =>
                      _showPendingNavigation('incidència', id),
                ),
                const SizedBox(height: 16),
                TascaSolucionsSection(
                  solucions: data.solucions,
                  onOpenSolucio: (id) => _showPendingNavigation('solució', id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _resolveApiBaseUrl() {
  return kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';
}
