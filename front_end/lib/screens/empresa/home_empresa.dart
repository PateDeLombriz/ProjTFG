//FET

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/screens/obra_screens/obra_profile_screen.dart';

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
  final _storage = const FlutterSecureStorage();
  final List<Map<String, dynamic>> _obres = [];
  bool _loading = true;
  String _statusFilter = 'Totes';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _carregarSessio();
    await _fetchObres();
  }

  //──────────────────────── API ────────────────────────

  Future<void> _carregarSessio() async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      _snack('No hi ha sessió guardada');
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ); //Ajusta endpoint si cal

      debugPrint('ME status=${res.statusCode}');
      debugPrint('ME body=${res.body}');
 
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint('Usuari carregat: $data');
        // Aquí podries carregar dades específiques de l'empresa o mostrar un missatge de benvinguda
        if (data['subject_id'] != null) {
          //data['tipus']=='empresa' &&
          await _storage.write(
            key: 'subject_id',
            value: data['subject_id'].toString(),
          );
        }
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error al carregar la sessió: $e');
    }
  }

  Future<void> _fetchObres() async {
    setState(() => _loading = true);
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      _snack('No hi ha sessió guardada');
      return;
    }
    try {
      //Agafa l'id guardat a carregaSessio a flutter secure storage per a fer la consulta de les obres d'aquesta empresa
      final idEmpresa = await _storage.read(key: 'subject_id') ?? '';

      final res = await http
          .get(Uri.parse('$_baseUrl/obresEmpresa/$idEmpresa'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }); //Ajusta endpoint si cal
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
          IconButton(
              icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const SizedBox(width: 4),
          CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: const Icon(Icons.person)),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsHeader(obres: _obres), // cuadrats amb informacoi estadstiques
            const SizedBox(height: 20), //Eslai entre estadstiques i filtres
            _filterRow(
                scheme), //Aixo es el row de filtres, on pots seleccionar per estat de l'obra
            const SizedBox(
                height:
                    12), //Aixo es el eslai entre els filtres i el llistat d'obres
            Expanded(
                child:
                    _buildList()), //Aixo es el llistat d'obres, que es refresca cada cop que entres a la pantalla o fas pull to refresh
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: scheme.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        : _obres.where((o) {
            final info = (o['obra_info'] as Map<String, dynamic>?) ?? {};
            return info['estat'] == _statusFilter;
          }).toList();

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

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

//──────────────────────── ESTADÍSTIQUES ────────────────────────
class _StatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> obres;
  const _StatsHeader({required this.obres});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exec = obres.where((o) {
      final info = (o['obra_info'] as Map<String, dynamic>?) ?? {};
      return info['estat'] == 'En execució';
    }).length;

    final fin = obres.where((o) {
      final info = (o['obra_info'] as Map<String, dynamic>?) ?? {};
      return info['estat'] == 'Finalitzada';
    }).length;
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
              Text(value.toString(),
                  style: TextStyle(
                      color: scheme.onPrimary, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      color: scheme.onPrimary.withOpacity(0.8), fontSize: 12)),
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
    final info = (obra['obra_info'] as Map<String, dynamic>?) ?? {};
    final estat = '${info['estat'] ?? 'Sense estat'}';

    Color _color(String s) {
      switch (s) {
        case 'En curs':
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
          //eL PADDING DE LA TARGETA, QUE ES EL QUE FA QUE EL CONTINGUT NO TOQUI LES BORDES I QUEDI MÉS AGRADABLE A LA VISTA
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  //Aixo es la caixa de l'icona, que té un color de fons i una icona dins
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.house_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['nom'] ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        _ubicacioSimple(info['ubicacio']), //abans ubicacio
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    Row(
                      children: [
                        _statusChip(estat, _color(estat)),
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
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _ubicacioSimple(dynamic v) {
  if (v is String) return v.trim().isEmpty ? 'NO string' : v;
  return v.toString();
}
}
