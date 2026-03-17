// lib/screens/treballador/treballador_form.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
/// TreballadorForm
/// Pantalla per crear un Treballador, crear el seu Contracte lligat a l'empresa
/// loguejada (extreta del JWT) i (opcionalment) assignar permisos amb flags.
/// Estètica alineada amb la guia: Material 3, surfaceVariant, cards/xips, etc.
/// ─────────────────────────────────────────────────────────────────────────────
class TreballadorForm extends StatefulWidget {
  const TreballadorForm({super.key});

  @override
  State<TreballadorForm> createState() => _TreballadorFormState();
}

class _TreballadorFormState extends State<TreballadorForm> {
  //==================== CONFIG/API ====================
  late final String _baseApi =
      kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';

  // TODO(auth): Obtenir el token real de login (p.ex. FlutterSecureStorage)
  Future<String?> _readToken() async {
    // return await storage.read(key: 'jwt');
    return null;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  //==================== FORM STATE ====================
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _cognomsCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _comentCtrl = TextEditingController();
  DateTime? _dataNaix;

  // ContracteTreballador
  DateTime? _dataContracte;
  DateTime? _dataFiContracte;
  final _carrecCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _nssCtrl = TextEditingController();
  final _salariCtrl = TextEditingController();
  String _estatTreballador = 'actiu'; // actiu | baixa | acomiadat

  bool _saving = false;

  //==================== PERMISOS (opcions + selecció) ====================
  List<_Permis> _permisos = [];
  final Map<int, _PermisSelection> _seleccioPermis = {}; // id_permis -> flags

  @override
  void initState() {
    super.initState();
    _loadPermisos();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _cognomsCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    _nickCtrl.dispose();
    _comentCtrl.dispose();

    _carrecCtrl.dispose();
    _categoriaCtrl.dispose();
    _nssCtrl.dispose();
    _salariCtrl.dispose();
    super.dispose();
  }

  //==================== LOAD DATA ====================
  Future<void> _loadPermisos() async {
    try {
      final token = await _readToken();
      final res =
          await http.get(Uri.parse('$_baseApi/permis/'), headers: _headers(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _permisos = data.map((e) => _Permis.fromJson(e)).toList();
        });
      } else {
        _snack('No s\'han pogut carregar permisos (${res.statusCode})');
      }
    } catch (e) {
      _snack('Error carregant permisos: $e');
    }
  }

  //==================== JWT: extreure id d'empresa ====================
  Future<int?> _empresaIdFromToken() async {
    final token = await _readToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payloadB64 = parts[1]
          .replaceAll('-', '+')
          .replaceAll('_', '/')
          .padRight((parts[1].length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(payloadB64));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      if (map['tipus'] == 'empresa') {
        final sub = map['sub'];
        if (sub is int) return sub;
        if (sub is String) return int.tryParse(sub);
      }
    } catch (_) {}
    return null;
  }

  //==================== SUBMIT ====================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataContracte == null) {
      _snack('⚠️ Selecciona la data de contracte');
      return;
    }

    if (_dataNaix == null) {
      final ok = await _confirmDialog(
        title: 'Sense data de naixement',
        text: 'Vols continuar sense indicar la data de naixement?',
      );
      if (ok != true) return;
    }

    setState(() => _saving = true);

    try {
      final token = await _readToken();

      // 1) Crear Treballador
      final treId = await _createTreballador(token);

      // 2) Crear Contracte lligat a l'empresa del JWT
      final empresaId = await _empresaIdFromToken();
      if (empresaId == null) {
        throw Exception('No s\'ha pogut identificar l\'empresa del JWT');
      }
      await _createContracteTreballador(token, treId, empresaId);

      // 3) Assignar permisos seleccionats (opcional)
      if (_seleccioPermis.isNotEmpty) {
        await _assignarPermisos(token, treId);
      }

      if (mounted) {
        _snack('✅ Treballador creat correctament', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('❌ Error durant el desament: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<int> _createTreballador(String? token) async {
    final payload = {
      'nom': _nomCtrl.text.trim(),
      'cognoms': _cognomsCtrl.text.trim(),
      'nickname': _nickCtrl.text.trim().isEmpty ? null : _nickCtrl.text.trim(),
      'dni_nie_passaport': _dniCtrl.text.trim(),
      'data_naixement': _dataNaix != null ? _fmtDate(_dataNaix!) : null,
      'telefon':
          _telefonCtrl.text.trim().isEmpty ? null : _telefonCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'comentaris':
          _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
      // 'foto': (si cal, via multipart)
    };

    final res = await http.post(
      Uri.parse('$_baseApi/treballadors/'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final id = (map['id'] ?? map['pk']) as int?;
      if (id == null) {
        throw Exception('Resposta sense id de treballador');
      }
      return id;
    } else {
      throw Exception('Crear Treballador -> ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _createContracteTreballador(
      String? token, int idTreballador, int idEmpresa) async {
    final payload = {
      'id_treballador': idTreballador,
      'id_empresa': idEmpresa,
      'data_contracte': _fmtDate(_dataContracte!),
      'data_fi':
          _dataFiContracte != null ? _fmtDate(_dataFiContracte!) : null,
      'salari': _salariCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_salariCtrl.text.replaceAll(',', '.')),
      'carrec':
          _carrecCtrl.text.trim().isEmpty ? null : _carrecCtrl.text.trim(),
      'categoria_professional': _categoriaCtrl.text.trim().isEmpty
          ? null
          : _categoriaCtrl.text.trim(),
      'nss': _nssCtrl.text.trim().isEmpty ? null : _nssCtrl.text.trim(),
      'estat': _estatTreballador, // 'actiu' | 'baixa' | 'acomiadat'
    };

    // TODO(backend): confirma el path exacte a urls.py (p.ex. contracte_treballador/)
    final res = await http.post(
      Uri.parse('$_baseApi/contracte_treballador/'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
          'Crear ContracteTreballador -> ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _assignarPermisos(String? token, int idTreballador) async {
    for (final entry in _seleccioPermis.entries) {
      final idPermis = entry.key;
      final sel = entry.value;

      final payload = {
        'id_treballador': idTreballador,
        'id_permis': idPermis,
        'lectura': sel.lectura,
        'escriptura': sel.escriptura,
        'edicio': sel.edicio,
      };

      final res = await http.post(
        Uri.parse('$_baseApi/permis_treballador/'),
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception(
            'Assignar permís($idPermis) -> ${res.statusCode}: ${res.body}');
      }
    }
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

  Future<bool?> _confirmDialog({required String title, required String text}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel·la')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continua')),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2100),
    );
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: scheme.surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _gap([double h = 12]) => SizedBox(height: h);

  //==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nou Treballador')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Dades bàsiques
                  const Text('Dades bàsiques',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _gap(8),
                  TextFormField(
                    controller: _nomCtrl,
                    decoration: _dec('Nom *', icon: Icons.person_outline),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatori' : null,
                  ),
                  _gap(),
                  TextFormField(
                    controller: _cognomsCtrl,
                    decoration: _dec('Cognoms *', icon: Icons.badge_outlined),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatori' : null,
                  ),
                  _gap(),
                  TextFormField(
                    controller: _dniCtrl,
                    decoration:
                        _dec('DNI/NIE/Passaport *', icon: Icons.credit_card),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatori' : null,
                  ),
                  _gap(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data de naixement'),
                    subtitle: Text(_dataNaix == null
                        ? 'Selecciona una data'
                        : _fmtDate(_dataNaix!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await _pickDate(_dataNaix);
                      if (d != null) setState(() => _dataNaix = d);
                    },
                  ),

                  const Divider(height: 32),

                  // ── Contacte
                  const Text('Contacte',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _gap(8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Email', icon: Icons.email_outlined),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _telefonCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dec('Telèfon', icon: Icons.phone_outlined),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _nickCtrl,
                    decoration: _dec('Àlies / Nickname', icon: Icons.tag),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _comentCtrl,
                    maxLines: 3,
                    decoration: _dec('Comentaris', icon: Icons.notes_outlined),
                  ),

                  const Divider(height: 32),

                  // ── Contracte amb l'empresa
                  const Text('Contracte amb l\'empresa',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _gap(8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data de contracte *'),
                    subtitle: Text(_dataContracte == null
                        ? 'Selecciona una data'
                        : _fmtDate(_dataContracte!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await _pickDate(_dataContracte);
                      if (d != null) setState(() => _dataContracte = d);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data fi (opcional)'),
                    subtitle: Text(_dataFiContracte == null
                        ? '—'
                        : _fmtDate(_dataFiContracte!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await _pickDate(_dataFiContracte);
                      if (d != null) setState(() => _dataFiContracte = d);
                    },
                  ),
                  _gap(),
                  TextFormField(
                    controller: _carrecCtrl,
                    decoration: _dec('Càrrec', icon: Icons.work_outline),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _categoriaCtrl,
                    decoration: _dec('Categoria professional'),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _nssCtrl,
                    decoration: _dec('NSS'),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _salariCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Salari (€)'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final val = double.tryParse(v.replaceAll(',', '.'));
                      if (val == null) return 'Número invàlid';
                      return null;
                    },
                  ),
                  _gap(),
                  DropdownButtonFormField<String>(
                    value: _estatTreballador,
                    decoration:
                        _dec('Estat del treballador *', icon: Icons.flag_outlined),
                    items: const [
                      DropdownMenuItem(value: 'actiu', child: Text('Actiu')),
                      DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
                      DropdownMenuItem(
                          value: 'acomiadat', child: Text('Acomiadat')),
                    ],
                    onChanged: (v) =>
                        setState(() => _estatTreballador = v ?? 'actiu'),
                  ),

                  const Divider(height: 32),

                  // ── Permisos (opcional)
                  _permisosSection(scheme),

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
    );
  }

  //==================== PERMISOS SECTION ====================
  Widget _permisosSection(ColorScheme scheme) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Permisos (opcional)'),
      subtitle: const Text('Selecciona permisos i marca els privilegis'),
      children: [
        if (_permisos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Sense permisos disponibles',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          )
        else
          Column(
            children: _permisos.map((p) => _permRow(p, scheme)).toList(),
          ),
      ],
    );
  }

  Widget _permRow(_Permis p, ColorScheme scheme) {
    final sel = _seleccioPermis[p.id];
    final selected = sel != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_open),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.clauFuncional,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: selected,
                  onChanged: (on) {
                    setState(() {
                      if (on) {
                        _seleccioPermis[p.id] = _PermisSelection();
                      } else {
                        _seleccioPermis.remove(p.id);
                      }
                    });
                  },
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _flagChip(
                    label: 'Lectura',
                    value: sel.lectura,
                    onChanged: (v) => setState(
                        () => _seleccioPermis[p.id] = sel.copyWith(lectura: v)),
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _flagChip(
                    label: 'Escriptura',
                    value: sel.escriptura,
                    onChanged: (v) => setState(() =>
                        _seleccioPermis[p.id] = sel.copyWith(escriptura: v)),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _flagChip(
                    label: 'Edició',
                    value: sel.edicio,
                    onChanged: (v) => setState(
                        () => _seleccioPermis[p.id] = sel.copyWith(edicio: v)),
                    color: Colors.green,
                  ),
                ],
              ),
              if (p.descripcio != null && p.descripcio!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.descripcio!,
                    style:
                        TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ]
          ],
        ),
      ),
    );
  }

  Widget _flagChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(value ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

//==================== MODELS/HELPERS (local) ====================
class _Permis {
  final int id;
  final String clauFuncional;
  final String? descripcio;

  _Permis({required this.id, required this.clauFuncional, this.descripcio});

  factory _Permis.fromJson(Map<String, dynamic> j) {
    return _Permis(
      id: j['id'] as int,
      clauFuncional:
          (j['clau_funcional'] ?? j['clauFuncional'] ?? '').toString(),
      descripcio:
          (j['descripcio'] ?? j['descripcion'] ?? j['description'])?.toString(),
    );
    }
}

class _PermisSelection {
  final bool lectura;
  final bool escriptura;
  final bool edicio;

  _PermisSelection(
      {this.lectura = false, this.escriptura = false, this.edicio = false});

  _PermisSelection copyWith({bool? lectura, bool? escriptura, bool? edicio}) {
    return _PermisSelection(
      lectura: lectura ?? this.lectura,
      escriptura: escriptura ?? this.escriptura,
      edicio: edicio ?? this.edicio,
    );
  }
}
