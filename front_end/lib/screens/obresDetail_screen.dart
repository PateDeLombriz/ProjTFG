import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:front_end/screens/obra_edit.dart';
import 'package:front_end/screens/empresa/inc_sol_form.dart';
import 'package:front_end/screens/floating_forms.dart';
import 'package:front_end/screens/empresa/tasca_form.dart';
import 'package:front_end/screens/empresa/solicRec_form.dart';
import 'package:front_end/screens/empresa/doc_form.dart';

/// Vista de **Perfil d'Obra** amb estètica alineada amb la nova UI.
/// Inclou:
/// - Resum estadístic (incidències, tasques, documents, recursos sol·licitats)
/// - ExpansionTiles estilitzades amb targetes internes
/// - RefreshIndicator per tornar a carregar dades
/// - Accions d'editar / eliminar (amb confirmació) i menú flotant per afegir
class ObraProfileScreen extends StatefulWidget {
  final Map<String, dynamic> obra;
  const ObraProfileScreen({super.key, required this.obra});

  @override
  State<ObraProfileScreen> createState() => _ObraProfileScreenState();
}

class _ObraProfileScreenState extends State<ObraProfileScreen> {
  static const _baseUrl = 'http://localhost:8000/api';

  Map<String, dynamic> _obra = {};
  List<dynamic> _incidencies = [];
  List<dynamic> _tasques = [];
  List<dynamic> _documents = [];
  List<dynamic> _solRec = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _obra = {...widget.obra};
    _fetchDetails();
  }

  //──────────────────── API ────────────────────
  Future<void> _fetchDetails() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/obres/${_obra['id']}/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _obra = data;
          _incidencies = data['incidencies'] ?? [];
          _tasques = data['tasques'] ?? [];
          _documents = data['documents'] ?? [];
          _solRec = data['sol_recursos'] ?? [];
        });
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteObra() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar obra'),
            content: const Text('Acció irreversible. Vols continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel·la'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/obres/${_obra['id']}/'),
      );
      if (res.statusCode == 204) {
        _snack('Obra eliminada', success: true);
        Navigator.pop(context, true);
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  //──────────────────── UI ─────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_obra['nom'] ?? 'Obra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ObraEditScreen(obra: _obra)),
              );
              if (updated != null) _fetchDetails();
            },
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteObra),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchDetails,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatsHeader(
                      incidencies: _incidencies.length,
                      tasques: _tasques.length,
                      docs: _documents.length,
                      resources: _solRec.length,
                    ),
                    const SizedBox(height: 20),
                    _infoTiles(scheme),
                    const SizedBox(height: 20),
                    _sectionTitle('Incidències', _showIncidenciaForm),
                    _expansion(
                      _incidencies,
                      (inc) => _IncidenciaCard(incidencia: inc),
                    ),

                    _sectionTitle('Tasques', _showTascaForm),
                    _expansion(_tasques, (t) => _TascaCardMini(tasca: t)),

                    _sectionTitle('Documents', _showDocumentForm),
                    _expansion(_documents, (d) => _DocCardMini(doc: d)),

                    _sectionTitle('Sol·licituds de Recurs', _showSolRecForm),
                    _expansion(_solRec, (s) => _SolRecCardMini(item: s)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  //──────────────────────── Helpers UI ─────────────────────────

  Widget _sectionTitle(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAdd,
          tooltip: 'Afegir $title',
        ),
      ],
    );
  }
  void _showDocumentForm() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DocumentForm(idObra: _obra['id']);
    },
  );
}

void _showSolRecForm() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SolRecForm(idObra: _obra['id']);
    },
  );
}


  void _showIncidenciaForm() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return IncidenciaForm(idObra: _obra['id']);
    },
  );
}

void _showTascaForm() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return TascaForm(idObra: _obra['id']);
    },
  );
}


  Widget _infoTiles(ColorScheme scheme) {
    Widget _tile(String label, dynamic value) => ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value?.toString() ?? '—'),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _tile('Ubicació', _obra['ubicacio']),
          _tile('Data Inici', _obra['data_inici']),
          _tile('Data Prev. Fi', _obra['data_prev_fi']),
          _tile(
            'Pressupost',
            _obra['pressupost'] != null ? '€${_obra['pressupost']}' : '—',
          ),
          _tile('Estat', _obra['estat']),
          ListTile(
            dense: true,
            title: const Text(
              'Descripció',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_obra['descripcio'] ?? '—'),
          ),
        ],
      ),
    );
  }


  Widget _expansion(
    List<dynamic> list,
    Widget Function(Map<String, dynamic>) builder,
  ) {
    if (list.isEmpty) {
      return const Text('No hi ha dades', style: TextStyle(color: Colors.grey));
    }
    // Garanteix que el resultat és List<Widget>
    final widgets = list
        .map<Widget>((e) => builder(e as Map<String, dynamic>))
        .toList(growable: false);

    return Column(children: widgets);
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }
}

//──────────────────── Header estadístic ────────────────────
class _StatsHeader extends StatelessWidget {
  final int incidencies;
  final int tasques;
  final int docs;
  final int resources;
  const _StatsHeader({
    required this.incidencies,
    required this.tasques,
    required this.docs,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Card _stat(String lbl, int val, IconData icon, Color c) => Card(
      color: c,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 90,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.onPrimary),
            const SizedBox(height: 4),
            Text(
              '$val',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              lbl,
              style: TextStyle(
                color: scheme.onPrimary.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _stat('Incid.', incidencies, Icons.warning_amber, Colors.orange),
          _stat('Tasques', tasques, Icons.task_alt, scheme.primary),
          _stat('Docs', docs, Icons.description, Colors.teal),
          _stat('Sol·Rec', resources, Icons.inventory_2, Colors.purple),
        ],
      ),
    );
  }
}

//──────────────────── Mini targetes ────────────────────
class _IncidenciaCard extends StatelessWidget {
  final Map<String, dynamic> incidencia;
  const _IncidenciaCard({required this.incidencia});

  @override
  Widget build(BuildContext context) {
    final critic = incidencia['criticitat'] ?? 0;
    Color bg =
        critic >= 7
            ? Colors.red.shade100
            : critic >= 4
            ? Colors.orange.shade100
            : Colors.green.shade100;

    return Card(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(incidencia['descripcio'] ?? '—'),
        subtitle: Text(
          'Estat: ${incidencia['estat']} · Inici: ${incidencia['data_inici']}',
        ),
      ),
    );
  }
}

class _TascaCardMini extends StatelessWidget {
  final Map<String, dynamic> tasca;
  const _TascaCardMini({required this.tasca});

  @override
  Widget build(BuildContext context) {
    final visible = tasca['visibilitat_tasca'] == true;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          visible ? Icons.visibility : Icons.visibility_off,
          color: visible ? Colors.green : Colors.grey,
        ),
        title: Text(tasca['descripcio'] ?? '—'),
        subtitle: Text(
          'Prioritat: ${tasca['prioritat']} · Inici: ${tasca['data_inici']}',
        ),
      ),
    );
  }
}

class _DocCardMini extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocCardMini({required this.doc});

  @override
  Widget build(BuildContext context) {
    final sizeMb = double.tryParse('${doc['mida']}') ?? 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(doc['nom'] ?? '—'),
        subtitle: Text(
          'Format: ${doc['format']} · ${sizeMb.toStringAsFixed(2)} MB',
        ),
      ),
    );
  }
}

class _SolRecCardMini extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SolRecCardMini({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(item['quantitat'].toString()),
        subtitle: Text(
          'Recurs ID: ${item['id_recurs']} · Data: ${item['data_necessitat']}',
        ),
      ),
    );
  }
}
