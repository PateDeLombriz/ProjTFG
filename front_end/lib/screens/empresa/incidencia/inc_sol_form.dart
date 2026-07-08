import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/widgets/incidencia_widgets.dart';

class IncidenciaFormScreen extends StatefulWidget {
  /// Id de l'obra a la qual pertany la incidència. Si és nul, es mostra un desplegable.
  final int? obraId;

  /// Dades inicials per editar una incidència existent. Si és null -> mode creació.
  ///
  /// Nota: amb el backend actual, la creació d'incidències i la gestió de
  /// solucions són funcionals. L'edició de les dades pròpies de la incidència
  /// queda preparada visualment, però no es persisteix fins que el backend
  /// afegeixi PUT/PATCH a /incidencia/{id}/.
  final IncidenciaDTO? initial;

  const IncidenciaFormScreen({
    super.key,
    this.obraId,
    this.initial,
  });

  @override
  State<IncidenciaFormScreen> createState() => _IncidenciaFormScreenState();
}

class _IncidenciaFormScreenState extends State<IncidenciaFormScreen> {
  late final IncidenciaService _service;

  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();

  bool _loadingOptions = true;
  bool _saving = false;
  bool _dirty = false;
  bool _incidenciaDirty = false;
  String? _loadError;

  DateTime? _dataInici;
  DateTime? _dataFi;
  int _criticitat = 2;
  int _prioritat = 2;
  String _estat = 'pendent';

  int? _obraSeleccionada;
  int? _tascaSeleccionadaId;
  List<ObraOption> _obres = const <ObraOption>[];
  List<TascaOption> _tasquesMateixaObra = const <TascaOption>[];

  final List<IncidenciaSolucioDraft> _solucions = <IncidenciaSolucioDraft>[];
  final Set<int> _deletedSolucioIds = <int>{};
  int _nextLocalSolucioId = -1;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _service = IncidenciaService();
    _initFromInitial();
    _loadOptions();
  }

  @override
  void dispose() {
    _service.dispose();
    _descCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  void _initFromInitial() {
    final initial = widget.initial;
    if (initial == null) {
      _obraSeleccionada = widget.obraId;
      _categoriaCtrl.text = '0';
      return;
    }

    _descCtrl.text = initial.descripcio;
    _dataInici = initial.dataInici;
    _dataFi = initial.dataFi;
    _criticitat = initial.criticitat;
    _prioritat = initial.prioritat;
    _categoriaCtrl.text = initial.categoria.toString();
    _estat = _normalizeEstat(initial.estat);
    _obraSeleccionada = widget.obraId ?? initial.idObra;
    _tascaSeleccionadaId = initial.idTasca;
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _loadError = null;
    });

    try {
      final obres = await _service.fetchObresOptions();
      var tasques = <TascaOption>[];
      final obraId = _obraSeleccionada;
      if (obraId != null) {
        tasques = await _service.fetchTasquesOptions(obraId: obraId);
      }

      final solucions = <IncidenciaSolucioDraft>[];
      if (_editing) {
        final raw = await _service.fetchSolucionsByIncidencia(widget.initial!.id);
        solucions.addAll(raw.map((item) => item.toDraft()));
      }

      if (!mounted) return;
      setState(() {
        _obres = obres;
        _tasquesMateixaObra = tasques;
        _solucions
          ..clear()
          ..addAll(solucions);
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _reloadTasquesForObra(int obraId) async {
    setState(() {
      _tasquesMateixaObra = const <TascaOption>[];
      _tascaSeleccionadaId = null;
    });

    try {
      final tasques = await _service.fetchTasquesOptions(obraId: obraId);
      if (!mounted) return;
      setState(() => _tasquesMateixaObra = tasques);
    } catch (e) {
      if (!mounted) return;
      _snack('No s’han pogut carregar les tasques: $e');
    }
  }

  void _markDirty({bool incidenciaData = false}) {
    if (!_dirty || (incidenciaData && !_incidenciaDirty)) {
      setState(() {
        _dirty = true;
        _incidenciaDirty = _incidenciaDirty || incidenciaData;
      });
    }
  }

  Map<String, dynamic> _incidenciaPayload() {
    return {
      'id_obra': _obraSeleccionada,
      'id_tasca': _tascaSeleccionadaId,
      'descripcio': _descCtrl.text.trim(),
      'data_inici': _formatDateForApi(_dataInici!),
      'data_fi': _dataFi == null ? null : _formatDateForApi(_dataFi!),
      'criticitat': _criticitat,
      'prioritat': _prioritat,
      'categoria': int.tryParse(_categoriaCtrl.text.trim()) ?? 0,
      'estat': _estat,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInici == null) {
      _snack('Falta la data d’inici.');
      return;
    }
    if (_obraSeleccionada == null) {
      _snack('Selecciona una obra.');
      return;
    }

    if (_editing && _incidenciaDirty) {
      final proceed = await _confirm(
        title: 'Backend pendent',
        message:
            'El backend actual encara no permet actualitzar les dades de la incidència. Es guardaran les solucions, però els canvis de dades generals quedaran pendents.',
        confirmLabel: 'Guardar solucions',
      );
      if (proceed != true) return;
    } else {
      final confirm = await _confirm(
        title: 'Desar incidència?',
        message: _editing
            ? 'Vols guardar els canvis de solucions?'
            : 'Vols crear la incidència i les solucions associades?',
        confirmLabel: 'Desar',
      );
      if (confirm != true) return;
    }

    setState(() => _saving = true);

    try {
      final incidenciaId = _editing
          ? widget.initial!.id
          : _asInt((await _service.createIncidencia(_incidenciaPayload()))['id']);

      if (incidenciaId == null || incidenciaId == 0) {
        throw Exception('El servidor no ha retornat l’id de la incidència.');
      }

      await _syncSolucions(incidenciaId);

      if (!mounted) return;
      final hadPendingIncidenciaChanges = _editing && _incidenciaDirty;
      _dirty = false;
      _incidenciaDirty = false;
      _snack(
        hadPendingIncidenciaChanges
            ? 'Solucions guardades. Les dades de la incidència queden pendents.'
            : 'Incidència desada correctament.',
        success: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncSolucions(int incidenciaId) async {
    for (final id in _deletedSolucioIds) {
      await _service.deleteSolucio(id);
    }

    for (final solucio in _solucions) {
      final payload = solucio.toPayload(incidenciaId: incidenciaId);
      if (solucio.isPersisted) {
        await _service.updateSolucio(solucio.id!, payload);
      } else {
        await _service.createSolucio(payload);
      }
    }
  }

  Future<void> _handleAddSolucio() async {
    final result = await showModalBottomSheet<IncidenciaSolucioFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidenciaSolucioEditorSheet(
        tasques: _tasquesMateixaObra,
      ),
    );

    if (result == null) return;

    setState(() {
      _solucions.add(_draftFromResult(result, id: _nextLocalSolucioId--));
      _dirty = true;
    });
  }

  Future<void> _handleEditSolucio(IncidenciaSolucioItem item) async {
    final index = _solucions.indexWhere((draft) => draft.id == item.id);
    if (index == -1) return;

    final result = await showModalBottomSheet<IncidenciaSolucioFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidenciaSolucioEditorSheet(
        initial: item,
        tasques: _tasquesMateixaObra,
      ),
    );

    if (result == null) return;

    setState(() {
      _solucions[index] = _draftFromResult(result, id: item.id);
      _dirty = true;
    });
  }

  Future<void> _handleDeleteSolucio(IncidenciaSolucioItem item) async {
    final confirmed = await _confirm(
      title: 'Eliminar solució?',
      message: 'Aquesta solució deixarà de formar part de la incidència.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (confirmed != true) return;

    setState(() {
      _solucions.removeWhere((draft) => draft.id == item.id);
      if (item.id > 0) _deletedSolucioIds.add(item.id);
      _dirty = true;
    });
  }

  IncidenciaSolucioDraft _draftFromResult(
    IncidenciaSolucioFormResult result, {
    required int id,
  }) {
    return IncidenciaSolucioDraft(
      id: id,
      idTasca: result.idTasca,
      descripcio: result.descripcio,
      costMonetari: result.costMonetari,
      eficacia: result.eficacia,
      costTemporal: result.costTemporal,
      impacte: result.impacte,
    );
  }

  List<IncidenciaSolucioItem> _solucioItems() {
    return [
      for (var i = 0; i < _solucions.length; i++)
        _solucions[i].toItem(temporaryId: -1000 - i),
    ];
  }

  Future<bool> _onWillPop() async {
    if (!_dirty || _saving) return true;

    final leave = await _confirm(
      title: 'Canvis sense desar',
      message: 'Vols sortir sense desar els canvis?',
      confirmLabel: 'Sortir',
      destructive: true,
    );

    return leave ?? false;
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

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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

  String? get _selectedObraLabel {
    final id = _obraSeleccionada;
    if (id == null) return null;
    for (final obra in _obres) {
      if (obra.id == id) return obra.nom;
    }
    return 'Obra #$id';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: scheme.primaryContainer.withOpacity(0.06),
        appBar: AppBar(
          title: Text(_editing ? 'Editar incidència' : 'Nova incidència'),
          actions: [
            IconButton(
              tooltip: 'Recarrega opcions',
              onPressed: _saving ? null : _loadOptions,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadOptions,
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    IncidenciaFormHeaderCard(
                      editing: _editing,
                      estat: _estat,
                      criticitat: _criticitat,
                      prioritat: _prioritat,
                      obraLabel: _selectedObraLabel,
                    ),
                    const SizedBox(height: 14),
                    if (_loadError != null) ...[
                      _ErrorPanel(
                        message: _loadError!,
                        onRetry: _loadOptions,
                      ),
                      const SizedBox(height: 14),
                    ],
                    IncidenciaSectionBlock(
                      title: 'Dades generals',
                      icon: Icons.description_outlined,
                      initiallyExpanded: true,
                      child: _buildGeneralSection(),
                    ),
                    const SizedBox(height: 14),
                    IncidenciaSectionBlock(
                      title: 'Planificació',
                      icon: Icons.event_outlined,
                      initiallyExpanded: true,
                      child: _buildPlanningSection(),
                    ),
                    const SizedBox(height: 14),
                    IncidenciaSectionBlock(
                      title: 'Severitat i estat',
                      icon: Icons.tune_rounded,
                      initiallyExpanded: true,
                      child: _buildSeveritySection(),
                    ),
                    const SizedBox(height: 14),
                    IncidenciaSectionBlock(
                      title: 'Solucions',
                      icon: Icons.build_circle_outlined,
                      count: _solucions.length,
                      initiallyExpanded: true,
                      onAdd: _handleAddSolucio,
                      addTooltip: 'Afegir solució',
                      child: IncidenciaSolucionsSectionBody(
                        solucions: _solucioItems(),
                        onAdd: _handleAddSolucio,
                        onEdit: _handleEditSolucio,
                        onDelete: _handleDeleteSolucio,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loadingOptions)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _LoadingOverlay(label: 'Carregant dades...'),
                ),
              ),
            if (_saving)
              const Positioned.fill(
                child: _LoadingOverlay(label: 'Desant...'),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving || _loadingOptions ? null : _submit,
          icon: const Icon(Icons.save_rounded),
          label: Text(_editing ? 'Desar solucions' : 'Crear incidència'),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      children: [
        _TextInput(
          controller: _descCtrl,
          label: 'Descripció *',
          icon: Icons.description_outlined,
          maxLines: 4,
          onChanged: (_) => _markDirty(incidenciaData: true),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'La descripció és obligatòria.'
              : null,
        ),
        const SizedBox(height: 12),
        if (widget.obraId == null)
          DropdownButtonFormField<int>(
            value: _obraSeleccionada,
            isExpanded: true,
            decoration: _inputDecoration(
              context,
              'Obra *',
              Icons.apartment_outlined,
            ),
            items: _obres
                .map(
                  (obra) => DropdownMenuItem<int>(
                    value: obra.id,
                    child: Text(obra.nom, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              _markDirty(incidenciaData: true);
              setState(() => _obraSeleccionada = value);
              if (value != null) _reloadTasquesForObra(value);
            },
            validator: (value) => value == null ? 'Selecciona una obra.' : null,
          )
        else
          _ReadOnlyInfoTile(
            icon: Icons.apartment_outlined,
            label: 'Obra',
            value: _selectedObraLabel ?? 'Obra #${widget.obraId}',
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: _tascaSeleccionadaId,
          isExpanded: true,
          decoration: _inputDecoration(
            context,
            'Tasca associada',
            Icons.link_outlined,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('— Sense tasca —'),
            ),
            ..._tasquesMateixaObra.map(
              (tasca) => DropdownMenuItem<int?>(
                value: tasca.id,
                child: Text(
                  tasca.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            _markDirty(incidenciaData: true);
            setState(() => _tascaSeleccionadaId = value);
          },
        ),
        const SizedBox(height: 12),
        _TextInput(
          controller: _categoriaCtrl,
          label: 'Categoria',
          icon: Icons.category_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => _markDirty(incidenciaData: true),
        ),
      ],
    );
  }

  Widget _buildPlanningSection() {
    return Column(
      children: [
        _DatePickerTile(
          label: 'Data inici *',
          value: _dataInici,
          onTap: () async {
            final picked = await _pickDate(_dataInici);
            if (picked == null) return;
            _markDirty(incidenciaData: true);
            setState(() => _dataInici = picked);
          },
        ),
        const SizedBox(height: 10),
        _DatePickerTile(
          label: 'Data fi',
          value: _dataFi,
          onTap: () async {
            final picked = await _pickDate(_dataFi);
            if (picked == null) return;
            _markDirty(incidenciaData: true);
            setState(() => _dataFi = picked);
          },
        ),
      ],
    );
  }

  Widget _buildSeveritySection() {
    return Column(
      children: [
        _MetricSlider(
          label: 'Criticitat',
          value: _criticitat,
          icon: Icons.crisis_alert_outlined,
          onChanged: (value) {
            _markDirty(incidenciaData: true);
            setState(() => _criticitat = value);
          },
        ),
        const SizedBox(height: 12),
        _MetricSlider(
          label: 'Prioritat',
          value: _prioritat,
          icon: Icons.priority_high_rounded,
          onChanged: (value) {
            _markDirty(incidenciaData: true);
            setState(() => _prioritat = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _estat,
          isExpanded: true,
          decoration: _inputDecoration(context, 'Estat *', Icons.flag_outlined),
          items: const [
            DropdownMenuItem(value: 'pendent', child: Text('Pendent')),
            DropdownMenuItem(value: 'en_curs', child: Text('En curs')),
            DropdownMenuItem(value: 'resolta', child: Text('Resolta')),
            DropdownMenuItem(value: 'tancada', child: Text('Tancada')),
          ],
          onChanged: (value) {
            if (value == null) return;
            _markDirty(incidenciaData: true);
            setState(() => _estat = value);
          },
        ),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: _inputDecoration(context, label, icon),
    );
  }
}

class _ReadOnlyInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null ? 'Selecciona una data' : _formatDate(value!),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MetricSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  const _MetricSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = value >= 4
        ? scheme.error
        : value >= 3
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (newValue) => onChanged(newValue.toInt()),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.50),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final String label;

  const _LoadingOverlay({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.18),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context,
  String label,
  IconData icon,
) {
  final scheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: scheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outline.withOpacity(0.16)),
    ),
  );
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

String _formatDateForApi(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _normalizeEstat(String value) {
  final text = value.trim().toLowerCase();
  switch (text) {
    case 'oberta':
    case 'obert':
    case 'pendent':
      return 'pendent';
    case 'en procés':
    case 'en proces':
    case 'en_curs':
    case 'en curs':
      return 'en_curs';
    case 'resolta':
      return 'resolta';
    case 'tancada':
      return 'tancada';
    default:
      return text.isEmpty ? 'pendent' : value;
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
