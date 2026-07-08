import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/empresa/obra_screens/obra_profile_screen.dart';
import 'package:front_end/screens/empresa/tasca_screens/tasca_detail_screen.dart';
import 'package:front_end/screens/treballador/obra/treballador_obra_info_screen.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/widgets/incidencia_widgets.dart';

class IncidenciaProfileScreen extends StatefulWidget {
  final int incidenciaId;
  final bool workerView;
  final String baseUrl = ApiConstants.baseUrl;

  IncidenciaProfileScreen({
    super.key,
    required this.incidenciaId,
    this.workerView = false,
  });

  @override
  State<IncidenciaProfileScreen> createState() =>
      _IncidenciaProfileScreenState();
}

class _IncidenciaProfileScreenState extends State<IncidenciaProfileScreen> {
  late final IncidenciaService _service;

  bool _loading = true;
  String? _error;
  String? _localEstatOverride;
  bool _localTascaHidden = false;
  int _localSolucioDraftId = -1;
  List<IncidenciaSolucioItem>? _localSolucions;
  IncidenciaProfileData? _profile;

  @override
  void initState() {
    super.initState();
    _service = IncidenciaService();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile =
          await _service.fetchIncidenciaProfile(widget.incidenciaId);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _localEstatOverride = null;
        _localTascaHidden = false;
        _localSolucions = List<IncidenciaSolucioItem>.from(profile.solucions);
        _localSolucioDraftId = -1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primaryContainer.withOpacity(0.06),
      appBar: AppBar(
        title: Text('Incidència #${widget.incidenciaId}'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Recarrega',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const _IncidenciaLoadingView();
    }

    if (_error != null) {
      return _IncidenciaErrorView(
        message: _error!,
        onRetry: _load,
      );
    }

    final profile = _profile;
    if (profile == null) {
      return _IncidenciaErrorView(
        message: 'No s\'han pogut carregar les dades de la incidència.',
        onRetry: _load,
      );
    }

    final incidencia = profile.incidencia;
    final obra = profile.obra;
    final tasca = _localTascaHidden ? null : profile.tasca;
    final solucions = _localSolucions ?? profile.solucions;
    final displayEstat = _localEstatOverride ?? incidencia.estat;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        IncidenciaHeaderCard(
          incidencia: incidencia,
          estatOverride: displayEstat,
          onChangeEstat: () => _handleChangeEstat(incidencia),
        ),
        const SizedBox(height: 14),
        IncidenciaCompactInfoPanel(
          incidencia: incidencia,
          estatOverride: displayEstat,
        ),
        const SizedBox(height: 14),
        IncidenciaSectionBlock(
          title: 'Obra associada',
          icon: Icons.apartment_rounded,
          initiallyExpanded: true,
          child: obra == null
              ? const IncidenciaEmptyState(
                  text: 'No s\'ha trobat informació de l\'obra associada.',
                )
              : IncidenciaObraCard(
                  obra: obra,
                  onTap: () => _openObra(context, obra.id, obra.nom),
                ),
        ),
        const SizedBox(height: 14),
        IncidenciaSectionBlock(
          title: 'Tasca de incidència',
          icon: Icons.task_alt_rounded,
          count: tasca == null ? 0 : 1,
          initiallyExpanded: true,
          onAdd: _handleAssignTasca,
          addTooltip: 'Tasca on ha succeït la incidència',
          child: tasca == null
              ? IncidenciaNoTascaPanel(
                  onAssignExisting: _handleAssignTasca,
                  onCreateNew: _handleCreateTasca,
                )
              : IncidenciaTascaCard(
                  tasca: tasca,
                  onTap: () => _openTasca(context, tasca.id),
                  onEdit: () => _handleEditTasca(tasca),
                  onDelete: () => _handleDeleteTasca(tasca),
                ),
        ),
        const SizedBox(height: 14),
        IncidenciaSectionBlock(
          title: 'Solucions',
          icon: Icons.build_circle_outlined,
          count: solucions.length,
          initiallyExpanded: true,
          onAdd: _handleAddSolucio,
          addTooltip: 'Afegir solució',
          child: IncidenciaSolucionsSectionBody(
            solucions: solucions,
            onAdd: _handleAddSolucio,
            onTapItem: _handleTapSolucio,
            onEdit: _handleEditSolucio,
            onDelete: _handleDeleteSolucio,
          ),
        ),
      ],
    );
  }

  void _openObra(BuildContext context, int obraId, String nomObra) {
    if (widget.workerView) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TreballadorObraInfoScreen(
            obra: Obra.fromMap({'id': obraId, 'nom': nomObra}),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ObraProfileScreen(
          obraId: obraId,
          baseUrl: widget.baseUrl,
        ),
      ),
    );
  }

  void _openTasca(BuildContext context, int tascaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TascaDetailScreen(
          tascaId: tascaId,
          capabilities: widget.workerView
              ? const TascaProfileCapabilities.treballador()
              : null,
        ),
      ),
    );
  }

  Future<void> _handleChangeEstat(Incidencia incidencia) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidenciaEstatBottomSheet(
        initialEstat: _localEstatOverride ?? incidencia.estat,
      ),
    );

    if (selected == null || selected.trim().isEmpty) return;

    setState(() => _localEstatOverride = selected);
    _showPendingSync(
      'Estat canviat a ${_estatLabel(selected)}. Pendent de sincronitzar amb backend.',
    );
  }

  Future<void> _handleAssignTasca() async {
    await _showActionSheet(
      title: 'Associar tasca existent',
      message:
          'El flux visual queda preparat amb el mateix patró de la resta de pantalles. Quan connectem backend, aquí es carregarà un desplegable amb les tasques disponibles de l\'obra.',
      icon: Icons.playlist_add_check_rounded,
      primaryLabel: 'Preparat',
    );
  }

  Future<void> _handleCreateTasca() async {
    await _showActionSheet(
      title: 'Crear tasca nova',
      message:
          'El botó de crear ja queda integrat amb la UI. En la següent fase s\'obrirà el formulari de tasca i s\'associarà el resultat a aquesta incidència.',
      icon: Icons.add_task_rounded,
      primaryLabel: 'Preparat',
    );
  }

  Future<void> _handleEditTasca(Tasca tasca) async {
    await _showActionSheet(
      title: 'Editar tasca',
      message:
          'Acció visual preparada per editar la tasca #${tasca.id}. Mantinc el frontend consistent i ho connectarem amb el formulari/endpoints existents en la següent fase.',
      icon: Icons.edit_rounded,
      primaryLabel: 'Preparat',
    );
  }


  Future<void> _handleDeleteTasca(Tasca tasca) async {
    final confirmed = await _confirm(
      title: 'Eliminar tasca?',
      message:
          'La tasca #${tasca.id} s\'eliminarà visualment d\'aquesta incidència. La persistència es connectarà amb backend després.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (confirmed == true) {
      setState(() => _localTascaHidden = true);
      _showPendingSync('Tasca eliminada localment. Pendent de sincronitzar.');
    }
  }

  Future<void> _handleAddSolucio() async {
    final result = await showModalBottomSheet<IncidenciaSolucioFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const IncidenciaSolucioEditorSheet(),
    );

    if (result == null) return;

    final current = List<IncidenciaSolucioItem>.from(
      _localSolucions ?? _profile?.solucions ?? const <IncidenciaSolucioItem>[],
    );

    final draft = IncidenciaSolucioItem(
      id: _localSolucioDraftId,
      descripcio: result.descripcio,
      eficacia: result.eficacia,
      costMonetari: result.costMonetari,
      costTemporal: result.costTemporal,
      impacte: result.impacte,
    );

    setState(() {
      current.add(draft);
      _localSolucioDraftId--;
      _localSolucions = current;
    });

    _showPendingSync('Solució afegida localment. Pendent de sincronitzar.');
  }

  void _handleTapSolucio(IncidenciaSolucioItem solucio) {
    _showPendingSync('Solució ${_displaySolucioId(solucio)} seleccionada.');
  }

  Future<void> _handleEditSolucio(IncidenciaSolucioItem solucio) async {
    final result = await showModalBottomSheet<IncidenciaSolucioFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidenciaSolucioEditorSheet(initial: solucio),
    );

    if (result == null) return;

    final current = List<IncidenciaSolucioItem>.from(
      _localSolucions ?? _profile?.solucions ?? const <IncidenciaSolucioItem>[],
    );
    final index = current.indexWhere((item) => item.id == solucio.id);
    if (index == -1) return;

    current[index] = IncidenciaSolucioItem(
      id: solucio.id,
      descripcio: result.descripcio,
      eficacia: result.eficacia,
      costMonetari: result.costMonetari,
      costTemporal: result.costTemporal,
      impacte: result.impacte,
    );

    setState(() => _localSolucions = current);
    _showPendingSync('Solució modificada localment. Pendent de sincronitzar.');
  }

  Future<void> _handleDeleteSolucio(IncidenciaSolucioItem solucio) async {
    final confirmed = await _confirm(
      title: 'Eliminar solució?',
      message:
          'La solució ${_displaySolucioId(solucio)} desapareixerà d\'aquesta vista. La persistència es connectarà amb backend després.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (confirmed == true) {
      final current = List<IncidenciaSolucioItem>.from(
        _localSolucions ??
            _profile?.solucions ??
            const <IncidenciaSolucioItem>[],
      )..removeWhere((item) => item.id == solucio.id);

      setState(() => _localSolucions = current);
      _showPendingSync('Solució eliminada localment. Pendent de sincronitzar.');
    }
  }

  Future<void> _showActionSheet({
    required String title,
    required String message,
    required IconData icon,
    required String primaryLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidenciaPreparedActionSheet(
        title: title,
        message: message,
        icon: icon,
        primaryLabel: primaryLabel,
      ),
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
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  void _showPendingSync(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _displaySolucioId(IncidenciaSolucioItem solucio) {
    if (solucio.id < 0) return 'nova';
    return '#${solucio.id}';
  }

  String _estatLabel(String? estat) {
    final text = estat?.trim().toLowerCase();
    if (text == null || text.isEmpty) return 'Sense estat';

    switch (text) {
      case 'pendent':
        return 'Pendent';
      case 'en_curs':
      case 'en curs':
        return 'En curs';
      case 'resolta':
        return 'Resolta';
      case 'tancada':
        return 'Tancada';
      default:
        return estat!.trim();
    }
  }
}

class _IncidenciaLoadingView extends StatelessWidget {
  const _IncidenciaLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 120),
        AppLoadingIndicator(),
      ],
    );
  }
}

class _IncidenciaErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _IncidenciaErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outline.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: scheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                'No s\'ha pogut carregar la incidència',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Torna-ho a provar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
