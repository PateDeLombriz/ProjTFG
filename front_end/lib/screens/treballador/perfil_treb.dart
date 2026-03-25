// lib/screen/treballador/treballador_home_screen.dart
// =============================================================================
// HOME de Treballador
// -----------------------------------------------------------------------------
// Què fa
//  - Mostra un resum del treballador (nom/cognoms, rol/estat, telèfon)
//  - Mostra l'obra actual (si n'hi ha) i la llista d'obres participades
//  - Mostra les tasques assignades
//  - Mostra i permet editar permisos (lectura/escriptura/edició)
//  - Inclou refresc (pull-to-refresh) i botó de tancar sessió
//
// API (alineat amb l'esquema NOU: Treballador, no UPersona/Usuari)
//  - GET   /api/treballadors/<id>/                (si no existeix, fallback: /treballadors/ i filtrar)
//  - GET   /api/responsable_obra/?id_treballador=<id>&actiu=1  (fallback: llista completa i filtrar)
//  - GET   /api/obres/<id>/
//  - GET   /api/tasca_treballador/?id_treballador=<id>         (fallback: llista completa i filtrar)
//  - GET   /api/tasca/<id>/
//  - GET   /api/permis/
//  - GET   /api/permis_treballador/?id_treballador=<id>        (fallback: llista completa i filtrar)
//  - PUT   /api/permis_treballador/<id>/   (si existeix el detall)
//  - POST  /api/permis_treballador/
//
// Autenticació
//  - Llegeix el JWT de FlutterSecureStorage (clau: 'token') i l'envia com a Bearer
//  - Llegeix també 'subject_id' guardat al login (és l'ID del Treballador per a tipus=treballador)
//
// Notes d'implementació
//  - Tolerant amb detalls vs llistes; intenta rutes amb filtre i cau en fallback si no existeixen
//  - No usa cap model antic (UPersona/Usuari ni /u_persona/ ni /permis_usuari/)
//  - Extreu rol/estat de camps directes si existeixen o del camp 'comentaris' del Treballador
//  - Separa codi d'UI i de crides API amb helpers; maneig d'errors robust
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class TreballadorProfileScreen extends StatefulWidget {
  const TreballadorProfileScreen({super.key, required this.usuariId});
  // Nota: mantenim el nom 'usuariId' per compatibilitat amb el teu codi existent.
  // Semànticament és l'ID de Treballador.
  final int usuariId;

  @override
  State<TreballadorProfileScreen> createState() => _TreballadorProfileScreenState();
}

class _TreballadorProfileScreenState extends State<TreballadorProfileScreen> {
  // ───────────────────────── Config ─────────────────────────
  static const String baseUrl = 'http://localhost:8000/api';
  //static const _storage = FlutterSecureStorage();

  // ───────────────────────── Estat ─────────────────────────
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _treballador;      // Detall de Treballador
  Map<String, dynamic>? _obraActual;       // Detall d'Obra
  final List<Map<String, dynamic>> _tasques = [];            // Detalls de tasques
  final List<Map<String, dynamic>> _obresParticipades = [];  // Deduït de tasques

  final List<Map<String, dynamic>> _permisos = [];           // Catàleg de Permis
  final List<Map<String, dynamic>> _permisTreballador = [];  // Vinculacions del treballador

  // ───────────────────────── Cicle de vida ─────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _fetchTreballador(widget.usuariId),
        _fetchObraActual(widget.usuariId),
        _fetchTasques(widget.usuariId),
        _fetchPermisos(),
        _fetchPermisosTreballador(widget.usuariId),
      ]);
      _dedueixObres();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────────────────── Helpers HTTP ─────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await SharedPreferences.getInstance();
    final h = <String, String>{'Content-Type': 'application/json'};
    token.getString('token');
    if (token != '') 
    h['Authorization'] = 'Bearer $token';
    return h;
  }

  Uri _u(String path, [Map<String, dynamic>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    if (q == null || q.isEmpty) return uri;
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: uri.path,
      queryParameters: q.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  // ───────────────────────── Fetch Treballador ─────────────────────────
  Future<void> _fetchTreballador(int id) async {
    final headers = await _authHeaders();

    // 1) Intenta endpoint de detall
    var res = await http.get(_u('/treballadors/$id/'), headers: headers);
    if (res.statusCode == 200) {
      _treballador = jsonDecode(res.body) as Map<String, dynamic>;
      return;
    }

    // 2) Fallback: llista i filtra
    res = await http.get(_u('/treballadors/'), headers: headers);
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      _treballador = list.firstWhere((e) => e['id'] == id, orElse: () => {});
      if (_treballador == null || _treballador!.isEmpty) {
        throw Exception('No s\'ha trobat el treballador #$id');
      }
      return;
    }

    throw Exception('HTTP ${res.statusCode} carregant treballador');
  }

  // ───────────────────────── Fetch Obra actual ─────────────────────────
  Future<void> _fetchObraActual(int treballadorId) async {
    final headers = await _authHeaders();

    // 1) Intenta amb filtres
    var res = await http.get(
      _u('/responsable_obra/', {
        'id_treballador': treballadorId,
        'actiu': 1, // actiu = data_fi is null
      }),
      headers: headers,
    );

    Map<String, dynamic>? responsableActiu;

    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      if (list.isNotEmpty) responsableActiu = list.first;
    } else {
      // 2) Fallback: llista completa i filtra al client
      res = await http.get(_u('/responsable_obra/'), headers: headers);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        final meus = list.where((r) => r['id_treballador'] == treballadorId);
        final actius = meus.where((r) => r['data_fi'] == null).toList();
        if (actius.isNotEmpty) responsableActiu = actius.first;
      }
    }

    if (responsableActiu != null) {
      final obraId = responsableActiu['id_obra'];
      if (obraId != null) {
        final r2 = await http.get(_u('/obres/$obraId/'), headers: headers);
        if (r2.statusCode == 200) {
          _obraActual = jsonDecode(r2.body) as Map<String, dynamic>;
        }
      }
    }
  }

  // ───────────────────────── Fetch Tasques ─────────────────────────
  Future<void> _fetchTasques(int treballadorId) async {
    final headers = await _authHeaders();

    // 1) Intenta amb filtre
    var res = await http.get(
      _u('/tasca_treballador/', {'id_treballador': treballadorId}),
      headers: headers,
    );

    List<Map<String, dynamic>> assigns = [];

    if (res.statusCode == 200) {
      assigns = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    } else {
      // 2) Fallback: llista i filtra
      res = await http.get(_u('/tasca_treballador/'), headers: headers);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        assigns = list.where((a) => a['id_treballador'] == treballadorId).toList();
      }
    }

    _tasques.clear();
    // Per cada assignació, demana el detall de tasca
    await Future.wait(assigns.map((a) async {
      final tascaId = a['id_tasca'];
      if (tascaId == null) return;
      final rt = await http.get(_u('/tasca/$tascaId/'), headers: headers);
      if (rt.statusCode == 200) {
        final t = jsonDecode(rt.body) as Map<String, dynamic>;
        _tasques.add(t);
      }
    }));
  }

  // ───────────────────────── Fetch Permisos ─────────────────────────
  Future<void> _fetchPermisos() async {
    final headers = await _authHeaders();
    final res = await http.get(_u('/permis/'), headers: headers);
    if (res.statusCode == 200) {
      _permisos
        ..clear()
        ..addAll((jsonDecode(res.body) as List).cast<Map<String, dynamic>>());
    } else {
      throw Exception('HTTP ${res.statusCode} carregant permisos');
    }
  }

  Future<void> _fetchPermisosTreballador(int treballadorId) async {
    final headers = await _authHeaders();

    // 1) Intenta amb filtre
    var res = await http.get(
      _u('/permis_treballador/', {'id_treballador': treballadorId}),
      headers: headers,
    );

    if (res.statusCode == 200) {
      _permisTreballador
        ..clear()
        ..addAll((jsonDecode(res.body) as List).cast<Map<String, dynamic>>());
      return;
    }

    // 2) Fallback: llista i filtra
    res = await http.get(_u('/permis_treballador/'), headers: headers);
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      _permisTreballador
        ..clear()
        ..addAll(list.where((pu) {
          final v = pu['id_treballador'];
          if (v is Map) return v['id'] == treballadorId; // per si retorna objecte FK
          return v == treballadorId;                      // per si retorna l'ID
        }));
      return;
    }

    throw Exception('HTTP ${res.statusCode} carregant permisos del treballador');
  }

  // ───────────────────────── Deduir obres ─────────────────────────
  void _dedueixObres() {
    _obresParticipades.clear();
    final seen = <int>{};
    for (final t in _tasques) {
      final obra = t['obra'];
      if (obra is Map) {
        final id = obra['id'] is int ? obra['id'] as int : int.tryParse('${obra['id']}');
        if (id != null && !seen.contains(id)) {
          seen.add(id);
          _obresParticipades.add(obra.cast<String, dynamic>());
        }
      }
    }
  }

  // ───────────────────────── Guardar permís ─────────────────────────
  Future<void> _savePermisRow(_PermisRow row) async {
    final headers = await _authHeaders();

    // Existeix ja una fila per aquest permís?
    final existent = _permisTreballador.firstWhere(
      (pu) {
        final idPerm = pu['id_permis'];
        final pid = idPerm is Map ? idPerm['id'] : idPerm;
        return pid == row.idPermis;
      },
      orElse: () => {},
    );

    final payload = jsonEncode({
      'id_treballador': widget.usuariId,
      'id_permis': row.idPermis,
      'lectura': row.lectura,
      'escriptura': row.escriptura,
      'edicio': row.edicio,
    });

    http.Response res;

    if (existent.isNotEmpty && existent['id'] != null) {
      final id = existent['id'];
      // Intentem PUT al detall
      res = await http.put(_u('/permis_treballador/$id/'), headers: headers, body: payload);
      if (res.statusCode == 404) {
        // Fallback a POST
        res = await http.post(_u('/permis_treballador/'), headers: headers, body: payload);
      }
    } else {
      res = await http.post(_u('/permis_treballador/'), headers: headers, body: payload);
    }

    if (!mounted) return;

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permís actualitzat')));
      await _fetchPermisosTreballador(widget.usuariId);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error (${res.statusCode}): ${res.body}')),
      );
    }
  }

  // ───────────────────────── Helpers de presentació ─────────────────────────
  String? _fromComentaris(String key) {
    final c = _treballador?['comentaris']?.toString() ?? '';
    if (c.isEmpty) return null;
    final re = RegExp('(^|;)\\s*' + RegExp.escape(key) + '\\s*=\\s*([^;]+)');
    final m = re.firstMatch(c);
    return m != null ? m.group(2)?.trim() : null;
  }

  String get _nom => _treballador?['nom']?.toString() ?? '';
  String get _cognoms => _treballador?['cognoms']?.toString() ?? '';
  String get _telefon => _treballador?['telefon']?.toString() ?? '';
  String get _rol => _treballador?['carrec']?.toString() // si algun dia exposeu ContracteTreballador
      ?? _treballador?['categoria_professional']?.toString()
      ?? _fromComentaris('rol')
      ?? '—';
  String get _estat => _fromComentaris('estat')?.toLowerCase() ?? '—';

  Color _estatColor(String s) {
    switch (s.toLowerCase()) {
      case 'actiu':
        return Colors.green;
      case 'baixa':
      case 'inactiu':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Future<void> _logout() async {
    final SharedPreferences token = await SharedPreferences.getInstance();
    await token.remove('token');

    await token.remove('subject_id');
    await token.remove('tipus');
    
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // ───────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inici'),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadAll)
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(
                        nom: _nom.isEmpty ? '—' : _nom,
                        cognoms: _cognoms,
                        rol: _rol,
                        estat: _estat,
                        telefon: _telefon.isEmpty ? null : _telefon,
                        colorEstat: _estatColor(_estat),
                      ),

                      const SizedBox(height: 16),
                      const _SectionTitle('Obra actual'),
                      if (_obraActual == null)
                        const _MutedText('No assignada actualment')
                      else
                        _ObraCard(obra: _obraActual!),

                      const SizedBox(height: 16),
                      const _SectionTitle('Obres en què he participat'),
                      if (_obresParticipades.isEmpty)
                        const _MutedText('Cap obra registrada')
                      else
                        ..._obresParticipades.map((o) => _ObraListTile(obra: o)).toList(),

                      const SizedBox(height: 16),
                      const _SectionTitle('Tasques assignades'),
                      if (_tasques.isEmpty)
                        const _MutedText('No hi ha tasques')
                      else
                        ..._tasques.map((t) => _TascaTile(tasca: t)).toList(),

                      const SizedBox(height: 16),
                      _PermisosPanel(
                        permisos: _permisos,
                        permisosTreballador: _permisTreballador,
                        onSave: _savePermisRow,
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'ID Treballador: ${widget.usuariId}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ───────────────────────── Widgets auxiliars ─────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.nom,
    required this.cognoms,
    required this.rol,
    required this.estat,
    required this.telefon,
    required this.colorEstat,
  });
  final String nom;
  final String cognoms;
  final String rol;
  final String estat;
  final String? telefon;
  final Color colorEstat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fullName = ('$nom ${cognoms.trim()}').trim();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 28, backgroundColor: scheme.primaryContainer, child: const Icon(Icons.person)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fullName.isEmpty ? '—' : fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text(rol, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip('Estat: $estat', colorEstat),
                  if (telefon != null) _chip('Tel: $telefon', scheme.primary),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
}

class _ObraCard extends StatelessWidget {
  const _ObraCard({required this.obra});
  final Map<String, dynamic> obra;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.house_siding_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(obra['nom']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(obra['ubicacio']?.toString() ?? 'Sense ubicació', style: TextStyle(color: scheme.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ObraListTile extends StatelessWidget {
  const _ObraListTile({required this.obra});
  final Map<String, dynamic> obra;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: .6),
      ),
      child: Row(children: [
        Icon(Icons.business_outlined, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(obra['nom']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(obra['ubicacio']?.toString() ?? '—', style: TextStyle(color: scheme.onSurfaceVariant)),
          ]),
        )
      ]),
    );
  }
}

class _TascaTile extends StatelessWidget {
  const _TascaTile({required this.tasca});
  final Map<String, dynamic> tasca;

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Color _priorityColor(int? p) {
    switch (p) {
      case 5:
      case 4:
        return Colors.redAccent;
      case 3:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = tasca['prioritat'] as int?;
    final color = _priorityColor(p);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.task_alt_outlined, color: scheme.primary),
        title: Text(tasca['descripcio']?.toString() ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('Inici: ${_fmt(tasca['data_inici'])} · Fi: ${_fmt(tasca['data_fi'])}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text('P${p ?? '-'}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _PermisosPanel extends StatefulWidget {
  const _PermisosPanel({
    required this.permisos,
    required this.permisosTreballador,
    required this.onSave,
  });
  final List<Map<String, dynamic>> permisos;
  final List<Map<String, dynamic>> permisosTreballador;
  final Future<void> Function(_PermisRow row) onSave;

  @override
  State<_PermisosPanel> createState() => _PermisosPanelState();
}

class _PermisosPanelState extends State<_PermisosPanel> {
  final Map<int, _PermisRow> _rows = {}; // id_permis -> row

  @override
  void initState() {
    super.initState();
    _rebuildRows();
  }

  @override
  void didUpdateWidget(covariant _PermisosPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildRows();
  }

  void _rebuildRows() {
    _rows.clear();
    final byPerm = <int, Map<String, dynamic>>{}; // id_permis -> vincle
    for (final pu in widget.permisosTreballador) {
      final idPermis = pu['id_permis'] is Map ? pu['id_permis']['id'] as int : pu['id_permis'] as int;
      byPerm[idPermis] = pu;
    }
    for (final p in widget.permisos) {
      final id = p['id'] as int;
      final pu = byPerm[id];
      _rows[id] = _PermisRow(
        idPermis: id,
        clau: p['clau_funcional']?.toString() ?? '',
        descripcio: p['descripcio']?.toString() ?? '',
        lectura: (pu?['lectura'] ?? false) as bool,
        escriptura: (pu?['escriptura'] ?? false) as bool,
        edicio: (pu?['edicio'] ?? false) as bool,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Permisos'),
        if (_rows.isEmpty)
          const _MutedText('Sense permisos definits')
        else
          ..._rows.values.map((row) => Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant, width: .6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.clau, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(row.descripcio, style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Lectura'),
                          value: row.lectura,
                          onChanged: (v) => setState(() => row.lectura = v ?? false),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Escriptura'),
                          value: row.escriptura,
                          onChanged: (v) => setState(() => row.escriptura = v ?? false),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Edició'),
                          value: row.edicio,
                          onChanged: (v) => setState(() => row.edicio = v ?? false),
                        ),
                      ),
                    ]),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => widget.onSave(row),
                        icon: const Icon(Icons.save),
                        label: const Text('Desa'),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

class _PermisRow {
  _PermisRow({
    required this.idPermis,
    required this.clau,
    required this.descripcio,
    required this.lectura,
    required this.escriptura,
    required this.edicio,
  });
  final int idPermis;
  String clau;
  String descripcio;
  bool lectura;
  bool escriptura;
  bool edicio;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: 16),
          const Text("S'ha produït un error", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Torna-ho a intentar')),
        ]),
      ),
    );
  }
}
