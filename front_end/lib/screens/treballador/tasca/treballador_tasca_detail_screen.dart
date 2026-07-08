
import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/empresa/obra_screens/obra_profile_screen.dart';
import 'package:front_end/screens/treballador/tasca/finalitzar_tasca_screen.dart';
import 'package:front_end/screens/treballador/incidencia/incidencia_report_screen.dart';
import 'package:front_end/services/tasques_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/themes/app_colors.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';
import 'package:front_end/shared/widgets/app_secondary_button.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

class TascaTreballadorDetailScreen extends StatefulWidget {
  final int tascaId;
  // CANVI 2: paràmetre opcional; null → empresa per defecte
  final TascaProfileCapabilities? capabilities;

  const TascaTreballadorDetailScreen({
    super.key,
    required this.tascaId,
    this.capabilities,
  });

  @override
  State<TascaTreballadorDetailScreen> createState() => _TascaTreballadorDetailScreenState();
}

class _TascaTreballadorDetailScreenState extends State<TascaTreballadorDetailScreen> {
  late final TascaService _service;
  late Future<TascaProfileData> _future;

  TascaProfileCapabilities get _caps =>
      widget.capabilities ?? const TascaProfileCapabilities.treballador();

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
        builder: (_) => TascaTreballadorDetailScreen(tascaId: id),
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
            return const AppLoadingIndicator();
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

                // CANVI 3: accions de treballador (només si capabilities ho permet)
                if (_caps.canComplete || _caps.canReportIncidencia) ...[
                  const SizedBox(height: 24),
                  _WorkerActionsSection(
                    tascaId: data.tasca.id,
                    tascaDescripcio: data.tasca.descripcio,
                    caps: _caps,
                    onActionDone: _reload,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── ACCIONS DEL TREBALLADOR ─────────────────────────

class _WorkerActionsSection extends StatelessWidget {
  final int tascaId;
  final String tascaDescripcio;
  final TascaProfileCapabilities caps;
  final VoidCallback onActionDone;

  const _WorkerActionsSection({
    required this.tascaId,
    required this.tascaDescripcio,
    required this.caps,
    required this.onActionDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.engineering_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Accions del treballador',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (caps.canComplete)
            AppPrimaryButton(
              label: 'Finalitzar tasca',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => _navigateFinalitzar(context),
            ),
          if (caps.canComplete && caps.canReportIncidencia)
            const SizedBox(height: AppSpacing.sm),
          if (caps.canReportIncidencia)
            AppSecondaryButton(
              label: 'Reportar incidència',
              icon: Icons.report_problem_outlined,
              onPressed: () => _navigateIncidencia(context),
            ),
        ],
      ),
    );
  }

  void _navigateFinalitzar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalitzarTascaScreen(
          tascaId: tascaId,
          tascaDescripcio: tascaDescripcio,
        ),
      ),
    ).then((updated) {
      if (updated == true) onActionDone();
    });
  }

  void _navigateIncidencia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidenciaReportScreen(
          tascaId: tascaId,
          tascaDescripcio: tascaDescripcio,
        ),
      ),
    ).then((created) {
      if (created == true) onActionDone();
    });
  }
}

