import 'package:flutter/material.dart';

import 'package:front_end/models/obra_models.dart';
import 'package:front_end/screens/empresa/doc_form.dart';
import 'package:front_end/screens/empresa/inc_sol_form.dart';
import 'package:front_end/screens/empresa/solicRec_form.dart';
import 'package:front_end/screens/tasca_screens/tasca_form.dart';
import 'package:front_end/screens/obra_screens/obra_edit_screen.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/widgets/obra_widgets.dart';

class ObraProfileScreen extends StatefulWidget {
  final int obraId;
  final String baseUrl;
  const ObraProfileScreen({
    super.key,
    required this.baseUrl,
    required this.obraId,
  });

  @override
  State<ObraProfileScreen> createState() => _ObraProfileScreenState();
}

class _ObraProfileScreenState extends State<ObraProfileScreen> {
  static const String _baseUrl = ApiConstants.baseUrl;

  late final ObraService _obraService;

  ObraProfileData? _profileData;
  Map<String, dynamic> _obraRaw = {};
  bool _loading = true;
  String? _errorMessage;

  int get _obraId {
    final rawId = _obraRaw['id_obra'] ?? widget.obraId;
    print('Get obraId: rawId = $rawId');
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  String get _fallbackTitle {
    final rawName = _obraRaw['nom'] ?? widget.obraId;
    final text = rawName?.toString().trim();
    return (text == null || text.isEmpty) ? 'Obra' : text;
  }

  @override
  void initState() {
    super.initState();
    _obraService = ObraService(baseUrl: _baseUrl);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final obraId = _obraId;

    if (obraId <= 0) {
      setState(() {
        _loading = false;
        _errorMessage = 'ID d’obra no vàlid';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _obraService.fetchObraRaw(obraId);//Aqui dins athentica i agafa les dades
      final parsed = ObraProfileData.fromMap(raw);

      if (!mounted) return;
      setState(() {
        _obraRaw = raw;
        _profileData = parsed; //Aqui se li passa a la varaible que consumiran les seccions
        _loading = false;
      });
    } on ObraServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Error carregant l’obra';
      });
      _showSnack('Error: $e');
    }
  }

  Future<void> _deleteObra() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar obra'),
          content: const Text('Aquesta acció és irreversible. Vols continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel·la'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _obraService.deleteObra(_obraId);
      if (!mounted) return;
      _showSnack('Obra eliminada', success: true);
      Navigator.pop(context, true);
    } on ObraServiceException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _handleFabAction(String value) async {
    if (value == 'inc') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IncidenciaFormScreen()),
      );
    } else if (value == 'tasca') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TascaFormScreen()),
      );
    } else if (value == 'doc') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentObraScreen(obraId: _obraId),
        ),
      );
    } else if (value == 'rec') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SolRecursFormScreen(obraId: _obraId),
        ),
      );
    }

    await _fetchDetails();
  }

  @override
  Widget build(BuildContext context) {
    final title = _profileData?.obra.nom ?? _fallbackTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ObraEditScreen(
                    obra:  _obraRaw,
                  ),
                ),
              );

              if (updated != null) {
                await _fetchDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteObra,
          ),
        ],
      ),
      floatingActionButton: ObraFabMenu(
        onSelected: _handleFabAction,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
      //cas d'error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchDetails,
                child: const Text('Torna-ho a provar'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _profileData;
    if (data == null) {
      return const Center(
        child: Text('No s’ha pogut carregar la informació de l’obra'),
      );
    }

    final obra = data.obra;

    return RefreshIndicator(
      onRefresh: _fetchDetails,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          // Header amb nom, ubicació resumida, dates i pressupost
          ObraHeaderCard(obra: obra),
          const SizedBox(height: 12),
          ObraCompactInfoPanel(
            obra: obra,
            responsablesCount: data.responsables.length,
          ),
          //A partir d'aqui son les diferents seccions, cada una dins d'un ObraSectionBlock
          const SizedBox(height: 16),
          ObraSectionBlock(
            title: 'Ubicació',
            icon: Icons.map_outlined,
            count: obra.hasLocationData ? 1 : 0,
            initiallyExpanded: false,
            child: ObraLocationSectionBody(obra: obra),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Incidències',
            icon: Icons.warning_amber_rounded,
            count: data.incidencies.length,
            child: ObraSectionContent(
              items: data.incidencies,
              emptyText: 'No hi ha incidències registrades.',
              itemBuilder: (item) => ObraIncidenciaCard(incidencia: item),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Documents',
            icon: Icons.description_outlined,
            count: data.documents.length,
            child: ObraSectionContent(
              items: data.documents,
              emptyText: 'No hi ha documents disponibles.',
              itemBuilder: (item) => ObraDocumentCard(document: item),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Tasques',
            icon: Icons.task_alt,
            count: data.tasques.length,
            child: ObraSectionContent(
              items: data.tasques,
              emptyText: 'No hi ha tasques assignades.',
              itemBuilder: (item) => ObraTascaCard(tasca: item),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Recursos',
            icon: Icons.inventory_2_outlined,
            count: data.solRecursos.length,
            child: ObraSectionContent(
              items: data.solRecursos,
              emptyText: 'No hi ha sol·licituds de recursos.',
              itemBuilder: (item) => ObraSolRecursCard(item: item),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Responsables',
            icon: Icons.badge_outlined,
            count: data.responsables.length,
            child: ObraSectionContent(
              items: data.responsables,
              emptyText: 'No hi ha responsables assignats.',
              itemBuilder: (item) => ObraResponsableCard(responsable: item),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }
}
