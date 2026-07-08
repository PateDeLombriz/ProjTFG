import 'package:flutter/material.dart';

import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/services/sol_recurs_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/widgets/sol_recurs_widgets.dart';

class SolRecursFormScreen extends StatefulWidget {
  final int? obraId;
  final SolRecursDTO? initial;
  final bool batchMode;

  const SolRecursFormScreen({
    super.key,
    this.obraId,
    this.initial,
    this.batchMode = false,
  });

  @override
  State<SolRecursFormScreen> createState() => _SolRecursFormScreenState();
}

class _SolRecursFormScreenState extends State<SolRecursFormScreen> {
  late final SolRecursService _service;
  late final ObraService _obraService;
  final _formKey = GlobalKey<FormState>();
  bool _loadingOptions = true;
  bool _saving = false;
  bool _dirty = false;

  int? _obraSeleccionada;
  List<ObraOption> _obres = const [];
  List<RecursOption> _recursos = const [];

  RecursOption? _recursSel;
  final _quantCtrl = TextEditingController();
  DateTime? _dataNecessitat;
  DateTime? _dataEntrega;
  final _comentCtrl = TextEditingController();
  final _provCtrl = TextEditingController();

  final List<SolRecursDraft> _batch = [];

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _service = SolRecursService(baseUrl: ApiConstants.baseUrl);
    _obraService = ObraService(baseUrl: ApiConstants.baseUrl);
    _initFromInitial();
    _loadOptions();
  }

  @override
  void dispose() {
    _quantCtrl.dispose();
    _comentCtrl.dispose();
    _provCtrl.dispose();
    _service.dispose();
    _obraService.dispose();
    super.dispose();
  }

  void _initFromInitial() {
    _obraSeleccionada = widget.obraId ?? widget.initial?.idObra;
    final initial = widget.initial;
    if (initial == null) return;

    _recursSel = RecursOption(
      id: initial.idRecurs,
      nom: initial.recursNom ?? 'Recurs #${initial.idRecurs}',
      unitat: initial.unitat ?? '',
    );
    _quantCtrl.text = initial.quantitat.toString();
    _dataNecessitat = initial.dataNecessitat;
    _dataEntrega = initial.dataEntrega;
    _comentCtrl.text = initial.comentari ?? '';
    _provCtrl.text = initial.proveidor ?? '';
  }

  Future<void> _loadOptions() async {
    if (!mounted) return;

    setState(() => _loadingOptions = true);

    try {
      final obresFuture = _obraService.fetchMyEmpresaObres();
      final recursosFuture = _service.fetchRecursOptions();

      final obres = await obresFuture;
      final recursos = await recursosFuture;

      if (!mounted) return;

      setState(() {
        _obres = obres.map(ObraOption.fromMap).toList();
        _recursos = recursos;
        _recursSel = _resolveInitialRecurs(_recursSel, recursos);
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loadingOptions = false);
      _snack('Error carregant opcions: $error');
    }
  }

  RecursOption? _resolveInitialRecurs(
    RecursOption? current,
    List<RecursOption> recursos,
  ) {
    if (current == null) return null;
    for (final recurs in recursos) {
      if (recurs.id == current.id) return recurs;
    }
    return current;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (widget.batchMode) {
      if (_obraSeleccionada == null) {
        _snack('Selecciona una obra.');
        return;
      }
      if (_batch.isEmpty) {
        _snack('Afegeix almenys una línia.');
        return;
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
      if (_obraSeleccionada == null) {
        _snack('Selecciona una obra.');
        return;
      }
      if (_recursSel == null) {
        _snack('Selecciona un recurs.');
        return;
      }
      if (_dataNecessitat == null) {
        _snack('Selecciona la data de necessitat.');
        return;
      }
    }

    final confirm = await _confirmDesar();
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      if (widget.batchMode) {
        for (final draft in _batch) {
          await _service.createSolRecursDraft(
            obraId: _obraSeleccionada!,
            draft: draft,
          );
        }
      } else {
        final draft = SolRecursDraft(
          recurs: _recursSel!,
          quantitat: int.parse(_quantCtrl.text.trim()),
          dataNecessitat: _dataNecessitat!,
          dataEntrega: _dataEntrega,
          comentari:
              _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
          proveidor:
              _provCtrl.text.trim().isEmpty ? null : _provCtrl.text.trim(),
          // Si l'edites i venia d'un treballador, es conserva.
          // Si la crea una empresa, queda null.
          idTreballador: widget.initial?.idTreballador,
          // El formulari no canvia aprovació; conserva o crea pendent.
          estat: widget.initial?.estat ?? 'pendent',
        );

        if (widget.initial == null) {
          await _service.createSolRecursDraft(
            obraId: _obraSeleccionada!,
            draft: draft,
          );
        } else {
          await _service.updateSolRecursDraft(
            widget.initial!.id,
            obraId: _obraSeleccionada!,
            draft: draft,
          );
        }
      }

      if (!mounted) return;
      _dirty = false;
      _snack('Sol·licitud desada correctament.', success: true);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _snack('Error desant la sol·licitud: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmDesar() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Desar sol·licitud'),
          content: Text(
            widget.batchMode
                ? 'Vols desar totes les línies del lot?'
                : _editing
                    ? 'Vols guardar els canvis de la sol·licitud?'
                    : 'Vols crear aquesta sol·licitud de recurs?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·la'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desa'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (!_dirty || _saving) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Canvis sense desar'),
          content: const Text('Vols sortir sense desar els canvis?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·la'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sortir'),
            ),
          ],
        );
      },
    );

    return leave ?? false;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickNeedDate() async {
    final picked = await _pickDate(_dataNecessitat);
    if (picked == null) return;
    _markDirty();
    setState(() => _dataNecessitat = picked);
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await _pickDate(_dataEntrega);
    if (picked == null) return;
    _markDirty();
    setState(() => _dataEntrega = picked);
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _addLine() async {
    final draft = await showModalBottomSheet<SolRecursDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SolRecursDraftEditorSheet(recursos: _recursos),
    );

    if (draft == null) return;
    _markDirty();
    setState(() => _batch.add(draft));
  }

  Future<void> _editLine(int index) async {
    final draft = await showModalBottomSheet<SolRecursDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SolRecursDraftEditorSheet(
        recursos: _recursos,
        initial: _batch[index],
      ),
    );

    if (draft == null) return;
    _markDirty();
    setState(() => _batch[index] = draft);
  }

  void _removeLine(int index) {
    _markDirty();
    setState(() => _batch.removeAt(index));
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: scheme.primaryContainer.withOpacity(0.06),
        appBar: AppBar(
          title: Text(
            widget.batchMode
                ? 'Sol·licituds de recursos'
                : _editing
                    ? 'Editar sol·licitud'
                    : 'Nova sol·licitud',
          ),
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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  SolRecursFormHeaderCard(
                    batchMode: widget.batchMode,
                    editing: _editing,
                    lineCount: widget.batchMode ? _batch.length : null,
                  ),
                  const SizedBox(height: 14),
                  if (_loadingOptions)
                    const SolRecursLoadingCard()
                  else if (widget.batchMode)
                    _buildBatchBody()
                  else
                    _buildSingleBody(),
                ],
              ),
            ),
            if (_saving)
              Container(
                color: Colors.black.withOpacity(0.26),
                child: const AppLoadingIndicator(),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving || _loadingOptions ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Desant...' : 'Desa'),
        ),
      ),
    );
  }

  Widget _buildSingleBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SolRecursFormSectionCard(
            title: 'Obra i recurs',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: [
                if (widget.obraId == null)
                  DropdownButtonFormField<int>(
                    value: _obraSeleccionada,
                    decoration:
                        _inputDecoration('Obra *', Icons.apartment_rounded),
                    items: _obres
                        .map(
                          (obra) => DropdownMenuItem<int>(
                            value: obra.id,
                            child: Text(obra.nom),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _markDirty();
                      setState(() => _obraSeleccionada = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una obra' : null,
                  )
                else
                  _ReadOnlyInfoTile(
                    icon: Icons.apartment_rounded,
                    label: 'Obra',
                    value: _obraLabel(_obraSeleccionada),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RecursOption>(
                  value: _recursSel,
                  decoration:
                      _inputDecoration('Recurs *', Icons.inventory_2_outlined),
                  items: _recursos
                      .map(
                        (recurs) => DropdownMenuItem<RecursOption>(
                          value: recurs,
                          child: Text(
                              '${recurs.nom}${recurs.unitat.isEmpty ? '' : ' (${recurs.unitat})'}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _markDirty();
                    setState(() => _recursSel = value);
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona un recurs' : null,
                ),
                if (_recursSel?.stock != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Stock disponible: ${_recursSel!.stock} ${_recursSel!.unitat}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SolRecursFormSectionCard(
            title: 'Quantitat i dates',
            icon: Icons.event_note_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _quantCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      _inputDecoration('Quantitat *', Icons.numbers_rounded),
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');
                    if (number == null || number <= 0)
                      return 'Entra un enter > 0';
                    return null;
                  },
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 12),
                SolRecursFormDateTile(
                  label: 'Data necessitat',
                  date: _dataNecessitat,
                  requiredField: true,
                  onTap: _pickNeedDate,
                ),
                const SizedBox(height: 12),
                SolRecursFormDateTile(
                  label: 'Data entrega',
                  date: _dataEntrega,
                  onTap: _pickDeliveryDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SolRecursFormSectionCard(
            title: 'Informació addicional',
            icon: Icons.notes_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _provCtrl,
                  decoration:
                      _inputDecoration('Proveïdor', Icons.storefront_outlined),
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comentCtrl,
                  decoration:
                      _inputDecoration('Comentari', Icons.notes_rounded),
                  maxLines: 3,
                  onChanged: (_) => _markDirty(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchBody() {
    return Column(
      children: [
        SolRecursFormSectionCard(
          title: 'Obra',
          icon: Icons.apartment_rounded,
          child: widget.obraId == null
              ? DropdownButtonFormField<int>(
                  value: _obraSeleccionada,
                  decoration:
                      _inputDecoration('Obra *', Icons.apartment_rounded),
                  items: _obres
                      .map(
                        (obra) => DropdownMenuItem<int>(
                          value: obra.id,
                          child: Text(obra.nom),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _markDirty();
                    setState(() => _obraSeleccionada = value);
                  },
                )
              : _ReadOnlyInfoTile(
                  icon: Icons.apartment_rounded,
                  label: 'Obra',
                  value: _obraLabel(_obraSeleccionada),
                ),
        ),
        const SizedBox(height: 14),
        SolRecursFormSectionCard(
          title: 'Línies de sol·licitud',
          icon: Icons.format_list_bulleted_rounded,
          count: _batch.length,
          onAdd: _addLine,
          addTooltip: 'Afegir línia',
          child: _batch.isEmpty
              ? const AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No hi ha línies',
                  message: 'Fes servir el botó + per afegir una línia al lot.',
                )
              : Column(
                  children: List.generate(_batch.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _batch.length - 1 ? 0 : 10,
                      ),
                      child: SolRecursDraftCard(
                        draft: _batch[index],
                        onTap: () => _editLine(index),
                        onDelete: () => _removeLine(index),
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.10)),
      ),
    );
  }

  String _obraLabel(int? id) {
    if (id == null) return 'Sense obra';
    for (final obra in _obres) {
      if (obra.id == id) return obra.nom;
    }
    return 'Obra #$id';
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
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
