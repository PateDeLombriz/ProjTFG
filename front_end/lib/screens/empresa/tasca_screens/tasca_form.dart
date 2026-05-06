import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/services/tasques_service.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

class TascaFormScreen extends StatefulWidget {
  final int? obraId;
  final TascaDTO?
      initial; //Dades utilitzades per el formulari de la tasca, pot venir de la tasca mateixa o d'una tasca pare (en cas de crear una subtasca)
  final int? empresaId;
  const TascaFormScreen({
    super.key,
    this.empresaId,
    this.obraId,
    this.initial,
  });

  @override
  State<TascaFormScreen> createState() => _TascaFormScreenState();
}

class _TascaFormScreenState extends State<TascaFormScreen> {
  late final TascaService _service;
  late final TreballadorService _serviceT;

  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  DateTime? _dataInici;
  DateTime? _dataFi;
  int _prioritat = 3;
  bool _visibilitat = true;

  int? _obraSeleccionada;
  TascaOption? _tascaPare;

  List<ObraOption> _obres = [];
  List<TascaOption> _tasquesMateixaObra = [];
  List<UsuariOption> _treballadors = [];
  final List<UsuariOption> _seleccionats = [];

  @override
  void initState() {
    super.initState();
    _service = TascaService(baseUrl: ApiConstants.baseUrl);
    _serviceT=TreballadorService(baseUrl: ApiConstants.baseUrl);
    _initFromInitial();
    _loadOptions();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _initFromInitial() {
    final initial = widget.initial;

    if (initial == null) {
      _obraSeleccionada = widget.obraId;
      return;
    }

    _descCtrl.text = initial.descripcio;
    _dataInici = initial.dataInici;
    _dataFi = initial.dataFi;
    _prioritat = initial.prioritat;
    _visibilitat = initial.visibilitat;
    _obraSeleccionada = widget.obraId ?? initial.idObra;
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);

    try {
      final obresFuture = _service.fetchObres();
      final treballadorsFuture = _service.fetchTreballadors();

      final results = await Future.wait([
        obresFuture,
        treballadorsFuture,
      ]);

      _obres = results[0] as List<ObraOption>;
      _treballadors = results[1] as List<UsuariOption>;

      if (_obraSeleccionada != null) {
        _tasquesMateixaObra =
            await _service.fetchTasquesPerObra(_obraSeleccionada!);
      }

      final initial = widget.initial;
      if (initial != null) {
        if (initial.idTascaPare != null) {
          _tascaPare = _tasquesMateixaObra.firstWhere(
            (opt) => opt.id == initial.idTascaPare,
            orElse: () => TascaOption(
              id: initial.idTascaPare!,
              desc: 'Tasca pare no trobada',
            ),
          );
        }

        final assignats = await _service.fetchTreballadorsDeTasca(initial.id);
        _seleccionats
          ..clear()
          ..addAll(assignats);
      }
    } catch (e) {
      if (mounted) {
        _snack('Error carregant opcions: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reloadTasquesPerObra(int obraId) async {
    try {
      final tasques = await _service.fetchTasquesPerObra(obraId);

      if (!mounted) return;

      setState(() {
        _tasquesMateixaObra = tasques;
        _tascaPare = null;
      });
    } catch (e) {
      if (mounted) {
        _snack('Error carregant tasques de l’obra: $e');
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'id_obra': _obraSeleccionada,
      'id_tasca_pare': _tascaPare?.id,
      'descripcio': _descCtrl.text.trim(),
      'data_inici': _fmtDate(_dataInici!),
      'data_fi': _dataFi != null ? _fmtDate(_dataFi!) : null,
      'prioritat': _prioritat,
      'visibilitat_tasca': _visibilitat,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataInici == null) {
      _snack('⚠️ Falta la data d’inici');
      return;
    }

    if (_obraSeleccionada == null) {
      _snack('⚠️ Selecciona una obra');
      return;
    }

    final confirm = await _confirmDesar();
    if (confirm != true) return;

    setState(() => _saving = true);

    try {
      final payload = _buildPayload();

      late final int tascaId;

      final isCreating = widget.initial == null;

      if (isCreating) {
        tascaId = await _service.createTascaAndReturnId(payload);

        if (tascaId == 0) {
          throw const TascaServiceException(
            'La tasca s’ha creat però el backend no ha retornat un id vàlid.',
          );
        }

        await _service.createAssignacionsTasca(tascaId, _seleccionats);
      } else {
        tascaId = widget.initial!.id;

        await _service.updateTasca(tascaId, payload);
        await _service.syncTreballadors(tascaId, _seleccionats);
      }

      if (!mounted) return;

      _dirty = false;
      _snack('✅ Tasca desada correctament!', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _snack('❌ Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openSelectTreballadors() async {
    final result = await showDialog<List<UsuariOption>>(
      context: context,
      builder: (_) => SelectTreballadorsDialog(
        tots: _treballadors,
        seleccionats: _seleccionats,
      ),
    );

    if (result == null) return;

    _markDirty();

    setState(() {
      _seleccionats
        ..clear()
        ..addAll(result);
    });
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<bool?> _confirmDesar() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmació'),
        content: const Text('Vols desar la tasca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·la'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desa'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_dirty || _saving) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hi ha canvis sense desar'),
        content: const Text('Vols sortir sense desar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·la'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sortir'),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  String _fmtDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _obraLabel() {
    final id = _obraSeleccionada;
    if (id == null) return 'Obra no seleccionada';

    return _obres
        .firstWhere(
          (obra) => obra.id == id,
          orElse: () => ObraOption(id: id, nom: 'Obra #$id'),
        )
        .nom;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? 'Nova Tasca' : 'Editar Tasca'),
        ),
        body: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Dades generals'),
                      _textField(
                        controller: _descCtrl,
                        label: 'Descripció *',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Obligatori';
                          }
                          return null;
                        },
                      ),
                      _gap(),
                      if (widget.obraId == null)
                        DropdownButtonFormField<int>(
                          value: _obraSeleccionada,
                          decoration: _inputDecoration(
                            'Obra *',
                            icon: Icons.business_outlined,
                          ),
                          items: _obres
                              .map(
                                (obra) => DropdownMenuItem<int>(
                                  value: obra.id,
                                  child: Text(obra.nom),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            _markDirty();

                            setState(() {
                              _obraSeleccionada = value;
                              _tascaPare = null;
                              _tasquesMateixaObra = [];
                            });

                            if (value != null) {
                              await _reloadTasquesPerObra(value);
                            }
                          },
                          validator: (value) {
                            return value == null ? 'Selecciona una obra' : null;
                          },
                        )
                      else
                        _readOnlyTile('Obra', _obraLabel()),
                      _gap(),
                      DropdownButtonFormField<TascaOption>(
                        value: _tascaPare,
                        decoration: _inputDecoration(
                          'Tasca pare',
                          icon: Icons.account_tree_outlined,
                        ),
                        items: [
                          const DropdownMenuItem<TascaOption>(
                            value: null,
                            child: Text('— Sense tasca pare —'),
                          ),
                          ..._tasquesMateixaObra
                              .where(
                                (tasca) =>
                                    widget.initial == null ||
                                    tasca.id != widget.initial!.id,
                              )
                              .map(
                                (tasca) => DropdownMenuItem<TascaOption>(
                                  value: tasca,
                                  child: Text(
                                    tasca.desc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          _markDirty();
                          setState(() => _tascaPare = value);
                        },
                      ),
                      const Divider(height: 32),
                      _sectionTitle('Planificació'),
                      _dateTile(
                        title: 'Data inici *',
                        date: _dataInici,
                        onTap: () async {
                          final date = await _pickDate(_dataInici);
                          if (date == null) return;

                          _markDirty();
                          setState(() => _dataInici = date);
                        },
                      ),
                      _dateTile(
                        title: 'Data fi',
                        date: _dataFi,
                        onTap: () async {
                          final date = await _pickDate(_dataFi);
                          if (date == null) return;

                          _markDirty();
                          setState(() => _dataFi = date);
                        },
                      ),
                      _gap(),
                      Row(
                        children: [
                          const Text('Prioritat'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _prioritat.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: '$_prioritat',
                              onChanged: (value) {
                                _markDirty();
                                setState(() {
                                  _prioritat = value.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visible als usuaris'),
                        value: _visibilitat,
                        onChanged: (value) {
                          _markDirty();
                          setState(() => _visibilitat = value);
                        },
                      ),
                      const Divider(height: 32),
                      _sectionTitle('Assignació de treballadors'),
                      if (_seleccionats.isEmpty)
                        Text(
                          'No hi ha treballadors assignats',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _seleccionats
                              .map(
                                (usuari) => Chip(
                                  label: Text(usuari.nomComplet),
                                  onDeleted: () {
                                    _markDirty();
                                    setState(() {
                                      _seleccionats.removeWhere(
                                        (item) => item.id == usuari.id,
                                      );
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _openSelectTreballadors,
                          icon: const Icon(Icons.group_add_outlined),
                          label: const Text('Afegir / Editar'),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 90,
                      ),
                    ],
                  ),
                ),
              ),
            if (_saving)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving || _loading ? null : _submit,
          icon: const Icon(Icons.save),
          label: const Text('Desa'),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _gap([double height = 12]) => SizedBox(height: height);

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label, icon: icon),
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        date == null ? 'Selecciona una data' : _fmtDate(date),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  Widget _readOnlyTile(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
