//FET

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Pantalla de **Sol·licituds de Recursos (SolRecurs)** amb el mateix nivell de detall
/// que les pantalles d'Obra, Tasca i Incidència.
///
/// Funcionalitats:
/// - Crear/editar UNA sol·licitud o bé un lot (batch) de sol·licituds per a la mateixa obra.
/// - Selecció d'Obra i Recurs amb informació contextual (unitats, stock disponible).
/// - Validacions personalitzades (quantitat > 0, dates, etc.).
/// - Camps opcionals: comentari, proveïdor, data_entrega.
/// - Confirmació abans de desar, SnackBars, overlay de càrrega i control de canvis (_dirty).
/// - Possibilitat d'esborrar o editar cada línia del lot abans d'enviar.
///
/// **Endpoints a adaptar** (placeholders):
/// - POST   /sol_recurs/
/// - PUT    /sol_recurs/{id}/
/// - DELETE /sol_recurs/{id}/
/// - GET    /sol_recurs/?id_obra=XX
/// - GET    /recursos/
/// - GET    /obres/
class SolRecursFormScreen extends StatefulWidget {
  /// Obra ja seleccionada (si null, es mostrarà dropdown)
  final int? obraId;

  /// Si vols editar una sol·licitud concreta
  final SolRecursDTO? initial;

  /// Mode lot: permet afegir múltiples línies i enviar-les de cop (només creació)
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
  //==================== CONFIG ====================
  static const String baseUrl = 'http://localhost:8000/api';

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _dirty = false;

  //==================== Obra / Recursos ====================
  int? _obraSeleccionada;
  List<ObraOption> _obres = [];
  List<RecursOption> _recursos = [];

  //==================== Una sol·licitud (mode single) ====================
  RecursOption? _recursSel;
  final _quantCtrl = TextEditingController();
  DateTime? _dataNecessitat;
  DateTime? _dataEntrega;
  final _comentCtrl = TextEditingController();
  final _provCtrl = TextEditingController();

  //==================== Lot de sol·licituds ====================
  final List<SolRecursDraft> _batch = [];

  @override
  void initState() {
    super.initState();
    _initFromInitial();
    _loadOptions();
  }

  @override
  void dispose() {
    _quantCtrl.dispose();
    _comentCtrl.dispose();
    _provCtrl.dispose();
    super.dispose();
  }

  void _initFromInitial() {
    _obraSeleccionada = widget.obraId ?? widget.initial?.idObra;
    if (widget.initial != null) {
      final i = widget.initial!;
      _recursSel = RecursOption(
        id: i.idRecurs,
        nom: i.recursNom ?? 'Recurs',
        unitat: i.unitat ?? '',
        stock: null,
        tipus: null,
      );
      _quantCtrl.text = i.quantitat.toString();
      _dataNecessitat = i.dataNecessitat;
      _dataEntrega = i.dataEntrega;
      _comentCtrl.text = i.comentari ?? '';
      _provCtrl.text = i.proveidor ?? '';
    }
  }

  Future<void> _loadOptions() async {
    try {
      if (_obraSeleccionada == null) {
        _obres = await _fetchObres();
      }
      _recursos = await _fetchRecursos();
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

  Future<List<RecursOption>> _fetchRecursos() async {
    final res = await http.get(Uri.parse('$baseUrl/recursos/'));
    if (res.statusCode == 200) {
      final l = jsonDecode(res.body) as List<dynamic>;
      return l
          .map((e) => RecursOption(
                id: e['id'],
                nom: e['nom'] ?? '—',
                unitat: e['unitats_mesura'] ?? '',
                stock: (e['quantitat_stock'] is num) ? (e['quantitat_stock'] as num).toDouble() : null,
                tipus: e['tipus_recurs'],
              ))
          .toList();
    }
    throw Exception('No s\'han pogut carregar els recursos');
  }

  Future<int> _createSol(SolRecursDraft draft) async {
    final payload = {
      'id_obra': _obraSeleccionada,
      'id_recurs': draft.recurs.id,
      'quantitat': draft.quantitat,
      'data_necessitat': _fmtDate(draft.dataNecessitat),
      'comentari': draft.comentari,
      'proveidor': draft.proveidor,
      'data_entrega': draft.dataEntrega != null ? _fmtDate(draft.dataEntrega!) : null,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/sol_recurs/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode == 201) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['id'] as int;
    }
    throw Exception('Error creant sol·licitud (${res.statusCode}) ${res.body}');
  }

  Future<void> _updateSol(int id, SolRecursDraft draft) async {
    final payload = {
      'id_obra': _obraSeleccionada,
      'id_recurs': draft.recurs.id,
      'quantitat': draft.quantitat,
      'data_necessitat': _fmtDate(draft.dataNecessitat),
      'comentari': draft.comentari,
      'proveidor': draft.proveidor,
      'data_entrega': draft.dataEntrega != null ? _fmtDate(draft.dataEntrega!) : null,
    };

    final res = await http.put(
      Uri.parse('$baseUrl/sol_recurs/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error actualitzant sol·licitud (${res.statusCode}) ${res.body}');
    }
  }

  //==================== SUBMIT ====================
  Future<void> _submit() async {
    if (widget.batchMode) {
      if (_obraSeleccionada == null) {
        _snack('⚠️ Selecciona una obra');
        return;
      }
      if (_batch.isEmpty) {
        _snack('Afegeix almenys una línia');
        return;
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
      if (_obraSeleccionada == null) {
        _snack('⚠️ Selecciona una obra');
        return;
      }
      if (_recursSel == null) {
        _snack('⚠️ Selecciona un recurs');
        return;
      }
      if (_dataNecessitat == null) {
        _snack('⚠️ Selecciona la data de necessitat');
        return;
      }
    }

    final confirm = await _confirmDesar();
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      if (widget.batchMode) {
        for (final draft in _batch) {
          await _createSol(draft);
        }
      } else {
        final draft = SolRecursDraft(
          recurs: _recursSel!,
          quantitat: int.parse(_quantCtrl.text),
          dataNecessitat: _dataNecessitat!,
          comentari: _comentCtrl.text.isEmpty ? null : _comentCtrl.text,
          proveidor: _provCtrl.text.isEmpty ? null : _provCtrl.text,
          dataEntrega: _dataEntrega,
        );
        if (widget.initial == null) {
          await _createSol(draft);
        } else {
          await _updateSol(widget.initial!.id, draft);
        }
      }

      if (mounted) {
        _dirty = false;
        _snack('✅ Sol·licitud(es) desades correctament!', success: true);
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
        content: Text(widget.batchMode
            ? 'Vols desar totes les sol·licituds?'
            : 'Vols desar la sol·licitud?'),
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
          title: Text(widget.batchMode
              ? 'Sol·licituds de Recursos (lot)'
              : widget.initial == null
                  ? 'Nova Sol·licitud de Recurs'
                  : 'Editar Sol·licitud'),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.batchMode ? _buildBatchBody() : _buildSingleBody(),
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

  //==================== SINGLE MODE BODY ====================
  Widget _buildSingleBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Dades de l\'obra'),
          if (_obraSeleccionada == null)
            DropdownButtonFormField<int>(
              decoration: _inputDecoration('Obra *', icon: Icons.business_outlined),
              items: _obres
                  .map((o) => DropdownMenuItem<int>(value: o.id, child: Text(o.nom)))
                  .toList(),
              onChanged: (v) {
                _markDirty();
                setState(() => _obraSeleccionada = v);
              },
              validator: (v) => v == null ? 'Selecciona una obra' : null,
            )
          else
            _readOnlyTile('Obra', _obres.firstWhere((o) => o.id == _obraSeleccionada, orElse: () => ObraOption(id: _obraSeleccionada!, nom: 'Obra #${_obraSeleccionada!}')).nom),

          const Divider(height: 32),
          _sectionTitle('Recurs i quantitat'),
          DropdownButtonFormField<RecursOption>(
            decoration: _inputDecoration('Recurs *', icon: Icons.inventory_2_outlined),
            value: _recursSel,
            items: _recursos
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text('${r.nom} (${r.unitat})'),
                    ))
                .toList(),
            onChanged: (v) {
              _markDirty();
              setState(() => _recursSel = v);
            },
            validator: (v) => v == null ? 'Selecciona un recurs' : null,
          ),
          _gap(),
          TextFormField(
            controller: _quantCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Quantitat *', icon: Icons.numbers),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Obligatori';
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Entra un enter > 0';
              return null;
            },
            onChanged: (_) => _markDirty(),
          ),
          if (_recursSel?.stock != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text('Stock disponible: ${_recursSel!.stock} ${_recursSel!.unitat}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),

          const Divider(height: 32),
          _sectionTitle('Dates i informació extra'),
          _dateTile(
            title: 'Data necessitat *',
            date: _dataNecessitat,
            onTap: () async {
              final d = await _pickDate(_dataNecessitat);
              if (d != null) {
                _markDirty();
                setState(() => _dataNecessitat = d);
              }
            },
          ),
          _dateTile(
            title: 'Data entrega (opcional)',
            date: _dataEntrega,
            onTap: () async {
              final d = await _pickDate(_dataEntrega);
              if (d != null) {
                _markDirty();
                setState(() => _dataEntrega = d);
              }
            },
          ),

          _gap(),
          TextFormField(
            controller: _provCtrl,
            decoration: _inputDecoration('Proveïdor'),
            onChanged: (_) => _markDirty(),
          ),
          _gap(),
          TextFormField(
            controller: _comentCtrl,
            decoration: _inputDecoration('Comentari'),
            maxLines: 3,
            onChanged: (_) => _markDirty(),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
        ],
      ),
    );
  }

  //==================== BATCH MODE BODY ====================
  Widget _buildBatchBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Dades de l\'obra'),
        if (_obraSeleccionada == null)
          DropdownButtonFormField<int>(
            decoration: _inputDecoration('Obra *', icon: Icons.business_outlined),
            items: _obres
                .map((o) => DropdownMenuItem<int>(value: o.id, child: Text(o.nom)))
                .toList(),
            onChanged: (v) {
              _markDirty();
              setState(() => _obraSeleccionada = v);
            },
            validator: (v) => v == null ? 'Selecciona una obra' : null,
          )
        else
          _readOnlyTile('Obra', _obres.firstWhere((o) => o.id == _obraSeleccionada, orElse: () => ObraOption(id: _obraSeleccionada!, nom: 'Obra #${_obraSeleccionada!}')).nom),

        const Divider(height: 32),
        _sectionTitle('Línies de sol·licitud'),
        if (_batch.isEmpty)
          Text('No hi ha línies', style: TextStyle(color: Colors.grey[600]))
        else
          ...List.generate(_batch.length, (i) => _lineItem(_batch[i], i)),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _addLineDialog,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Afegeix línia'),
          ),
        ),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
      ],
    );
  }

  Widget _lineItem(SolRecursDraft draft, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('${draft.recurs.nom}  x${draft.quantitat} ${draft.recurs.unitat}'),
        subtitle: Text('Necessitat: ${_fmtDate(draft.dataNecessitat)}\nProveïdor: ${draft.proveidor ?? '—'}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            _markDirty();
            setState(() => _batch.removeAt(index));
          },
        ),
        onTap: () async {
          final edited = await showDialog<SolRecursDraft>(
            context: context,
            builder: (ctx) => _LineDialog(
              recursos: _recursos,
              initial: draft,
            ),
          );
          if (edited != null) {
            _markDirty();
            setState(() => _batch[index] = edited);
          }
        },
      ),
    );
  }

  Future<void> _addLineDialog() async {
    final draft = await showDialog<SolRecursDraft>(
      context: context,
      builder: (ctx) => _LineDialog(recursos: _recursos),
    );
    if (draft != null) {
      _markDirty();
      setState(() => _batch.add(draft));
    }
  }

  //==================== SMALL UI BUILDERS ====================
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
}

//==================== DIALOG PER UNA LÍNIA (batch) ====================
class _LineDialog extends StatefulWidget {
  final List<RecursOption> recursos;
  final SolRecursDraft? initial;
  const _LineDialog({required this.recursos, this.initial});

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final _formKey = GlobalKey<FormState>();
  RecursOption? _recurs;
  final _quantCtrl = TextEditingController();
  DateTime? _dataNec;
  DateTime? _dataEnt;
  final _comentCtrl = TextEditingController();
  final _provCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final i = widget.initial!;
      _recurs = i.recurs;
      _quantCtrl.text = i.quantitat.toString();
      _dataNec = i.dataNecessitat;
      _dataEnt = i.dataEntrega;
      _comentCtrl.text = i.comentari ?? '';
      _provCtrl.text = i.proveidor ?? '';
    }
  }

  @override
  void dispose() {
    _quantCtrl.dispose();
    _comentCtrl.dispose();
    _provCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nova línia' : 'Editar línia'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RecursOption>(
                value: _recurs,
                decoration: const InputDecoration(labelText: 'Recurs *'),
                items: widget.recursos
                    .map((r) => DropdownMenuItem(value: r, child: Text('${r.nom} (${r.unitat})')))
                    .toList(),
                onChanged: (v) => setState(() => _recurs = v),
                validator: (v) => v == null ? 'Obligatori' : null,
              ),
              TextFormField(
                controller: _quantCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantitat *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatori';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter > 0';
                  return null;
                },
              ),
              _dateTile(
                context,
                title: 'Data necessitat *',
                date: _dataNec,
                onTap: () async {
                  final d = await _pickDate(context, _dataNec);
                  if (d != null) setState(() => _dataNec = d);
                },
              ),
              _dateTile(
                context,
                title: 'Data entrega',
                date: _dataEnt,
                onTap: () async {
                  final d = await _pickDate(context, _dataEnt);
                  if (d != null) setState(() => _dataEnt = d);
                },
              ),
              TextFormField(
                controller: _provCtrl,
                decoration: const InputDecoration(labelText: 'Proveïdor'),
              ),
              TextFormField(
                controller: _comentCtrl,
                decoration: const InputDecoration(labelText: 'Comentari'),
                maxLines: 2,
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
            if (_dataNec == null) return; // assegura data necessitat
            Navigator.pop(
              context,
              SolRecursDraft(
                recurs: _recurs!,
                quantitat: int.parse(_quantCtrl.text),
                dataNecessitat: _dataNec!,
                comentari: _comentCtrl.text.isEmpty ? null : _comentCtrl.text,
                proveidor: _provCtrl.text.isEmpty ? null : _provCtrl.text,
                dataEntrega: _dataEnt,
              ),
            );
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }

  Widget _dateTile(BuildContext context, {required String title, required DateTime? date, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(date == null ? 'Selecciona una data' : _fmtDate(date)),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? current) async {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

//==================== DTOs & Drafts ====================
class SolRecursDTO {
  final int id;
  final int idObra;
  final int idRecurs;
  final int quantitat;
  final DateTime dataNecessitat;
  final DateTime? dataEntrega;
  final String? comentari;
  final String? proveidor;
  final String? recursNom;
  final String? unitat;

  SolRecursDTO({
    required this.id,
    required this.idObra,
    required this.idRecurs,
    required this.quantitat,
    required this.dataNecessitat,
    this.dataEntrega,
    this.comentari,
    this.proveidor,
    this.recursNom,
    this.unitat,
  });

  factory SolRecursDTO.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) => s == null ? null : DateTime.parse(s);
    return SolRecursDTO(
      id: json['id'],
      idObra: json['id_obra'],
      idRecurs: json['id_recurs'],
      quantitat: json['quantitat'] ?? 0,
      dataNecessitat: DateTime.parse(json['data_necessitat']),
      dataEntrega: parseDate(json['data_entrega']),
      comentari: json['comentari'],
      proveidor: json['proveidor'],
      recursNom: json['recurs_nom'],
      unitat: json['unitats_mesura'],
    );
  }
}

class SolRecursDraft {
  final RecursOption recurs;
  final int quantitat;
  final DateTime dataNecessitat;
  final DateTime? dataEntrega;
  final String? comentari;
  final String? proveidor;

  SolRecursDraft({
    required this.recurs,
    required this.quantitat,
    required this.dataNecessitat,
    this.dataEntrega,
    this.comentari,
    this.proveidor,
  });
}

class ObraOption {
  final int id;
  final String nom;
  ObraOption({required this.id, required this.nom});
}

class RecursOption {
  final int id;
  final String nom;
  final String unitat;
  final double? stock;
  final String? tipus;
  RecursOption({required this.id, required this.nom, required this.unitat, this.stock, this.tipus});
}
