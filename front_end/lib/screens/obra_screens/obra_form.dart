//FET 

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';

/// Pantalla per crear una **Obra** i, opcionalment, introduir dades relacionades
/// (tasques inicials, sol·licituds de recursos, documents i responsable).
///
/// - Disseny dividit per seccions amb `ExpansionTile` i `Divider`.
/// - Validacions personalitzades i indicadors de camps obligatoris (*).
/// - `DropdownButtonFormField` per camps relacionats.
/// - Botó de desament flotant, diàleg de confirmació i SnackBars.
/// - Suport per pujar documents (només metadades + arxiu local amb FilePicker).
/// - Compatible amb mode fosc via Theme.of(context).
///
/// Nota: ajusta els endpoints de la teva API (BASE_URL) i els models segons convingui.
class ObraForm extends StatefulWidget {
  const ObraForm({super.key});

  @override
  State<ObraForm> createState() => _ObraFormState();
}

class _ObraFormState extends State<ObraForm> {
  //==================== CONSTANTS ====================
  static const String baseUrl = 'http://localhost:8000/api';

  //==================== FORM KEYS ====================
  final _formKey = GlobalKey<FormState>();

  //==================== CONTROLLERS (Obra) ====================
  final _nomCtrl = TextEditingController();
  final _ubicacioCtrl = TextEditingController();
  final _pressupostCtrl = TextEditingController();
  final _descripcioCtrl = TextEditingController();
  String _estat = 'Res Firmat';
  DateTime? _dataInici;
  DateTime? _dataPrevFi;

  //==================== RESPONSABLE OBRA ====================
  List<UsuariOption> _treballadors = [];
  UsuariOption? _responsableSeleccionat; // id_treballador
  DateTime? _dataIniciResp;

  //==================== TASQUES ====================
  final List<TascaDraft> _tasques = [];

  //==================== SOL·LICITUDS DE RECURSOS ====================
  final List<SolRecursDraft> _solRecursos = [];
  List<RecursOption> _recursos = [];

  //==================== DOCUMENTS ====================
  final List<DocumentDraft> _documents = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _ubicacioCtrl.dispose();
    _pressupostCtrl.dispose();
    _descripcioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final treballadors = await _fetchTreballadors();
      final recursos = await _fetchRecursos();
      if (mounted) {
        setState(() {
          _treballadors = treballadors;
          _recursos = recursos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error carregant opcions: $e')));
      }
    }
  }

  Future<List<UsuariOption>> _fetchTreballadors() async {
    final res = await http.get(
      Uri.parse('$baseUrl/treballadors/'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map(
            (e) => UsuariOption(
              id: e['id'],
              nom: e['nom'] ?? '—',
              cognoms: e['cognoms'] ?? '',
            ),
          )
          .toList();
    }
    throw Exception('No s\'han pogut carregar els treballadors');
  }

  Future<List<RecursOption>> _fetchRecursos() async {
    final res = await http.get(Uri.parse('$baseUrl/recursos/'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map(
            (e) => RecursOption(
              id: e['id'],
              nom: e['nom'],
              unitat: e['unitats_mesura'],
            ),
          )
          .toList();
    }
    throw Exception('No s\'han pogut carregar els recursos');
  }

  //==================== SUBMIT ====================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInici == null || _dataPrevFi == null) {
      _snack('⚠️ Selecciona les dates de l\'obra');
      return;
    }
    if (_responsableSeleccionat != null && _dataIniciResp == null) {
      _snack('⚠️ Indica la data d\'inici del responsable');
      return;
    }

    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() => _saving = true);

    try {
      // 1) Crear Obra
      final obraId = await _createObra();

      // 2) Crear Responsable (opcional)
      if (_responsableSeleccionat != null) {
        await _createResponsableObra(obraId);
      }

      // 3) Crear Tasques
      for (final t in _tasques) {
        await _createTasca(obraId, t);
      }

      // 4) Crear Sol·licituds de recursos
      for (final sr in _solRecursos) {
        await _createSolRecurs(obraId, sr);
      }

      // 5) Pujar documents (metadades)
      for (final d in _documents) {
        await _createDocument(obraId, d);
      }

      if (mounted) {
        _snack(
          '✅ Obra i dades relacionades creades correctament!',
          success: true,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _snack('❌ Error durant el desament: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<int> _createObra() async {
    final payload = {
      'nom': _nomCtrl.text.trim(),
      'ubicacio': _ubicacioCtrl.text.trim(),
      'pressupost': double.tryParse(_pressupostCtrl.text.replaceAll(',', '.')),
      'descripcio': _descripcioCtrl.text.trim(),
      'estat': _estat,
      'data_inici': _fmtDate(_dataInici!),
      'data_prev_fi': _fmtDate(_dataPrevFi!),
    };

    final res = await http.post(
      Uri.parse('$baseUrl/obres/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['id'] as int;
    } else {
      throw Exception('Error creant obra (${res.statusCode}) ${res.body}');
    }
  }

  Future<void> _createResponsableObra(int idObra) async {
    final payload = {
      'id_obra': idObra,
      'id_treballador': _responsableSeleccionat!.id,
      'data_inici': _fmtDate(_dataIniciResp!),
    };
    final res = await http.post(
      Uri.parse('$baseUrl/responsables/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Error creant responsable (${res.statusCode})');
    }
  }

  Future<void> _createTasca(int idObra, TascaDraft t) async {
    final payload = {
      'id_obra': idObra,
      'descripcio': t.descripcio.trim(),
      'data_inici': _fmtDate(t.dataInici),
      'data_fi': t.dataFi != null ? _fmtDate(t.dataFi!) : null,
      'prioritat': t.prioritat,
      'visibilitat_tasca': t.visibilitat,
      'id_tasca_pare': null,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/tasques/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Error creant tasca (${res.statusCode})');
    }
  }

  Future<void> _createSolRecurs(int idObra, SolRecursDraft sr) async {
    final payload = {
      'id_obra': idObra,
      'id_recurs': sr.recurs.id,
      'quantitat': sr.quantitat,
      'data_necessitat': _fmtDate(sr.dataNecessitat),
      'comentari': sr.comentari?.trim(),
      'proveidor': sr.proveidor?.trim(),
    };
    final res = await http.post(
      Uri.parse('$baseUrl/sol_recurs/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Error creant sol·licitud de recurs (${res.statusCode})');
    }
  }

  Future<void> _createDocument(int idObra, DocumentDraft d) async {
    final payload = {
      'id_obra': idObra,
      'id_creador':
          d.idCreador ?? 1, // TODO: substitueix pel teu usuari loguejat
      'nom': d.nom,
      'format': d.format,
      'mida': d.mida,
      'comentari': d.comentari,
      'data_pujada': DateTime.now().toIso8601String(),
      'tipus': d.tipus ?? 'general',
    };
    final res = await http.post(
      Uri.parse('$baseUrl/documents_obra/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Error creant document (${res.statusCode})');
    }
    // Si vols pujar binaris, necessites multipart request. Aquí només es guarda metadada.
  }

  //==================== UI HELPERS ====================
  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDate(DateTime? current) async {
    return await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<bool?> _showConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmació'),
            content: const Text(
              'Vols desar l\'obra i totes les dades relacionades?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel·la'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Desa'),
              ),
            ],
          ),
    );
  }

  //==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Obra (completa)')),
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
                    controller: _nomCtrl,
                    label: 'Nom *',
                    icon: Icons.title,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Introdueix el nom'
                                : null,
                  ),
                  _gap(),
                  _textField(
                    controller: _ubicacioCtrl,
                    label: 'Ubicació',
                    icon: Icons.location_on_outlined,
                  ),
                  _gap(),
                  _textField(
                    controller: _pressupostCtrl,
                    label: 'Pressupost (€)',
                    icon: Icons.euro,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v.replaceAll(',', '.'));
                      if (val == null) return 'Introdueix un número vàlid';
                      return null;
                    },
                  ),
                  _gap(),
                  _textField(
                    controller: _descripcioCtrl,
                    label: 'Descripció',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  _gap(),
                  DropdownButtonFormField<String>(
                    value: _estat,
                    decoration: _inputDecoration(
                      'Estat *',
                      icon: Icons.flag_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Res Firmat',
                        child: Text('Res Firmat'),
                      ),
                      DropdownMenuItem(
                        value: 'En execució',
                        child: Text('En execució'),
                      ),
                      DropdownMenuItem(
                        value: 'Finalitzada',
                        child: Text('Finalitzada'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _estat = v ?? _estat),
                  ),
                  _gap(),
                  _dateTile(
                    title: 'Data inici *',
                    date: _dataInici,
                    onTap: () async {
                      final d = await _pickDate(_dataInici);
                      if (d != null) setState(() => _dataInici = d);
                    },
                  ),
                  _dateTile(
                    title: 'Data prevista fi *',
                    date: _dataPrevFi,
                    onTap: () async {
                      final d = await _pickDate(_dataPrevFi);
                      if (d != null) setState(() => _dataPrevFi = d);
                    },
                  ),

                  const Divider(height: 32),

                  // RESPONSABLE
                  _sectionTitle('Responsable de l\'obra (opcional)'),
                  DropdownButtonFormField<UsuariOption>(
                    value: _responsableSeleccionat,
                    decoration: _inputDecoration(
                      'Selecciona responsable',
                      icon: Icons.person_outline,
                    ),
                    items:
                        _treballadors
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.nomComplet),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (v) => setState(() => _responsableSeleccionat = v),
                  ),
                  _gap(8),
                  if (_responsableSeleccionat != null)
                    _dateTile(
                      title: 'Data inici responsable *',
                      date: _dataIniciResp,
                      onTap: () async {
                        final d = await _pickDate(_dataIniciResp);
                        if (d != null) setState(() => _dataIniciResp = d);
                      },
                    ),

                  const Divider(height: 32),

                  // TASQUES
                  _sectionTitle('Tasques inicials'),
                  _builderList<TascaDraft>(
                    emptyText: 'Encara no hi ha tasques afegides',
                    items: _tasques,
                    itemBuilder: (t, i) => _tascaItem(context, t, i),
                    onAdd: _addTascaDialog,
                    icon: Icons.task_alt_outlined,
                  ),

                  const Divider(height: 32),

                  // SOL·LICITUDS DE RECURSOS
                  _sectionTitle('Sol·licituds de recursos'),
                  _builderList<SolRecursDraft>(
                    emptyText: 'No hi ha sol·licituds',
                    items: _solRecursos,
                    itemBuilder: (sr, i) => _solRecursItem(context, sr, i),
                    onAdd: _addSolRecursDialog,
                    icon: Icons.inventory_2_outlined,
                  ),

                  const Divider(height: 32),

                  // DOCUMENTS
                  _sectionTitle('Documents'),
                  _builderList<DocumentDraft>(
                    emptyText: 'Sense documents adjunts',
                    items: _documents,
                    itemBuilder: (d, i) => _documentItem(context, d, i),
                    onAdd: _addDocumentDialog,
                    icon: Icons.attach_file,
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  //==================== WIDGET HELPERS ====================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _gap([double h = 12]) => SizedBox(height: h);

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      subtitle: Text(date == null ? 'Selecciona una data' : _fmtDate(date)),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  /// Generador genèric de seccions amb una llista + botó d'afegir
  Widget _builderList<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required String emptyText,
    required VoidCallback onAdd,
    required IconData icon,
  }) {
    return Column(
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyText, style: const TextStyle(color: Colors.grey)),
          )
        else
          ...List.generate(items.length, (i) => itemBuilder(items[i], i)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: Icon(icon),
            label: const Text('Afegir'),
          ),
        ),
      ],
    );
  }

  //==================== DIALOGS ADD ITEMS ====================
  Future<void> _addTascaDialog() async {
    final draft = await showDialog<TascaDraft>(
      context: context,
      builder: (ctx) => TascaDialog(initial: null),
    );
    if (draft != null) {
      setState(() => _tasques.add(draft));
    }
  }

  Future<void> _addSolRecursDialog() async {
    final draft = await showDialog<SolRecursDraft>(
      context: context,
      builder: (ctx) => SolRecursDialog(recursos: _recursos),
    );
    if (draft != null) {
      setState(() => _solRecursos.add(draft));
    }
  }

  Future<void> _addDocumentDialog() async {
    final draft = await showDialog<DocumentDraft>(
      context: context,
      builder: (ctx) => const DocumentDialog(),
    );
    if (draft != null) {
      setState(() => _documents.add(draft));
    }
  }

  //==================== ITEM WIDGETS ====================
  Widget _tascaItem(BuildContext context, TascaDraft t, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(t.descripcio, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          'Inici: ${_fmtDate(t.dataInici)} - Fi: ${t.dataFi != null ? _fmtDate(t.dataFi!) : '—'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _tasques.removeAt(index)),
        ),
        onTap: () async {
          final edited = await showDialog<TascaDraft>(
            context: context,
            builder: (ctx) => TascaDialog(initial: t),
          );
          if (edited != null) {
            setState(() => _tasques[index] = edited);
          }
        },
      ),
    );
  }

  Widget _solRecursItem(BuildContext context, SolRecursDraft sr, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(sr.recurs.nom),
        subtitle: Text(
          'Quantitat: ${sr.quantitat} ${sr.recurs.unitat}\nNecessitat: ${_fmtDate(sr.dataNecessitat)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _solRecursos.removeAt(index)),
        ),
        onTap: () async {
          final edited = await showDialog<SolRecursDraft>(
            context: context,
            builder: (ctx) => SolRecursDialog(recursos: _recursos, initial: sr),
          );
          if (edited != null) setState(() => _solRecursos[index] = edited);
        },
      ),
    );
  }

  Widget _documentItem(BuildContext context, DocumentDraft d, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(d.nom),
        subtitle: Text(
          'Format: ${d.format} · Mida: ${d.mida.toStringAsFixed(2)} MB',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _documents.removeAt(index)),
        ),
      ),
    );
  }
}

//==================== MODELS AUXILIARS (Client-side drafts) ====================
class UsuariOption {
  final int id;
  final String nom;
  final String cognoms;
  UsuariOption({required this.id, required this.nom, required this.cognoms});
  String get nomComplet => '$nom $cognoms'.trim();
}

class RecursOption {
  final int id;
  final String nom;
  final String unitat;
  RecursOption({required this.id, required this.nom, required this.unitat});
}

class TascaDraft {
  final String descripcio;
  final DateTime dataInici;
  final DateTime? dataFi;
  final int prioritat; // 1-5
  final bool visibilitat;
  TascaDraft({
    required this.descripcio,
    required this.dataInici,
    this.dataFi,
    required this.prioritat,
    required this.visibilitat,
  });
}

class SolRecursDraft {
  final RecursOption recurs;
  final int quantitat;
  final DateTime dataNecessitat;
  final String? comentari;
  final String? proveidor;
  SolRecursDraft({
    required this.recurs,
    required this.quantitat,
    required this.dataNecessitat,
    this.comentari,
    this.proveidor,
  });
}

class DocumentDraft {
  final String nom;
  final String format;
  final double mida; // MB
  final String? comentari;
  final String? tipus;
  final int? idCreador;
  final XFile? fitxer; // referència local (no s'envia en JSON aquí)
  DocumentDraft({
    required this.nom,
    required this.format,
    required this.mida,
    this.tipus,
    this.comentari,
    this.idCreador,
    this.fitxer,
  });
}

//==================== DIALOGS ====================
class TascaDialog extends StatefulWidget {
  final TascaDraft? initial;
  const TascaDialog({super.key, this.initial});

  @override
  State<TascaDialog> createState() => _TascaDialogState();
}

class _TascaDialogState extends State<TascaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  DateTime? _dIni;
  DateTime? _dFi;
  int _prioritat = 3;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _descCtrl.text = widget.initial!.descripcio;
      _dIni = widget.initial!.dataInici;
      _dFi = widget.initial!.dataFi;
      _prioritat = widget.initial!.prioritat;
      _visible = widget.initial!.visibilitat;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nova Tasca' : 'Edita Tasca'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripció *'),
                validator:
                    (v) => v == null || v.trim().isEmpty ? 'Obligatori' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              _dateTile(
                context,
                title: 'Data inici *',
                date: _dIni,
                onTap: () async {
                  final d = await _pickDate(context, _dIni);
                  if (d != null) setState(() => _dIni = d);
                },
              ),
              _dateTile(
                context,
                title: 'Data fi',
                date: _dFi,
                onTap: () async {
                  final d = await _pickDate(context, _dFi);
                  if (d != null) setState(() => _dFi = d);
                },
              ),
              const SizedBox(height: 8),
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
                      onChanged: (v) => setState(() => _prioritat = v.toInt()),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Visible'),
                value: _visible,
                onChanged: (v) => setState(() => _visible = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·la'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_dIni == null) return;
            Navigator.pop(
              context,
              TascaDraft(
                descripcio: _descCtrl.text.trim(),
                dataInici: _dIni!,
                dataFi: _dFi,
                prioritat: _prioritat,
                visibilitat: _visible,
              ),
            );
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
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

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class SolRecursDialog extends StatefulWidget {
  final List<RecursOption> recursos;
  final SolRecursDraft? initial;
  const SolRecursDialog({super.key, required this.recursos, this.initial});

  @override
  State<SolRecursDialog> createState() => _SolRecursDialogState();
}

class _SolRecursDialogState extends State<SolRecursDialog> {
  final _formKey = GlobalKey<FormState>();
  RecursOption? _recurs;
  final _quantCtrl = TextEditingController();
  DateTime? _dataNec;
  final _comentCtrl = TextEditingController();
  final _provCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _recurs = widget.initial!.recurs;
      _quantCtrl.text = widget.initial!.quantitat.toString();
      _dataNec = widget.initial!.dataNecessitat;
      _comentCtrl.text = widget.initial!.comentari ?? '';
      _provCtrl.text = widget.initial!.proveidor ?? '';
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
      title: Text(
        widget.initial == null
            ? 'Nova sol·licitud recurs'
            : 'Edita sol·licitud',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RecursOption>(
                value: _recurs,
                items:
                    widget.recursos
                        .map(
                          (r) => DropdownMenuItem(value: r, child: Text(r.nom)),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _recurs = v),
                decoration: const InputDecoration(labelText: 'Recurs *'),
                validator: (v) => v == null ? 'Obligatori' : null,
              ),
              TextFormField(
                controller: _quantCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantitat *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatori';
                  if (int.tryParse(v) == null) return 'Nombre enter';
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
              TextFormField(
                controller: _comentCtrl,
                decoration: const InputDecoration(labelText: 'Comentari'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _provCtrl,
                decoration: const InputDecoration(labelText: 'Proveïdor'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·la'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_dataNec == null) return;
            Navigator.pop(
              context,
              SolRecursDraft(
                recurs: _recurs!,
                quantitat: int.parse(_quantCtrl.text),
                dataNecessitat: _dataNec!,
                comentari: _comentCtrl.text.isEmpty ? null : _comentCtrl.text,
                proveidor: _provCtrl.text.isEmpty ? null : _provCtrl.text,
              ),
            );
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
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

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class DocumentDialog extends StatefulWidget {
  const DocumentDialog({super.key});

  @override
  State<DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<DocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _comentCtrl = TextEditingController();
  final _tipusCtrl = TextEditingController();
  XFile? _file;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _comentCtrl.dispose();
    _tipusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Afegir document'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator:
                    (v) => v == null || v.trim().isEmpty ? 'Obligatori' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tipusCtrl,
                decoration: const InputDecoration(labelText: 'Tipus'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _comentCtrl,
                decoration: const InputDecoration(labelText: 'Comentari'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text(_file?.name ?? 'Cap fitxer seleccionat'),
                onTap: _pickFile,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·la'),
        ),
        ElevatedButton(
          onPressed:  () async{
            if (!_formKey.currentState!.validate()) return;
            if (_file == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecciona un fitxer')),
              );
              return;
            }
            
            final sizeBytes = await _file!.length();
            final sizeMb = sizeBytes / (1024 * 1024);
            //ext serveix per obtenir l'extensió del fitxer
            final ext = _file!.name.contains('.') ? _file!.name.split('.').last : 'bin';//Aixo

            Navigator.pop(
              context,
              DocumentDraft(
                nom: _nomCtrl.text.trim(),
                format: ext,
                mida: sizeMb,
                comentari: _comentCtrl.text.isEmpty ? null : _comentCtrl.text,
                tipus: _tipusCtrl.text.isEmpty ? null : _tipusCtrl.text,
                fitxer: _file,
              ),
            );
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final x = await openFile(); // o openFiles() per múltiples
    if (x != null) {
      _file = x; // és un XFile
      final bytes = await x.length(); // mida en bytes
      final sizeMb = bytes / (1024 * 1024);
    }
  }
}
