//FET
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:front_end/screens/tascaDetailScreen.dart';
import 'package:front_end/screens/empresa/tasca_form.dart';

/// Pantalla de **Gestió de Tasques** amb la mateixa estètica que la resta
/// (estadístiques, cercador, targetes riques, RefreshIndicator, menú d'accions).
class TasquesScreen extends StatefulWidget {
  const TasquesScreen({super.key});

  @override
  State<TasquesScreen> createState() => _TasquesScreenState();
}

class _TasquesScreenState extends State<TasquesScreen> {
  static const _baseUrl = 'http://localhost:8000/api';

  final List<Map<String, dynamic>> _tasques = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchTasques();
  }

  //──────────────────── API ────────────────────
  Future<void> _fetchTasques() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/tasques/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        _tasques
          ..clear()
          ..addAll(data.cast<Map<String, dynamic>>());
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error al carregar tasques: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteTasca(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tasca'),
        content: const Text('Vols eliminar aquesta tasca?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel·la')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await http.delete(Uri.parse('$_baseUrl/tasca/$id/'));
      if (res.statusCode == 204) {
        _fetchTasques();
        _snack('Tasca eliminada', success: true);
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
      appBar: AppBar(title: const Text('Tasques')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatsHeader(tasques: _tasques),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cerca per descripció...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final items = _query.isEmpty
        ? _tasques
        : _tasques.where((t) => (t['descripcio'] ?? '').toString().toLowerCase().contains(_query)).toList();

    if (items.isEmpty) return const Center(child: Text('No hi ha tasques'));

    return RefreshIndicator(
      onRefresh: _fetchTasques,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _TascaCard(tasca: items[i], onDelete: _deleteTasca),
      ),
    );
  }

  void _snack(String msg, {bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : null));
}

//──────────────────── ESTADÍSTIQUES ────────────────────
class _StatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> tasques;
  const _StatsHeader({required this.tasques});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = tasques.length;
    final visibles = tasques.where((t) => t['visibilitat_tasca'] == true).length;
    final prioritatAlta = tasques.where((t) => (t['prioritat'] ?? 99) <= 2).length;

    Card _stat(String label, int value, IconData icon, Color color) => Card(
          color: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 100,
            height: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: scheme.onPrimary),
                const SizedBox(height: 6),
                Text(value.toString(), style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: scheme.onPrimary.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _stat('Totals', totals, Icons.list_alt, scheme.primary),
          _stat('Visibles', visibles, Icons.visibility, Colors.teal),
          _stat('Alta Prio.', prioritatAlta, Icons.priority_high, Colors.orange),
        ],
      ),
    );
  }
}

//──────────────────── TARGETA TASCA ────────────────────
class _TascaCard extends StatelessWidget {
  final Map<String, dynamic> tasca;
  final void Function(int) onDelete;
  const _TascaCard({required this.tasca, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final descr = tasca['descripcio'] ?? '—';
    final start = tasca['data_inici'] ?? 'N/D';
    final end = tasca['data_fi'] ?? 'N/D';
    final prio = tasca['prioritat']?.toString() ?? '-';
    final visible = tasca['visibilitat_tasca'] == true;

    Color _prioColor(int p) {
      if (p == 1) return Colors.red;
      if (p == 2) return Colors.orange;
      return scheme.primary;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visible ? Colors.green : Colors.grey,
          child: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
        ),
        title: Text(descr, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Inici: $start · Fi: $end\nPrioritat: $prio'),
        isThreeLine: true,
        onTap: () {
          final id = int.tryParse('${tasca['id']}') ?? -1;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TascaDetailScreen(tascaId: id)),
          );
        },
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') onDelete(tasca['id']);
            if (v == 'edit') {
              Navigator.pushNamed(context, '/editTasca', arguments: tasca);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edita')),
            PopupMenuItem(value: 'delete', child: Text('Elimina')),
          ],
        ),
      ),
    );
  }
}
