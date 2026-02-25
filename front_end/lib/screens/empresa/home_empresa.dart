//FET

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:front_end/screens/empresa/obra_form.dart';
import 'package:front_end/screens/obresDetail_screen.dart';

/// Pantalla principal per a empreses amb llistat d'obres, estadístiques i filtres.
/// Estètica i UX alineades amb la resta de pantalles (bordes arrodonits, colors de tema,
/// validacions, RefreshIndicator, targetes riques i chips d'estat).
class HomeEmpresa extends StatefulWidget {
  const HomeEmpresa({super.key});

  @override
  State<HomeEmpresa> createState() => _HomeEmpresaState();
}

class _HomeEmpresaState extends State<HomeEmpresa> {
  static const _baseUrl = 'http://localhost:8000/api';

  final List<Map<String, dynamic>> _obres = [];
  bool _loading = true;
  String _statusFilter = 'Totes';

  @override
  void initState() {
    super.initState();
    _fetchObres();
  }

  //──────────────────────── API ────────────────────────
  Future<void> _fetchObres() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/obres/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        _obres
          ..clear()
          ..addAll(data.cast<Map<String, dynamic>>());
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error al carregar les obres: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  //──────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestió d\'Obres'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const SizedBox(width: 4),
          CircleAvatar(backgroundColor: scheme.primaryContainer, child: const Icon(Icons.person)),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsHeader(obres: _obres),
            const SizedBox(height: 20),
            _filterRow(scheme),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  //───────────────────── Widgets auxiliars ──────────────────────
  Widget _filterRow(ColorScheme scheme) {
    return Row(
      children: [
        const Text('Filtra per estat:'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: scheme.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['Totes', 'Res Firmat', 'En execució', 'Finalitzada']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _statusFilter = v ?? 'Totes'),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final items = _statusFilter == 'Totes'
        ? _obres
        : _obres.where((o) => (o['estat'] ?? o['Estat']) == _statusFilter).toList();

    if (items.isEmpty) {
      return const Center(child: Text('No hi ha obres'));
    }

    return RefreshIndicator(
      onRefresh: _fetchObres,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _ObraCard(obra: items[i], onTap: _openObra),
      ),
    );
  }

  //───────────────────── Navegació ──────────────────────
  void _openObra(Map<String, dynamic> obra) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ObraProfileScreen(obra: obra)),
    );
    if (updated == true) _fetchObres();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

//──────────────────────── ESTADÍSTIQUES ────────────────────────
class _StatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> obres;
  const _StatsHeader({required this.obres});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exec = obres.where((o) => (o['estat'] ?? o['Estat']) == 'En execució').length;
    final fin = obres.where((o) => (o['estat'] ?? o['Estat']) == 'Finalitzada').length;

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
              Text(value.toString(), style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: scheme.onPrimary.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat('Totals', obres.length, Icons.business, scheme.primary),
        _stat('Execució', exec, Icons.construction, Colors.orange),
        _stat('Finalitz.', fin, Icons.check_circle, Colors.green),
      ],
    );
  }
}

//──────────────────────── TARGETA OBRA ─────────────────────────
class _ObraCard extends StatelessWidget {
  final Map<String, dynamic> obra;
  final void Function(Map<String, dynamic>) onTap;
  const _ObraCard({required this.obra, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estat = '${obra['estat'] ?? obra['Estat'] ?? 'Sense estat'}';

    Color _color(String s) {
      switch (s) {
        case 'En execució':
          return Colors.orange;
        case 'Finalitzada':
          return Colors.green;
        case 'Res Firmat':
          return Colors.grey;
        default:
          return scheme.primary;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(obra),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.house_siding_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(obra['nom'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_ubicacioSimple(obra['ubicacio']),
                      style: TextStyle(color: scheme.onSurfaceVariant)),                    Row(
                      children: [
                        _statusChip(estat, _color(estat)),
                        const SizedBox(width: 6),
                        if (obra['pressupost'] != null)
                          Text('€${obra['pressupost']}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _ubicacioSimple(dynamic v) {
    if (v == null) return 'Sense ubicació';
    if (v is String) return v.trim().isEmpty ? 'Sense ubicació' : v;
    if (v is int) return 'Ubicació #$v';
    if (v is Map) {
      final adreca = v['adreca'] ?? v['adreça'];
      final ciutat = v['ciutat'];
      return [adreca, ciutat]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
    }
    return v.toString();
  }
}
