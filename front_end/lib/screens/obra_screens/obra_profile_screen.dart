import 'package:flutter/material.dart';
import 'package:front_end/models/document_models.dart';
import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/responsable_models.dart';
import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/empresa/doc_form.dart';
import 'package:front_end/screens/empresa/inc_sol_form.dart';
import 'package:front_end/screens/recursos/solicRec_form.dart';
import 'package:front_end/screens/incidencia/incidenciaDetail_screen.dart';
import 'package:front_end/screens/obra_screens/obra_edit_screen.dart';
import 'package:front_end/screens/tasca_screens/tasca_detail_screen.dart';
import 'package:front_end/screens/tasca_screens/tasca_form.dart';
import 'package:front_end/services/obra_service.dart';
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
  late final ObraService _obraService;

  ObraProfileData? _profileData;
  Map<String, dynamic> _obraRaw = {};
  bool _loading = true;
  String? _errorMessage;

  int get _obraId {
    final rawId = _obraRaw['id_obra'] ?? widget.obraId;
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
    _obraService = ObraService(baseUrl: widget.baseUrl);
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
      final raw = await _obraService.fetchObraRaw(obraId);
      final parsed = ObraProfileData.fromMap(raw);

      if (!mounted) return;
      setState(() {
        _obraRaw = raw;
        _profileData = parsed;
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
          content: const Text(
            'Aquesta acció és irreversible. Vols continuar?',
          ),
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
    switch (value) {
      case 'inc':
        await _openAddIncidencia();
        break;
      case 'tasca':
        await _openAddTasca();
        break;
      case 'doc':
        await _openAddDocument();
        break;
      case 'rec':
        await _openAddRecurs();
        break;
    }

    await _fetchDetails();
  }

  Future<void> _openAddIncidencia() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IncidenciaFormScreen()),
    );
  }

  Future<void> _openAddTasca() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TascaFormScreen(obraId: widget.obraId)),
    );
  }

  Future<void> _openAddDocument() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentObraScreen(obraId: _obraId),
      ),
    );
  }

  Future<void> _openAddRecurs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolRecursFormScreen(obraId: _obraId),
      ),
    );
  }

  Future<void> _openAddResponsable() async {
    _showSnack(
      'Flux d’alta de responsables preparat per a la UI. Falta connectar la pantalla específica.',
    );
  }

  Future<void> _openEditIncidencia(Incidencia item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidenciaProfileScreen(
          incidenciaId: item.id,
        ),
      ),
    );
    await _fetchDetails();
  }

  Future<void> _openEditTasca(Tasca item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TascaDetailScreen(
          tascaId: item.id
        ),
      ),
    );
    await _fetchDetails();
  }

  Future<void> _openEditDocument(DocumentObraItem item) async {
    _showSnack(
      'Acció d’editar document preparada. Falta connectar la pantalla específica del document ${item.id}.',
    );
  }

  Future<void> _openEditRecurs(SolRecurs item) async {
    _showSnack(
      'Acció d’editar recurs preparada. Falta connectar la pantalla específica del recurs ${item.idRecurs}.',
    );
  }

  Future<void> _openEditResponsable(ResponsableObra item) async {
    _showSnack(
      'Acció d’editar responsable preparada. Falta connectar el flux específic del treballador ${item.idTreballador}.',
    );
  }

  Future<void> _confirmDeleteItem({
    required String subjectLabel,
    required String itemLabel,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Eliminar $subjectLabel'),
          content: Text(
            'Vols eliminar "$itemLabel"? Aquesta acció quedarà connectada quan el backend estigui disponible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel·la'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirma'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    _showSnack(
      'Delete de $subjectLabel preparat a la UI. El backend es connectarà més endavant.',
    );
  }

  Future<void> _deleteIncidencia(Incidencia item) {
    return _confirmDeleteItem(
      subjectLabel: 'incidència',
      itemLabel: item.descripcio,
    );
  }

  Future<void> _deleteTasca(Tasca item) {
    return _confirmDeleteItem(
      subjectLabel: 'tasca',
      itemLabel: item.descripcio,
    );
  }

  Future<void> _deleteDocument(DocumentObraItem item) {
    return _confirmDeleteItem(
      subjectLabel: 'document',
      itemLabel: item.nom,
    );
  }

  Future<void> _deleteRecurs(SolRecurs item) {
    return _confirmDeleteItem(
      subjectLabel: 'recurs',
      itemLabel: 'Recurs ${item.idRecurs}',
    );
  }

  Future<void> _deleteResponsable(ResponsableObra item) {
    return _confirmDeleteItem(
      subjectLabel: 'responsable',
      itemLabel: 'Treballador ${item.idTreballador}',
    );
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
                    obra: _obraRaw.isEmpty
                        ? <String, dynamic>{'id': widget.obraId}
                        : _obraRaw,
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
          ObraHeaderCard(obra: obra),
          const SizedBox(height: 12),
          ObraCompactInfoPanel(
            obra: obra,
            responsablesCount: data.responsables.length,
          ),
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
            onAdd: _openAddIncidencia,
            addTooltip: 'Afegir incidència',
            child: ObraSectionContent<Incidencia>(
              items: data.incidencies,
              emptyText: 'No hi ha incidències registrades.',
              itemBuilder: (item) => ObraIncidenciaCard(
                incidencia: item,
                onEdit: () => _openEditIncidencia(item),
                onDelete: () => _deleteIncidencia(item),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Documents',
            icon: Icons.description_outlined,
            count: data.documents.length,
            onAdd: _openAddDocument,
            addTooltip: 'Afegir document',
            child: ObraSectionContent<DocumentObraItem>(
              items: data.documents,
              emptyText: 'No hi ha documents disponibles.',
              itemBuilder: (item) => ObraDocumentCard(
                document: item,
                onEdit: () => _openEditDocument(item),
                onDelete: () => _deleteDocument(item),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Tasques',
            icon: Icons.task_alt,
            count: data.tasques.length,
            onAdd: _openAddTasca,
            addTooltip: 'Afegir tasca',
            child: ObraSectionContent<Tasca>(
              items: data.tasques,
              emptyText: 'No hi ha tasques assignades.',
              itemBuilder: (item) => ObraTascaCard(
                tasca: item,
                onEdit: () => _openEditTasca(item),
                onDelete: () => _deleteTasca(item),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Recursos',
            icon: Icons.inventory_2_outlined,
            count: data.solRecursos.length,
            onAdd: _openAddRecurs,
            addTooltip: 'Afegir recurs',
            child: ObraSectionContent<SolRecurs>(
              items: data.solRecursos,
              emptyText: 'No hi ha sol·licituds de recursos.',
              itemBuilder: (item) => ObraSolRecursCard(
                item: item,
                onEdit: () => _openEditRecurs(item),
                onDelete: () => _deleteRecurs(item),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ObraSectionBlock(
            title: 'Responsables',
            icon: Icons.badge_outlined,
            count: data.responsables.length,
            onAdd: _openAddResponsable,
            addTooltip: 'Afegir responsable',
            child: ObraSectionContent<ResponsableObra>(
              items: data.responsables,
              emptyText: 'No hi ha responsables assignats.',
              itemBuilder: (item) => ObraResponsableCard(
                responsable: item,
                onEdit: () => _openEditResponsable(item),
                onDelete: () => _deleteResponsable(item),
              ),
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