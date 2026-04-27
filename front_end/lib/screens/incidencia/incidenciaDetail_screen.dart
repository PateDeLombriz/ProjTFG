import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/screens/obra_screens/obra_profile_screen.dart';
import 'package:front_end/screens/tasca_screens/tasca_detail_screen.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/widgets/incidencia_widgets.dart';
import 'package:front_end/services/obra_service.dart';

class IncidenciaProfileScreen extends StatefulWidget {
  final int incidenciaId;
  final String baseUrl = ApiConstants.baseUrl;

  IncidenciaProfileScreen({
    super.key,
    required this.incidenciaId,
  });

  @override
  State<IncidenciaProfileScreen> createState() =>
      _IncidenciaProfileScreenState();
}

class _IncidenciaProfileScreenState extends State<IncidenciaProfileScreen> {
  late final IncidenciaService _service;
  
  bool _loading = true;
  String? _error;
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
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text('Incidència #${widget.incidenciaId}'),
        centerTitle: false,
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
        message: 'No s’han pogut carregar les dades de la incidència.',
        onRetry: _load,
      );
    }

    final incidencia = profile.incidencia;
    final obra = profile.obra;
    final tasca = profile.tasca;
    final solucions = profile.solucions;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        IncidenciaHeaderCard(incidencia: incidencia),
        const SizedBox(height: 14),

        IncidenciaCompactInfoPanel(incidencia: incidencia),
        const SizedBox(height: 14),

        IncidenciaSectionBlock(
          title: 'Obra associada',
          icon: Icons.apartment_rounded,
          initiallyExpanded: true,
          child: obra == null
              ? const IncidenciaEmptyState(
                  text: 'No s’ha trobat informació de l’obra associada.',
                )
              : IncidenciaObraCard(
                  obra: obra,
                  onTap: () => _openObra(context, obra.id),
                ),
        ),
        const SizedBox(height: 14),

        IncidenciaSectionBlock(
          title: 'Tasca associada',
          icon: Icons.task_alt_outlined,
          initiallyExpanded: false,
          child: tasca == null
              ? const IncidenciaEmptyState(
                  text: 'Aquesta incidència no està associada a cap tasca.',
                )
              : IncidenciaTascaCard(
                  tasca: tasca,
                  onTap: () => _openTasca(context, tasca.id),
                ),
        ),
        const SizedBox(height: 14),

        IncidenciaSectionBlock(
          title: 'Solucions',
          icon: Icons.build_circle_outlined,
          count: solucions.length,
          initiallyExpanded: true,
          child: IncidenciaSolucionsSectionBody(
            solucions: solucions,
            onTapItem: _handleTapSolucio,
          ),
        ),
      ],
    );
  }

  void _openObra(BuildContext context, int obraId) async {
    final os = ObraService(baseUrl: widget.baseUrl);
    if (!mounted) return;

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
        ),
      ),
    );
  }

  void _handleTapSolucio(IncidenciaSolucioItem solucio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solució #${solucio.id}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        Center(child: CircularProgressIndicator()),
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
                'No s’ha pogut carregar la incidència',
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