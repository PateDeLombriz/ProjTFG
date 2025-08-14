// treballador_profile_screen_v2.dart
// Perfil de Treballador
// -----------------------------------------------------------------------------
// Usa únicament endpoints que ja tens a views_api_full.py. Quan no hi ha
// filtres al backend, es fa filtratge al client. Si després exposes filtres
// (id_treballador, actiu, etc.), només caldrà simplificar crides.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TreballadorProfileScreen extends StatefulWidget {
  const TreballadorProfileScreen({super.key, required this.usuariId});
  final int usuariId;

  @override
  State<TreballadorProfileScreen> createState() => _TreballadorProfileScreenState();
}

class _TreballadorProfileScreenState extends State<TreballadorProfileScreen> {
  static const String baseUrl = 'http://localhost:8000/api';

  Map<String, dynamic>? _usuari;     // fila d'Usuari
  Map<String, dynamic>? _persona;    // fila d'UPersona (nom, cognoms, rol, estat)
  Map<String, dynamic>? _obraActual; // Responsable amb data_fi null

  List<Map<String, dynamic>> _tasques = [];          // Tasques detallades
  List<Map<String, dynamic>> _obresParticipades = []; // Deduïdes de tasques + responsables

  List<Map<String, dynamic>> _permisos = [];         // /permis/
  List<Map<String, dynamic>> _permisUsuari = [];     // /permis_usuari/

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Future.wait([
        _fetchUsuari(),
        _fetchPersones(),
        _fetchTasquesDetallPerTreballador(),
        _fetchResponsablesObra(),
        _fetchPermisos(),
        _fetchPermisosUsuari(),
      ]);
      _dedueixObres();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- API helpers ----------------
  Future<void> _fetchUsuari() async {
    // No tens /usuaris/<id>/, però tens /usuaris/ amb possible filtre per tipus.
    final res = await http.get(Uri.parse('$baseUrl/usuaris/'));
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      _usuari = list.firstWhere((u) => u['id'] == widget.usuariId, orElse: () => {});
    } else {
      throw Exception('HTTP ${res.statusCode} carregant usuaris');
    }
  }

  Future<void> _fetchPersones() async {
    final res = await http.get(Uri.parse('$baseUrl/usuaris/')); // tenim també UPersonaList, però sense filtre
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode} carregant usuaris');

    // Necessitem també /u_persona/ (llista) per trobar la del nostre usuari
    final resPers = await http.get(Uri.parse('$baseUrl/u_persona/'));
    if (resPers.statusCode == 200) {
      final list = (jsonDecode(resPers.body) as List).cast<Map<String, dynamic>>();
      _persona = list.firstWhere(
        (p) => p['usuari'] == widget.usuariId,
        orElse: () => {},
      );
    } else {
      throw Exception('HTTP ${resPers.statusCode} carregant u_persona');
    }
  }

  Future<void> _fetchTasquesDetallPerTreballador() async {
    // 1) agafem totes les assignacions N:M
    final resAssign = await http.get(Uri.parse('$baseUrl/tasca_treballador/'));
    if (resAssign.statusCode != 200) throw Exception('HTTP ${resAssign.statusCode} carregant tasca_treballador');
    final assigns = (jsonDecode(resAssign.body) as List).cast<Map<String, dynamic>>();
    final meAssigns = assigns.where((a) => a['id_treballador'] == widget.usuariId).toList();

    // 2) per cada assignació, demana el detall de la tasca per obtenir obra, incidències i solucions
    _tasques.clear();
    await Future.wait(meAssigns.map((a) async {
      final tascaId = a['id_tasca'];
      final resT = await http.get(Uri.parse('$baseUrl/tasca/$tascaId/'));
      if (resT.statusCode == 200) {
        final t = jsonDecode(resT.body) as Map<String, dynamic>;
        _tasques.add(t);
      }
    }));
  }

  Future<void> _fetchResponsablesObra() async {
    // Sense filtres al backend: agafem tots i filtrem client-side
    final res = await http.get(Uri.parse('$baseUrl/responsable_obra/'));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode} carregant responsable_obra');
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    final meus = list.where((r) => r['id_treballador'] == widget.usuariId).toList();

    // obra actual: data_fi null
    final actius = meus.where((r) => r['data_fi'] == null).toList();
    if (actius.isNotEmpty) {
      // tenim id_obra (num). Demana detall d'obra per mostrar-la bé.
      final obraId = actius.first['id_obra'];
      if (obraId != null) {
        final resO = await http.get(Uri.parse('$baseUrl/obres/$obraId/'));
        if (resO.statusCode == 200) {
          _obraActual = jsonDecode(resO.body) as Map<String, dynamic>;
        }
      }
    }
  }

  Future<void> _fetchPermisos() async {
    final res = await http.get(Uri.parse('$baseUrl/permis/'));
    if (res.statusCode == 200) {
      _permisos = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('HTTP ${res.statusCode} carregant permisos');
    }
  }

  Future<void> _fetchPermisosUsuari() async {
    final res = await http.get(Uri.parse('$baseUrl/permis_usuari/'));
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      _permisUsuari = list.where((pu) => pu['id_usuari'] == widget.usuariId).toList();
    } else {
      throw Exception('HTTP ${res.statusCode} carregant permisos d\'usuari');
    }
  }

  void _dedueixObres() {
    final seen = <int>{};
    _obresParticipades.clear();

    // de les tasques
    for (final t in _tasques) {
      final obra = t['obra']; // el TasquesDetail afegeix 'obra'
      if (obra is Map) {
        final id = obra['id'] as int?;
        if (id != null && !seen.contains(id)) {
          seen.add(id);
          _obresParticipades.add(obra.cast<String, dynamic>());
        }
      }
    }

    // de responsables (si hem carregat obra actual ja la tenim; si vols totes, caldria
    // demanar totes les obres de la llista meus i afegir-les també)
  }

  // ---------------- Guardar permisos ----------------
  Future<void> _savePermisRow(_PermisRow row) async {
    final mapExist = _permisUsuari.firstWhere(
      (pu) => (pu['id_permis'] == row.idPermis),
      orElse: () => {},
    );

    final payload = {
      'id_usuari': widget.usuariId,
      'id_permis': row.idPermis,
      'lectura': row.lectura,
      'escriptura': row.escriptura,
      'edicio': row.edicio,
      // dates no calen, DB les pot omplir
    };

    try {
      http.Response res;
      if (mapExist.isNotEmpty && mapExist['id'] != null) {
        final id = mapExist['id'];
        // Prova PUT al detall (necessitaràs mapejar al urls.py): /permis_usuari/<id>/
        res = await http.put(
          Uri.parse('$baseUrl/permis_usuari/$id/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (res.statusCode == 404) {
          // Si no tens el detall implementat, fem POST com a fallback
          res = await http.post(
            Uri.parse('$baseUrl/permis_usuari/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );
        }
      } else {
        res = await http.post(
          Uri.parse('$baseUrl/permis_usuari/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permís actualitzat')));
        await _fetchPermisosUsuari();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error (${res.statusCode}): ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de connexió: $e')),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Treballador'),
        actions: [IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh))],
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
                        nom: _persona?['nom'] ?? '—',
                        cognoms: _persona?['cognoms'] ?? '',
                        rol: _persona?['rol'] ?? '—',
                        estat: _persona?['estat'] ?? '—',
                        telefon: _usuari?['telefon']?.toString(),
                      ),

                      const SizedBox(height: 16),
                      const _SectionTitle('Obra actual'),
                      if (_obraActual == null)
                        _MutedText('No assignada actualment')
                      else
                        _ObraCard(obra: _obraActual!),

                      const SizedBox(height: 16),
                      const _SectionTitle('Obres en què ha participat'),
                      if (_obresParticipades.isEmpty)
                        _MutedText('Cap obra registrada')
                      else
                        ..._obresParticipades.map((o) => _ObraListTile(obra: o)).toList(),

                      const SizedBox(height: 16),
                      const _SectionTitle('Tasques encomanades'),
                      if (_tasques.isEmpty)
                        _MutedText('No hi ha tasques')
                      else
                        ..._tasques.map((t) => _TascaTile(tasca: t)).toList(),

                      const SizedBox(height: 16),
                      const _SectionTitle('Permisos'),
                      _PermisosTable(
                        permisos: _permisos,
                        permisosUsuari: _permisUsuari,
                        onSave: _savePermisRow,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

// ---------------- Widgets auxiliars ----------------
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.nom,
    required this.cognoms,
    required this.rol,
    required this.estat,
    required this.telefon,
  });
  final String nom;
  final String cognoms;
  final String rol;
  final String estat;
  final String? telefon;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fullName = '$nom ${cognoms.trim()}'.trim();
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
                  _chip('Estat: $estat', _estatColor(estat)),
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

class _PermisosTable extends StatefulWidget {
  const _PermisosTable({required this.permisos, required this.permisosUsuari, required this.onSave});
  final List<Map<String, dynamic>> permisos;
  final List<Map<String, dynamic>> permisosUsuari;
  final Future<void> Function(_PermisRow row) onSave;

  @override
  State<_PermisosTable> createState() => _PermisosTableState();
}

class _PermisosTableState extends State<_PermisosTable> {
  final Map<int, _PermisRow> _rows = {}; // id_permis -> row

  @override
  void initState() {
    super.initState();
    _rebuildRows();
  }

  @override
  void didUpdateWidget(covariant _PermisosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildRows();
  }

  void _rebuildRows() {
    _rows.clear();
    final userByPerm = <int, Map<String, dynamic>>{};
    for (final pu in widget.permisosUsuari) {
      final idPermis = pu['id_permis'] is Map ? pu['id_permis']['id'] as int : pu['id_permis'] as int;
      userByPerm[idPermis] = pu;
    }
    for (final p in widget.permisos) {
      final id = p['id'] as int;
      final pu = userByPerm[id];
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
    if (_rows.isEmpty) {
      return _MutedText('Sense permisos definits');
    }
    return Column(
      children: [
        for (final row in _rows.values)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant, width: .6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            ]),
          ),
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
