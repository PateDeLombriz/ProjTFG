import 'package:flutter/material.dart';
import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/screens/empresa/incidencia/inc_sol_form.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/screens/empresa/obra_screens/obra_profile_screen.dart';
import 'package:front_end/screens/empresa/incidencia/incidenciaDetail_screen.dart';
import 'package:front_end/screens/empresa/treballador_empresa/treballador_detail_screen.dart';
import 'package:front_end/screens/treballador/tasca/finalitzar_tasca_screen.dart';
import 'package:front_end/screens/treballador/incidencia/incidencia_report_screen.dart';
import 'package:front_end/services/tasques_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';
import 'package:front_end/shared/widgets/app_secondary_button.dart';
import 'package:front_end/shared/widgets/app_expandable_section.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

class TascaDetailScreen extends StatefulWidget {
  final int tascaId;
  // CANVI 2: paràmetre opcional; null → empresa per defecte
  final TascaProfileCapabilities? capabilities;

  const TascaDetailScreen({
    super.key,
    required this.tascaId,
    this.capabilities,
  });

  @override
  State<TascaDetailScreen> createState() => _TascaDetailScreenState();
}

class _TascaDetailScreenState extends State<TascaDetailScreen> {
  late final TascaService _service;
  late Future<_TascaDetailData> _future;
  late final IncidenciaService _incidenciaService;

  TascaProfileCapabilities get _caps =>
      widget.capabilities ?? const TascaProfileCapabilities.empresa();

  @override
  void initState() {
    super.initState();
    _service = TascaService(baseUrl: ApiConstants.baseUrl);
    _incidenciaService = IncidenciaService();
    _future = _loadData();
  }

  @override
  void dispose() {
    _incidenciaService.dispose();
    super.dispose();
  }

  Future<_TascaDetailData> _loadData() async {
    final profile = await _service.fetchTascaProfile(widget.tascaId);
    final treballadors =
        await _service.fetchTreballadorsDetallatsDeTasca(profile.tasca.id);

    return _TascaDetailData(
      profile: profile,
      treballadors: treballadors,
    );
  }

  IncidenciaDTO _incidenciaItemToDTO(
    Tasca tasca,
    TascaIncidenciaItem item,
  ) {
    return IncidenciaDTO(
      id: item.id,
      idObra: item.obraId ?? tasca.obraId,
      idTasca: item.tascaId ?? tasca.id,
      descripcio: item.descripcio,
      dataInici: item.dataInici ?? DateTime.now(),
      dataFi: item.dataFi,
      criticitat: item.criticitat ?? 1,
      prioritat: item.prioritat ?? 1,
      categoria: item.categoria ?? 0,
      estat: item.estat ?? 'pendent',
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadData();
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
        builder: (_) => TascaDetailScreen(
          tascaId: id,
          capabilities: widget.capabilities,
        ),
      ),
    );
  }

  void _openTreballador(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreballadorDetailScreen(treballadorId: id),
      ),
    );
  }

  void _openIncidencia(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncidenciaProfileScreen(
          incidenciaId: id,
          workerView: _caps.canComplete || _caps.canReportIncidencia,
        ),
      ),
    );
  }

  Future<void> _handleSelectTascaPare(Tasca tasca) async {
    try {
      final options = await _service.fetchTasquesPerObra(tasca.obraId);
      final disponibles =
          options.where((option) => option.id != tasca.id).toList();

      if (!mounted) return;

      if (disponibles.isEmpty) {
        _snack(
            'No hi ha altres tasques disponibles per seleccionar com a tasca pare.');
        return;
      }

      final selected = await showDialog<TascaOption>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Seleccionar tasca pare'),
          children: [
            for (final option in disponibles)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, option),
                child: Text(
                  option.desc.trim().isEmpty
                      ? 'Tasca #${option.id}'
                      : option.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );

      if (selected == null) return;

      await _service.updateTascaPare(tasca.id, selected.id);

      if (!mounted) return;
      _snack('Tasca pare actualitzada correctament.', success: true);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Error actualitzant la tasca pare: $e');
    }
  }

  Future<void> _handleUnlinkTascaPare(Tasca tasca) async {
    final confirmed = await _confirm(
      title: 'Desvincular tasca pare?',
      message: 'Aquesta tasca deixarà de dependre de la tasca pare actual.',
      confirmLabel: 'Desvincular',
      destructive: true,
    );

    if (confirmed != true) return;

    try {
      await _service.updateTascaPare(tasca.id, null);

      if (!mounted) return;
      _snack('Tasca pare desvinculada correctament.', success: true);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Error desvinculant la tasca pare: $e');
    }
  }

  List<UsuariOption> _toUsuariOptions(List<TreballadorListItem> treballadors) {
    return treballadors
        .map(
          (t) => UsuariOption(
            id: t.id,
            nom: t.nom,
            cognoms: t.cognoms ?? '',
          ),
        )
        .toList();
  }

  Future<void> _handleAddTreballadors(
    Tasca tasca,
    List<UsuariOption> seleccionatsActuals,
  ) async {
    try {
      final tots = await _service.fetchTreballadors();

      if (!mounted) return;

      final selected = await showDialog<List<UsuariOption>>(
        context: context,
        builder: (_) => SelectTreballadorsDialog(
          tots: tots,
          seleccionats: seleccionatsActuals,
        ),
      );

      if (selected == null) return;

      await _service.syncTreballadors(tasca.id, selected);

      if (!mounted) return;
      _snack('Treballadors actualitzats correctament.', success: true);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Error actualitzant els treballadors: $e');
    }
  }

  Future<void> _handleRemoveTreballador(
      Tasca tasca, TreballadorListItem usuari) async {
    final confirmed = await _confirm(
      title: 'Desassignar treballador?',
      message: '${usuari.nomComplet} deixarà d’estar assignat a aquesta tasca.',
      confirmLabel: 'Desassignar',
      destructive: true,
    );

    if (confirmed != true) return;

    try {
      await _service.removeTreballadorFromTasca(
        tascaId: tasca.id,
        treballadorId: usuari.id,
      );

      if (!mounted) return;
      _snack('Treballador desassignat correctament.', success: true);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Error desassignant el treballador: $e');
    }
  }

  Future<void> _handleCreateIncidencia(Tasca tasca) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IncidenciaFormScreen(
          obraId: tasca.obraId,
        ),
      ),
    );

    if (created == true) {
      await _reload();
    }
  }

  Future<void> _handleEditIncidencia(
    Tasca tasca,
    TascaIncidenciaItem incidencia,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IncidenciaFormScreen(
          obraId: incidencia.obraId ?? tasca.obraId,
          initial: _incidenciaItemToDTO(tasca, incidencia),
        ),
      ),
    );

    if (updated == true) {
      await _reload();
    }
  }

  Future<void> _handleDeleteIncidencia(TascaIncidenciaItem incidencia) async {
    final confirmed = await _confirm(
      title: 'Eliminar incidència?',
      message: 'La incidència #${incidencia.id} s’eliminarà definitivament.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (confirmed != true) return;

    try {
      await _incidenciaService.deleteIncidencia(incidencia.id);

      if (!mounted) return;
      _snack('Incidència eliminada correctament.', success: true);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Error eliminant la incidència: $e');
    }
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
      backgroundColor: scheme.primaryContainer.withOpacity(0.06),
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
      body: FutureBuilder<_TascaDetailData>(
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
          final viewData = snapshot.data;
          if (viewData == null) {
            return TascaEmptyState(onRetry: _reload);
          }

          final data = viewData.profile;
          final treballadors = viewData.treballadors;

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
                const SizedBox(height: 16),
                TascaTreballadorsSection(
                  treballadors: treballadors,
                  onAddTreballadors: () => _handleAddTreballadors(
                    data.tasca,
                    _toUsuariOptions(treballadors),
                  ),
                  onOpenTreballador: _openTreballador,
                  onRemoveTreballador: (treballador) =>
                      _handleRemoveTreballador(data.tasca, treballador),
                ),
                const SizedBox(height: 16),
                TascaIncidenciesSection(
                  incidencies: data.incidencies,
                  onOpenIncidencia: _openIncidencia,
                  onCreateIncidencia: () => _handleCreateIncidencia(data.tasca),
                  onEditIncidencia: (incidencia) =>
                      _handleEditIncidencia(data.tasca, incidencia),
                  onDeleteIncidencia: _handleDeleteIncidencia,
                ),
                const SizedBox(height: 16),
                TascaPareSection(
                  tascaPare: data.tascaPare,
                  onOpenTascaPare: _openTascaPare,
                  onSelectTascaPare: () => _handleSelectTascaPare(data.tasca),
                  onUnlinkTascaPare: () => _handleUnlinkTascaPare(data.tasca),
                ),
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
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(
      accentBorder: true,
      title: 'Accions del treballador',
      icon: Icons.engineering_outlined,
      //accent: scheme.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (caps.canComplete)
            AppPrimaryButton(
              label: 'Finalitzar tasca',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => _navigateFinalitzar(context),
            ),
          if (caps.canComplete && caps.canReportIncidencia)
            const SizedBox(height: 10),
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

class _TascaDetailData {
  final TascaProfileData profile;
  final List<TreballadorListItem> treballadors;

  const _TascaDetailData({
    required this.profile,
    required this.treballadors,
  });
}
