///FET
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Pantalla de **Gestió de Tasques** (creació / edició) amb el mateix nivell de detall
/// que l'"Obra Full Form". Inclou:
///
/// - Dades generals (descripció, dates, prioritat, visibilitat)
/// - Selecció d'Obra (si no es rep per paràmetre)
/// - Selecció de Tasca Pare (jerarquia)
/// - Assignació de Treballadors (N:M) via diàleg multi-selecció
/// - Confirmació abans de desar, SnackBars d'errors/success
/// - Botó flotant de desament i protecció davant sortida amb canvis
/// - Validacions exhaustives i missatges personalitzats
/// - Carregues asíncrones d'opcions (obres, tasques, usuaris treballadors)
/// - Compatibilitat amb tema clar/fosc (Theme.of(context))
///
/// Revisa els ENDPOINTS (baseUrl) i adapta'ls al teu backend.
class TascaFormScreen extends StatefulWidget {
  /// id de l'obra a la qual pertany la tasca. Si és nul, es mostrarà un dropdown.
  final int? obraId;

  /// Dades inicials per editar una tasca existent. Si és null -> mode creació.
  final TascaDTO? initial;

  const TascaFormScreen({super.key, this.obraId, this.initial});

  @override
  State<TascaFormScreen> createState() => _TascaFormScreenState();
}

class _TascaFormScreenState extends State<TascaFormScreen> {
  //==================== CONFIG ====================
  static const String baseUrl = 'http://localhost:8000/api';

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _dirty = false; // per saber si hi ha canvis sense desar

  //==================== CONTROLLERS ====================
  final _descCtrl = TextEditingController();
  DateTime? _dataInici;
  DateTime? _dataFi;
  int _prioritat = 3; // 1-5
  bool _visibilitat = true;

  //==================== OBRA / TASCA PARE ====================
  int? _obraSeleccionada;
  TascaOption? _tascaPare; // nullable

  List<ObraOption> _obres = [];
  List<TascaOption> _tasquesMateixaObra = [];

  //==================== TREBALLADORS ====================
  List<UsuariOption> _treballadors = [];
  final List<UsuariOption> _seleccionats = [];

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
      final t = widget.initial!;
      _descCtrl.text = t.descripcio;
      _dataInici = t.dataInici;
      _dataFi = t.dataFi;
      _prioritat = t.prioritat;
      _visibilitat = t.visibilitat;
      _obraSeleccionada = widget.obraId ?? t.idObra;
      // Tasca pare es carregarà un cop tinguem les opcions
      // Treballadors seleccionats es carregaran després
    } else {
      _obraSeleccionada = widget.obraId; // pot venir predefinida
    }
  }

  Future<void> _loadOptions() async {
    try {
      // Carregar obres si cal
      if (_obraSeleccionada == null) {
        _obres = await _fetchObres();
      }
      // Carregar treballadors
      _treballadors = await _fetchTreballadors();

      // Si tenim obra seleccionada, carreguem tasques per escollir pare
      if (_obraSeleccionada != null) {
        _tasquesMateixaObra = await _fetchTasquesPerObra(_obraSeleccionada!);
      }

      // Si estem editant, marquem tasca pare i treballadors
      if (widget.initial != null) {
        final t = widget.initial!;
        if (t.idTascaPare != null) {
          _tascaPare = _tasquesMateixaObra.firstWhere(
            (opt) => opt.id == t.idTascaPare,
            orElse: () => TascaOption(id: t.idTascaPare!, desc: 'Tasca pare (No trobada)')
          );
        }
        // Carregar treballadors assignats a la tasca
        final assignats = await _fetchTreballadorsDeTasca(t.id);
        _seleccionats.addAll(assignats);
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        _snack('Error carregant opcions: $e');
      }
    }
  }

  //==================== API CALLS ====================
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
      return l
          .map((e) => TascaOption(id: e['id'], desc: (e['descripcio'] ?? '').toString()))
          .toList();
    }
    throw Exception('No s\'han pogut carregar les tasques');
  }

  Future<List<UsuariOption>> _fetchTreballadors() async {
    final res = await http.get(Uri.parse('$baseUrl/treballadors/?tipus=TREBALLADOR'));
    if (res.statusCode == 200) {
      final l = jsonDecode(res.body) as List<dynamic>;
      return l
          .map((e) => UsuariOption(
                id: e['id'],
                nom: e['nom'] ?? e['username'] ?? '—',
                cognoms: e['cognoms'] ?? '',
              ))
          .toList();
    }
    throw Exception('No s\'han pogut carregar els treballadors');
  }

  Future<List<UsuariOption>> _fetchTreballadorsDeTasca(int idTasca) async {
    final res = await http.get(Uri.parse('$baseUrl/tasca_treballador/?id_tasca=$idTasca'));
    if (res.statusCode == 200) {
      final l = jsonDecode(res.body) as List<dynamic>;
      return l
          .map((e) => UsuariOption(
                id: e['id_treballador'],
                nom: e['treballador_nom'] ?? 'Treballador',
                cognoms: e['treballador_cognoms'] ?? '',
              ))
          .toList();
    }
    return [];
  }

  Future<int> _createTasca() async {
    final payload = {
      'id_obra': _obraSeleccionada,
      'id_tasca_pare': _tascaPare?.id,
      'descripcio': _descCtrl.text.trim(),
      'data_inici': _fmtDate(_dataInici!),
      'data_fi': _dataFi != null ? _fmtDate(_dataFi!) : null,
      'prioritat': _prioritat,
      'visibilitat_tasca': _visibilitat,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/tasques/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode == 201) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['id'] as int;
    }
    throw Exception('Error creant tasca (${res.statusCode}) ${res.body}');
  }

  Future<void> _updateTasca(int id) async {
    final payload = {
      'id_obra': _obraSeleccionada,
      'id_tasca_pare': _tascaPare?.id,
      'descripcio': _descCtrl.text.trim(),
      'data_inici': _fmtDate(_dataInici!),
      'data_fi': _dataFi != null ? _fmtDate(_dataFi!) : null,
      'prioritat': _prioritat,
      'visibilitat_tasca': _visibilitat,
    };

    final res = await http.put(
      Uri.parse('$baseUrl/tasques/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error actualitzant tasca (${res.statusCode}) ${res.body}');
    }
  }

  Future<void> _syncTreballadors(int idTasca) async {
    // Aquí pots decidir: esborro tots i creo de nou, o faig diff. Simplicitat: esborra i crea
    // 1) Esborrar existents
    await http.delete(Uri.parse('$baseUrl/tasca_treballador/$idTasca/bulk_delete/'));

    // 2) Crear nous
    for (final u in _seleccionats) {
      final payload = {
        'id_tasca': idTasca,
        'id_treballador': u.id,
        'comentari': null,
      };
      final res = await http.post(
        Uri.parse('$baseUrl/tasca_treballador/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201) {
        throw Exception('Error assignant treballador ${u.id} (${res.statusCode})');
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
      late int tascaId;
      if (widget.initial == null) {
        tascaId = await _createTasca();
      } else {
        tascaId = widget.initial!.id;
        await _updateTasca(tascaId);
      }

      await _syncTreballadors(tascaId);

      if (mounted) {
        _dirty = false;
        _snack('✅ Tasca desada correctament!', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  //==================== UI HELPERS ====================
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
        content: const Text('Vols desar la tasca?'),
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
          title: const Text('Hi ha canvis sense desar'),
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
          title: Text(widget.initial == null ? 'Nova Tasca' : 'Editar Tasca'),
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
                      maxLines: 3,
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
                            _tascaPare = null;
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

                    // Tasca pare
                    DropdownButtonFormField<TascaOption>(
                      decoration: _inputDecoration('Tasca pare', icon: Icons.account_tree_outlined),
                      value: _tascaPare,
                      items: [
                        const DropdownMenuItem<TascaOption>(value: null, child: Text('— Sense tasca pare —')),
                        ..._tasquesMateixaObra
                            .where((t) => widget.initial == null || t.id != widget.initial!.id)
                            .map((t) => DropdownMenuItem(value: t, child: Text(t.desc, maxLines: 1, overflow: TextOverflow.ellipsis)))
                            .toList(),
                      ],
                      onChanged: (v) {
                        _markDirty();
                        setState(() => _tascaPare = v);
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
                            onChanged: (v) {
                              _markDirty();
                              setState(() => _prioritat = v.toInt());
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Visible als usuaris'),
                      value: _visibilitat,
                      onChanged: (v) {
                        _markDirty();
                        setState(() => _visibilitat = v);
                      },
                    ),

                    const Divider(height: 32),

                    _sectionTitle('Assignació de treballadors'),
                    if (_seleccionats.isEmpty)
                      Text('No hi ha treballadors assignats', style: TextStyle(color: Colors.grey[600]))
                    else
                      Wrap(
                        spacing: 6,
                        children: _seleccionats
                            .map((u) => Chip(
                                  label: Text(u.nomComplet),
                                  onDeleted: () {
                                    _markDirty();
                                    setState(() => _seleccionats.remove(u));
                                  },
                                ))
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

  //==================== DIALOG TREBALLADORS ====================
  Future<void> _openSelectTreballadors() async {
    final result = await showDialog<List<UsuariOption>>(
      context: context,
      builder: (ctx) => _SelectTreballadorsDialog(
        tots: _treballadors,
        seleccionats: _seleccionats,
      ),
    );
    if (result != null) {
      _markDirty();
      setState(() {
        _seleccionats
          ..clear()
          ..addAll(result);
      });
    }
  }
}

//==================== DIALOG MULTISELECT TREBALLADORS ====================
class _SelectTreballadorsDialog extends StatefulWidget {
  final List<UsuariOption> tots;
  final List<UsuariOption> seleccionats;
  const _SelectTreballadorsDialog({required this.tots, required this.seleccionats});

  @override
  State<_SelectTreballadorsDialog> createState() => _SelectTreballadorsDialogState();
}

class _SelectTreballadorsDialogState extends State<_SelectTreballadorsDialog> {
  late List<UsuariOption> _temp;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _temp = List.of(widget.seleccionats);
  }

  @override
  Widget build(BuildContext context) {
    final filtres = widget.tots
        .where((u) => u.nomComplet.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return AlertDialog(
      title: const Text('Selecciona treballadors'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cerca...'),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtres.length,
                itemBuilder: (ctx, i) {
                  final u = filtres[i];
                  final selected = _temp.any((s) => s.id == u.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _temp.add(u);
                        } else {
                          _temp.removeWhere((s) => s.id == u.id);
                        }
                      });
                    },
                    title: Text(u.nomComplet),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel·la')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _temp), child: const Text('Aplica')),
      ],
    );
  }
}

//==================== DTOs / OPTIONS (client side) ====================
class TascaDTO {
  final int id;
  final int idObra;
  final String descripcio;
  final DateTime dataInici;
  final DateTime? dataFi;
  final int prioritat;
  final bool visibilitat;
  final int? idTascaPare;

  TascaDTO({
    required this.id,
    required this.idObra,
    required this.descripcio,
    required this.dataInici,
    this.dataFi,
    required this.prioritat,
    required this.visibilitat,
    this.idTascaPare,
  });

  factory TascaDTO.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) => s == null ? null : DateTime.parse(s);
    return TascaDTO(
      id: json['id'],
      idObra: json['id_obra'],
      descripcio: json['descripcio'] ?? '',
      dataInici: DateTime.parse(json['data_inici']),
      dataFi: parseDate(json['data_fi']),
      prioritat: json['prioritat'] ?? 3,
      visibilitat: json['visibilitat_tasca'] ?? true,
      idTascaPare: json['id_tasca_pare'],
    );
  }
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

class UsuariOption {
  final int id;
  final String nom;
  final String cognoms;
  UsuariOption({required this.id, required this.nom, required this.cognoms});
  String get nomComplet => '$nom $cognoms'.trim();
}
