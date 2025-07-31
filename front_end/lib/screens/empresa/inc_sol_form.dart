//FET

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Pantalla de **Gestió d'Incidències** (creació / edició) amb secció integrada
/// per a **Solucions**. Manté el mateix nivell de detall que les pantalles
/// d'Obra i Tasca creades anteriorment:
///
/// - Dades generals de la incidència (descripció, dates, criticitat, prioritat, categoria, estat)
/// - Enllaç amb Obra (obligatori) i Tasca (opcional)
/// - Llista de solucions (crear/editar/eliminar amb diàlegs)
/// - Confirmacions, SnackBars, validacions i protecció de canvis (_dirty)
/// - Carrega asíncrona d'opcions (obres, tasques)
/// - Botó flotant per desar, overlay de càrrega
/// - Compatible amb tema clar/fosc
///
/// **Endpoints** a ajustar segons el teu backend:
/// - /incidencies/
/// - /solucions/
/// - /tasques/?id_obra=ID
/// - /obres/
class IncidenciaFormScreen extends StatefulWidget {
  /// id de l'obra a la qual pertany la incidència. Si és nul, es mostra un dropdown.
  final int? obraId;

  /// Dades inicials per editar una incidència existent. Si és null -> mode creació.
  final IncidenciaDTO? initial;

  const IncidenciaFormScreen({super.key, this.obraId, this.initial});

  @override
  State<IncidenciaFormScreen> createState() => _IncidenciaFormScreenState();
}

class _IncidenciaFormScreenState extends State<IncidenciaFormScreen> {
  //==================== CONFIG ====================
  static const String baseUrl = 'http://localhost:8000/api';

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _dirty = false;

  //==================== CONTROLS INCIDÈNCIA ====================
  final _descCtrl = TextEditingController();
  DateTime? _dataInici;
  DateTime? _dataFi;
  int _criticitat = 2; // 1-5
  int _prioritat = 2;  // 1-5
  String _categoria = '0'; // si és int, converteix després
  String _estat = 'Oberta';

  //==================== OBRA / TASCA ====================
  int? _obraSeleccionada;
  TascaOption? _tascaSeleccionada;
  List<ObraOption> _obres = [];
  List<TascaOption> _tasquesMateixaObra = [];

  //==================== SOLUCIONS ====================
  final List<SolucioDraft> _solucions = [];

  @override
  void initState() {
    super.initState();
    _initFromInitial();
    _loadOptions();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _initFromInitial() {
    if (widget.initial != null) {
      final inc = widget.initial!;
      _descCtrl.text = inc.descripcio;
      _dataInici = inc.dataInici;
      _dataFi = inc.dataFi;
      _criticitat = inc.criticitat;
      _prioritat = inc.prioritat;
      _categoria = inc.categoria.toString();
      _estat = inc.estat;
      _obraSeleccionada = widget.obraId ?? inc.idObra;
      // Tasca i solucions es carregaran després de tenir les opcions
    } else {
      _obraSeleccionada = widget.obraId;
    }
  }

  Future<void> _loadOptions() async {
    try {
      if (_obraSeleccionada == null) {
        _obres = await _fetchObres();
      }
      if (_obraSeleccionada != null) {
        _tasquesMateixaObra = await _fetchTasquesPerObra(_obraSeleccionada!);
      }

      // Edit mode: carregar tasca seleccionada i solucions
      if (widget.initial != null) {
        final inc = widget.initial!;
        if (inc.idTasca != null) {
          _tascaSeleccionada = _tasquesMateixaObra.firstWhere(
            (t) => t.id == inc.idTasca,
            orElse: () => TascaOption(id: inc.idTasca!, desc: 'Tasca (no trobada)'));
        }
        final sols = await _fetchSolucions(inc.id);
        _solucions.addAll(sols.map((s) => s.toDraft()));
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _snack('Error carregant opcions: $e');
    }
  }

  //==================== API ====================
  Future<List<ObraOption>> _fetchObres() async {
    final res = await http.get(Uri.parse('$baseUrl/obres/'));
    if (res.statusCode == 200) {
      final l = jsonDecode(res.body) as List<dynamic>;
      return l.map((e) => ObraOption(id: e['id'], nom: e['nom'] ?? '—')).toList();
    }
    throw Exception('No s\'han pogut carregar les obres');
  }

  Future<List<TascaOption>> _fetchTasquesPerObra(int idObra) async {
    final res = await http.get(Uri.parse('$baseUrl/tasques/?id_obra=$idObra'));
    if (res.statusCode == 200) {
      final l = jsonDecode(res.body) as List<dynamic>;
      return l.map((e) => TascaOption(id: e['id'], desc: e['descripcio'] ?? '')).toList();
    }
    throw Exception('No s\'han pogut carregar les tasques');
  }

  Future<List<SolucioDTO>> _fetchSolucions(int idIncidencia) async {
    final res = await http.get(Uri.parse('$baseUrl/solucions/?id_incidencia=$idIncidencia'));
    if (res.statusCode == 200) {
      final l = jsonDecode(res.body) as List<dynamic>;
      return l.map((e) => SolucioDTO.fromJson(e)).toList();
    }
    return [];
  }

  Future<int> _createIncidencia() async {
    final payload = {
      'id_obra': _obraSeleccionada,
      'id_tasca': _tascaSeleccionada?.id,
      'descripcio': _descCtrl.text.trim(),
      'data_inici': _fmtDate(_dataInici!),
      'data_fi': _dataFi != null ? _fmtDate(_dataFi!) : null,
      'criticitat': _criticitat,
      'prioritat': _prioritat,
      'categoria': int.tryParse(_categoria) ?? 0,
      'estat': _estat,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/incidencies/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode == 201) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['id'] as int;
    } else {
      throw Exception('Error creant incidència (${res.statusCode}) ${res.body}');
    }
  }

  Future<void> _updateIncidencia(int id) async {
    final payload = {
      'id_obra': _obraSeleccionada,
      'id_tasca': _tascaSeleccionada?.id,
      'descripcio': _descCtrl.text.trim(),
      'data_inici': _fmtDate(_dataInici!),
      'data_fi': _dataFi != null ? _fmtDate(_dataFi!) : null,
      'criticitat': _criticitat,
      'prioritat': _prioritat,
      'categoria': int.tryParse(_categoria) ?? 0,
      'estat': _estat,
    };
    final res = await http.put(
      Uri.parse('$baseUrl/incidencies/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error actualitzant incidència (${res.statusCode}) ${res.body}');
    }
  }

  Future<void> _syncSolucions(int idIncidencia) async {
    // Estratègia simple: esborra totes i crea de nou
    await http.delete(Uri.parse('$baseUrl/solucions/$idIncidencia/bulk_delete/'));

    for (final s in _solucions) {
      final payload = {
        'id_incidencia': idIncidencia,
        'id_tasca': s.idTasca,
        'descripcio': s.descripcio.trim(),
        'cost_monetari': s.costMonetari,
        'eficacia': s.eficacia,
        'cost_temporal': s.costTemporal,
        'impacte': s.impacte,
      };
      final res = await http.post(
        Uri.parse('$baseUrl/solucions/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201) {
        throw Exception('Error creant solució (${res.statusCode}) ${res.body}');
      }
    }
  }

  //==================== SUBMIT ====================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInici == null) {
      _snack('⚠️ Falta la data d\'inici');
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
      late int incId;
      if (widget.initial == null) {
        incId = await _createIncidencia();
      } else {
        incId = widget.initial!.id;
        await _updateIncidencia(incId);
      }
      await _syncSolucions(incId);

      if (mounted) {
        _dirty = false;
        _snack('✅ Incidència desada correctament!', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  //==================== HELPERS ====================
  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : null),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDate(DateTime? current) async {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<bool?> _confirmDesar() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmació'),
        content: const Text('Vols desar la incidència i les solucions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel·la')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desa')),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_dirty && !_saving) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Canvis sense desar'),
          content: const Text('Vols sortir sense desar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel·la')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sortir')),
          ],
        ),
      );
      return leave ?? false;
    }
    return true;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  //==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? 'Nova Incidència' : 'Editar Incidència'),
        ),
        body: Stack(
          children: [
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
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Obligatori' : null,
                    ),
                    _gap(),

                    // OBRA
                    if (_obraSeleccionada == null)
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration('Obra *', icon: Icons.business_outlined),
                        items: _obres
                            .map((o) => DropdownMenuItem<int>(value: o.id, child: Text(o.nom)))
                            .toList(),
                        onChanged: (v) async {
                          _markDirty();
                          setState(() {
                            _obraSeleccionada = v;
                            _tascaSeleccionada = null;
                            _tasquesMateixaObra = [];
                          });
                          if (v != null) {
                            _tasquesMateixaObra = await _fetchTasquesPerObra(v);
                            if (mounted) setState(() {});
                          }
                        },
                        validator: (v) => v == null ? 'Selecciona una obra' : null,
                      )
                    else
                      _readOnlyTile('Obra', _obres.firstWhere((o) => o.id == _obraSeleccionada, orElse: () => ObraOption(id: _obraSeleccionada!, nom: 'Obra #${_obraSeleccionada!}')).nom),

                    _gap(),

                    // TASCA (opcional)
                    DropdownButtonFormField<TascaOption>(
                      decoration: _inputDecoration('Tasca associada', icon: Icons.link_outlined),
                      value: _tascaSeleccionada,
                      items: [
                        const DropdownMenuItem<TascaOption>(value: null, child: Text('— Sense tasca —')),
                        ..._tasquesMateixaObra
                            .map((t) => DropdownMenuItem(value: t, child: Text(t.desc, maxLines: 1, overflow: TextOverflow.ellipsis)))
                            .toList(),
                      ],
                      onChanged: (v) {
                        _markDirty();
                        setState(() => _tascaSeleccionada = v);
                      },
                    ),

                    const Divider(height: 32),
                    _sectionTitle('Planificació'),

                    _dateTile(
                      title: 'Data inici *',
                      date: _dataInici,
                      onTap: () async {
                        final d = await _pickDate(_dataInici);
                        if (d != null) {
                          _markDirty();
                          setState(() => _dataInici = d);
                        }
                      },
                    ),
                    _dateTile(
                      title: 'Data fi',
                      date: _dataFi,
                      onTap: () async {
                        final d = await _pickDate(_dataFi);
                        if (d != null) {
                          _markDirty();
                          setState(() => _dataFi = d);
                        }
                      },
                    ),

                    _gap(),
                    _sectionTitle('Severitat i estat'),

                    _sliderRow('Criticitat', _criticitat, (v) {
                      _markDirty();
                      setState(() => _criticitat = v);
                    }),
                    _sliderRow('Prioritat', _prioritat, (v) {
                      _markDirty();
                      setState(() => _prioritat = v);
                    }),

                    _gap(8),
                    _textField(
                      controller: TextEditingController(text: _categoria),
                      label: 'Categoria (numèrica o codi)',
                      icon: Icons.category_outlined,
                      keyboard: TextInputType.number,
                      validator: (_) => null,
                      // com que controlem amb un controller temporal, caldrà assignar quan canviï
                    ),
                    // millor fer servir un onChanged a part:
                    // Fem un camp separat per categoria per controlar _categoria
                    // Per simplicitat utilitzem un TextField "temporal" aquí:

                    _gap(),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Estat *', icon: Icons.flag_outlined),
                      value: _estat,
                      items: const [
                        DropdownMenuItem(value: 'Oberta', child: Text('Oberta')),
                        DropdownMenuItem(value: 'En procés', child: Text('En procés')),
                        DropdownMenuItem(value: 'Tancada', child: Text('Tancada')),
                      ],
                      onChanged: (v) {
                        _markDirty();
                        setState(() => _estat = v ?? _estat);
                      },
                    ),

                    const Divider(height: 32),

                    _sectionTitle('Solucions'),
                    if (_solucions.isEmpty)
                      Text('No hi ha solucions afegides', style: TextStyle(color: Colors.grey[600]))
                    else
                      ...List.generate(_solucions.length, (i) => _solItem(_solucions[i], i)),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _addSolucioDialog,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Afegir solució'),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
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
          onPressed: _saving ? null : _submit,
          icon: const Icon(Icons.save),
          label: const Text('Desa'),
        ),
      ),
    );
  }

  //==================== SMALL BUILDERS ====================
  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _gap([double h = 12]) => SizedBox(height: h);

  InputDecoration _inputDecoration(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

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
      onChanged: (v) {
        _markDirty();
        if (label.startsWith('Categoria')) {
          _categoria = v; // Aquí actualitzem _categoria si cal
        }
      },
    );
  }

  Widget _dateTile({required String title, required DateTime? date, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(date == null ? 'Selecciona una data' : _fmtDate(date)),
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

  Widget _sliderRow(String title, int value, void Function(int) onChanged) {
    return Row(
      children: [
        Text(title),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$value',
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
      ],
    );
  }

  //==================== SOLUCIONS ====================
  Widget _solItem(SolucioDraft s, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(s.descripcio, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Cost €: ${s.costMonetari}  · Eficiència: ${s.eficacia}\nTemps: ${s.costTemporal}h · Impacte: ${s.impacte}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            _markDirty();
            setState(() => _solucions.removeAt(index));
          },
        ),
        onTap: () async {
          final edited = await showDialog<SolucioDraft>(
            context: context,
            builder: (ctx) => SolucioDialog(
              initial: s,
              tasques: _tasquesMateixaObra,
            ),
          );
          if (edited != null) {
            _markDirty();
            setState(() => _solucions[index] = edited);
          }
        },
      ),
    );
  }

  Future<void> _addSolucioDialog() async {
    final draft = await showDialog<SolucioDraft>(
      context: context,
      builder: (ctx) => SolucioDialog(
        tasques: _tasquesMateixaObra,
      ),
    );
    if (draft != null) {
      _markDirty();
      setState(() => _solucions.add(draft));
    }
  }
}

//==================== DIALOG SOLUCIÓ ====================
class SolucioDialog extends StatefulWidget {
  final SolucioDraft? initial;
  final List<TascaOption> tasques;
  const SolucioDialog({super.key, this.initial, required this.tasques});

  @override
  State<SolucioDialog> createState() => _SolucioDialogState();
}

class _SolucioDialogState extends State<SolucioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _eficCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _impCtrl = TextEditingController();
  TascaOption? _tascaAssoc;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final s = widget.initial!;
      _descCtrl.text = s.descripcio;
      _costCtrl.text = s.costMonetari.toString();
      _eficCtrl.text = s.eficacia.toString();
      _tempCtrl.text = s.costTemporal.toString();
      _impCtrl.text = s.impacte.toString();
      if (s.idTasca != null) {
        _tascaAssoc = widget.tasques.firstWhere(
          (t) => t.id == s.idTasca,
          orElse: () => TascaOption(id: s.idTasca!, desc: 'Tasca (no trobada)'),
        );
      }
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _costCtrl.dispose();
    _eficCtrl.dispose();
    _tempCtrl.dispose();
    _impCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nova solució' : 'Editar solució'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripció *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obligatori' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              // Tasca associada
              DropdownButtonFormField<TascaOption>(
                value: _tascaAssoc,
                decoration: const InputDecoration(labelText: 'Tasca associada'),
                items: [
                  const DropdownMenuItem<TascaOption>(value: null, child: Text('— Sense tasca —')),
                  ...widget.tasques.map((t) => DropdownMenuItem(value: t, child: Text(t.desc, maxLines: 1, overflow: TextOverflow.ellipsis)))
                ],
                onChanged: (v) => setState(() => _tascaAssoc = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost monetari (€) *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatori';
                  if (int.tryParse(v) == null) return 'Nombre enter';
                  return null;
                },
              ),
              TextFormField(
                controller: _eficCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Eficàcia (0-100) *'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null) return 'Enter';
                  if (n < 0 || n > 100) return '0-100';
                  return null;
                },
              ),
              TextFormField(
                controller: _tempCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost temporal (hores) *'),
                validator: (v) => int.tryParse(v ?? '') == null ? 'Enter' : null,
              ),
              TextFormField(
                controller: _impCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Impacte (1-5) *'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null) return 'Enter';
                  if (n < 1 || n > 5) return '1-5';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel·la')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              SolucioDraft(
                idTasca: _tascaAssoc?.id,
                descripcio: _descCtrl.text.trim(),
                costMonetari: int.parse(_costCtrl.text),
                eficacia: int.parse(_eficCtrl.text),
                costTemporal: int.parse(_tempCtrl.text),
                impacte: int.parse(_impCtrl.text),
              ),
            );
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }
}

//==================== DTOs & Drafts ====================
class IncidenciaDTO {
  final int id;
  final int idObra;
  final int? idTasca;
  final String descripcio;
  final DateTime dataInici;
  final DateTime? dataFi;
  final int criticitat;
  final int prioritat;
  final int categoria;
  final String estat;

  IncidenciaDTO({
    required this.id,
    required this.idObra,
    this.idTasca,
    required this.descripcio,
    required this.dataInici,
    this.dataFi,
    required this.criticitat,
    required this.prioritat,
    required this.categoria,
    required this.estat,
  });

  factory IncidenciaDTO.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) => s == null ? null : DateTime.parse(s);
    return IncidenciaDTO(
      id: json['id'],
      idObra: json['id_obra'],
      idTasca: json['id_tasca'],
      descripcio: json['descripcio'] ?? '',
      dataInici: DateTime.parse(json['data_inici']),
      dataFi: parseDate(json['data_fi']),
      criticitat: json['criticitat'] ?? 1,
      prioritat: json['prioritat'] ?? 1,
      categoria: json['categoria'] ?? 0,
      estat: json['estat'] ?? 'Oberta',
    );
  }
}

class SolucioDTO {
  final int id;
  final int idIncidencia;
  final int? idTasca;
  final String descripcio;
  final int costMonetari;
  final int eficacia;
  final int costTemporal;
  final int impacte;

  SolucioDTO({
    required this.id,
    required this.idIncidencia,
    this.idTasca,
    required this.descripcio,
    required this.costMonetari,
    required this.eficacia,
    required this.costTemporal,
    required this.impacte,
  });

  factory SolucioDTO.fromJson(Map<String, dynamic> json) {
    return SolucioDTO(
      id: json['id'],
      idIncidencia: json['id_incidencia'],
      idTasca: json['id_tasca'],
      descripcio: json['descripcio'] ?? '',
      costMonetari: json['cost_monetari'] ?? 0,
      eficacia: json['eficacia'] ?? 0,
      costTemporal: json['cost_temporal'] ?? 0,
      impacte: json['impacte'] ?? 1,
    );
  }

  SolucioDraft toDraft() => SolucioDraft(
        idTasca: idTasca,
        descripcio: descripcio,
        costMonetari: costMonetari,
        eficacia: eficacia,
        costTemporal: costTemporal,
        impacte: impacte,
      );
}

class SolucioDraft {
  final int? idTasca;
  final String descripcio;
  final int costMonetari;
  final int eficacia;
  final int costTemporal;
  final int impacte;

  SolucioDraft({
    this.idTasca,
    required this.descripcio,
    required this.costMonetari,
    required this.eficacia,
    required this.costTemporal,
    required this.impacte,
  });
}

class ObraOption {
  final int id;
  final String nom;
  ObraOption({required this.id, required this.nom});
}

class TascaOption {
  final int id;
  final String desc;
  TascaOption({required this.id, required this.desc});
}
