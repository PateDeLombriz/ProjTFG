//fet

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:http/http.dart' as http;

/// Pantalla de **Gestió de Recursos** amb una estètica coherent amb la resta
/// de pantalles (targetes riques, cercador, RefreshIndicator, estadístiques).
///
/// Funcions:
/// - Llista de recursos amb targetes (nom, quantitat, unitat, tipus + icona).
/// - Cercador instantani.
/// - Estadístiques bàsiques (total, sota mínim, per tipus).
/// - Es pot refrescar fent swipe.
/// - Accions ràpides editar / eliminar.
class RecursosScreen extends StatefulWidget {
  const RecursosScreen({super.key});

  @override
  State<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends State<RecursosScreen> {
  static final _baseUrl = ApiConstants.baseUrl;

  final List<Map<String, dynamic>> _recursos = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchRecursos();
  }

  //──────────────────── API ────────────────────
  Future<void> _fetchRecursos() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/recursos/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        _recursos
          ..clear()
          ..addAll(data.cast<Map<String, dynamic>>());
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error al carregar recursos: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteRecurs(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar recurs'),
            content: const Text('Vols eliminar aquest recurs?'),
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
      final res = await http.delete(Uri.parse('$_baseUrl/recursos/$id/'));
      if (res.statusCode == 204) {
        _fetchRecursos();
        _snack('Recurs eliminat', success: true);
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
      appBar: AppBar(title: const Text('Recursos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatsHeader(recursos: _recursos),
            const SizedBox(height: 16),
            _searchField(scheme),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      
    );
  }

  Widget _searchField(ColorScheme scheme) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Cerca recurs...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      onChanged: (v) => setState(() => _query = v.toLowerCase()),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final items =
        _query.isEmpty
            ? _recursos
            : _recursos
                .where((r) => (r['nom'] ?? '').toLowerCase().contains(_query))
                .toList();

    if (items.isEmpty) return const Center(child: Text('No hi ha recursos'));

    return RefreshIndicator(
      onRefresh: _fetchRecursos,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder:
            (ctx, i) => _RecursCard(recurs: items[i], onDelete: _deleteRecurs),
      ),
    );
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

//──────────────────── ESTADÍSTIQUES ────────────────────
class _StatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> recursos;
  const _StatsHeader({required this.recursos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = recursos.length;
    final low =
        recursos.where((r) {
          final raw = r['quantitat_stock'];
          final quant = raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
          return quant < 10;
        }).length;

    final types = recursos.map((r) => r['tipus_recurs']).toSet().length;

    Card _stat(String label, int value, IconData icon, Color color) {
      return Card(
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
              Text(
                value.toString(),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _stat('Totals', totals, Icons.inventory_2_outlined, scheme.primary),
          _stat('Baix stock', low, Icons.warning_amber, Colors.orange),
          _stat('Tipus', types, Icons.category, Colors.teal),
        ],
      ),
    );
  }
}

//──────────────────── TARGETA RECURS ────────────────────
class _RecursCard extends StatelessWidget {
  final Map<String, dynamic> recurs;
  final void Function(int) onDelete;
  const _RecursCard({required this.recurs, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nom = recurs['nom'] ?? '—';
    final unitats = recurs['unitats_mesura'] ?? '-';
    final quant = recurs['quantitat_stock']?.toString() ?? '-';
    final tipus = recurs['tipus_recurs'] ?? '-';

    IconData _iconFor(String t) {
      switch (t.toString().toLowerCase()) {
        case 'material':
          return Icons.layers_outlined;
        case 'maquinaria':
          return Icons.agriculture_outlined;
        case 'personal':
          return Icons.people_alt_outlined;
        default:
          return Icons.category_outlined;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(_iconFor(tipus)),
        ),
        title: Text(nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Quantitat: $quant $unitats\nTipus: $tipus'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') onDelete(recurs['id']);
            if (v == 'edit') {
              Navigator.pushNamed(context, '/editRecurs', arguments: recurs);
            }
          },
          itemBuilder:
              (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edita')),
                PopupMenuItem(value: 'delete', child: Text('Elimina')),
              ],
        ),
      ),
    );
  }
}
