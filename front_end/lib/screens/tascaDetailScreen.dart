// tasca_detail_screen_styled.dart
// ----------------------------------------------------------------------------------
// Detall de Tasca amb estètica unificada (coherent amb HomeEmpresa):
//  • ColorScheme, targetes amb cantonades arrodonides i ombres suaus
//  • Capçalera amb resum i xips d'estat/prioritat/visibilitat
//  • Seccions clarament separades: Tasca, Tasca pare, Obra, Treballador, Incidències, Solucions
//  • Refresh manual (icona a l'AppBar) i arrossegant (RefreshIndicator)
//  • Sense dependències noves
// ----------------------------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TascaDetailScreen extends StatefulWidget {
  const TascaDetailScreen({super.key, required this.tascaId});
  final int tascaId;

  @override
  State<TascaDetailScreen> createState() => _TascaDetailScreenState();
}

class _TascaDetailScreenState extends State<TascaDetailScreen> {
  static const String baseUrl = 'http://localhost:8000/api';

  Map<String, dynamic>? _tasca;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarDetalls();
  }

  Future<void> _carregarDetalls() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse('$baseUrl/tasca/${widget.tascaId}/'));
      if (res.statusCode == 200) {
        setState(() => _tasca = jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        setState(() => _error = 'HTTP ${res.statusCode}: ${res.reasonPhrase}');
      }
    } catch (e) {
      setState(() => _error = 'Error de connexió: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------------------- Helpers visuals ---------------------
  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    // si ve ISO, talla a AAAA-MM-DD
    if (d.length >= 10) return d.substring(0, 10);
    return d;
  }

  Color _prioritatColor(int? p, ColorScheme scheme) {
    if (p == null) return scheme.outline;
    switch (p) {
      case 5:
      case 4:
        return Colors.redAccent;
      case 3:
        return Colors.orange;
      case 2:
      case 1:
      default:
        return Colors.green;
    }
  }

  Widget _chip(String text, Color color, Color onColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoTile(BuildContext context, {required String label, required String value, IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: .6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalls de la Tasca'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarDetalls),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _carregarDetalls)
              : RefreshIndicator(
                  onRefresh: _carregarDetalls,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(tasca: _tasca!),

                      _sectionTitle(context, 'Tasca'),
                      _infoTile(
                        context,
                        label: 'Descripció',
                        value: _tasca!['descripcio'] ?? '—',
                        icon: Icons.description_outlined,
                      ),
                      _infoTile(
                        context,
                        label: 'Data inici',
                        value: _fmtDate(_tasca!['data_inici'] as String?),
                        icon: Icons.event_available,
                      ),
                      _infoTile(
                        context,
                        label: 'Data fi',
                        value: _fmtDate(_tasca!['data_fi'] as String?),
                        icon: Icons.event_busy,
                      ),
                      _infoTile(
                        context,
                        label: 'Prioritat',
                        value: (_tasca!['prioritat']?.toString() ?? '—'),
                        icon: Icons.priority_high_outlined,
                      ),
                      _infoTile(
                        context,
                        label: 'Visible',
                        value: ((_tasca!['visibilitat_tasca'] ?? false) ? 'Sí' : 'No'),
                        icon: Icons.visibility_outlined,
                      ),

                      if (_tasca!['tasca_pare'] != null) ...[
                        _sectionTitle(context, 'Tasca pare'),
                        _ParentTaskCard(parent: _tasca!['tasca_pare'] as Map<String, dynamic>),
                      ],

                      if (_tasca!['obra'] != null) ...[
                        _sectionTitle(context, 'Obra associada'),
                        _WorkCard(obra: _tasca!['obra'] as Map<String, dynamic>),
                      ],

                      if (_tasca!['treballador_assignat'] != null) ...[
                        _sectionTitle(context, 'Treballador assignat'),
                        _WorkerCard(assignacio: _tasca!['treballador_assignat'] as Map<String, dynamic>),
                      ],

                      _sectionTitle(context, 'Incidències associades'),
                      _IncidenciesList(list: (_tasca!['incidencies'] as List?) ?? const []),

                      _sectionTitle(context, 'Solucions associades'),
                      _SolucionsList(list: (_tasca!['solucions'] as List?) ?? const []),

                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Tornar'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.tasca});
  final Map<String, dynamic> tasca;

  Color _estatColor(String? s) {
    switch (s) {
      case 'pendent':
      case 'PENDENT':
        return Colors.orange;
      case 'resolta':
      case 'RESOLTA':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prioritat = tasca['prioritat'] as int?;
    final visible = (tasca['visibilitat_tasca'] ?? false) as bool;
    final estatInc = (tasca['estat_incidencies'] ?? '—') as String?; // opcional si el backend ho dona

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.task_alt_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (tasca['descripcio'] ?? '—') as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('Prioritat ${prioritat ?? '—'}', _prioritatColor(prioritat, scheme), scheme.onSurface),
                          _chip(visible ? 'Visible' : 'Oculta', visible ? Colors.green : Colors.grey, scheme.onSurface),
                          if (estatInc != null && estatInc != '—')
                            _chip('Incidències: $estatInc', _estatColor(estatInc), scheme.onSurface),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _prioritatColor(int? p, ColorScheme scheme) {
    if (p == null) return scheme.outline;
    switch (p) {
      case 5:
      case 4:
        return Colors.redAccent;
      case 3:
        return Colors.orange;
      case 2:
      case 1:
      default:
        return Colors.green;
    }
  }

  Widget _chip(String text, Color color, Color onColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _ParentTaskCard extends StatelessWidget {
  const _ParentTaskCard({required this.parent});
  final Map<String, dynamic> parent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.device_hub_outlined, color: scheme.primary),
        title: Text(parent['descripcio'] ?? '—'),
        subtitle: Text('ID: ${parent['id'] ?? '—'}'),
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.obra});
  final Map<String, dynamic> obra;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.business, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(obra['nom'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_ubicacioSimple(obra['ubicacio']),
                  style: TextStyle(color: scheme.onSurfaceVariant))                ],
              ),
            ),
          ],
        ),
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

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.assignacio});
  final Map<String, dynamic> assignacio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final usuari = assignacio['usuari'] as Map<String, dynamic>?;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuari != null
                        ? '${usuari['nom'] ?? ''} ${usuari['cognoms'] ?? ''}'.trim()
                        : '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (assignacio['comentari'] != null && assignacio['comentari'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(assignacio['comentari']),
                  ],
                  if (usuari != null) ...[
                    const SizedBox(height: 4),
                    Text('ID Usuari: ${usuari['id']}', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _IncidenciesList extends StatelessWidget {
  const _IncidenciesList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (list.isEmpty) {
      return Text('No hi ha incidències.', style: TextStyle(color: scheme.onSurfaceVariant));
    }

    return Column(
      children: [
        for (final inc in list)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.report_gmailerrorred_outlined, color: scheme.primary),
              title: Text(inc['descripcio'] ?? 'Sense descripció'),
              subtitle: Text(
                'Estat: ${inc['estat'] ?? '—'} · Prioritat: ${inc['prioritat'] ?? '—'}\nInici: ${_fmt(inc['data_inici'])} · Fi: ${_fmt(inc['data_fi'])}',
              ),
            ),
          ),
      ],
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }
}

class _SolucionsList extends StatelessWidget {
  const _SolucionsList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (list.isEmpty) {
      return Text('No hi ha solucions.', style: TextStyle(color: scheme.onSurfaceVariant));
    }

    return Column(
      children: [
        for (final sol in list)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: scheme.primary),
              title: Text(sol['descripcio'] ?? '—'),
              subtitle: Text(
                'Cost: ${sol['cost_monetari'] ?? '—'} € · Impacte: ${sol['impacte'] ?? '—'} · Eficàcia: ${sol['eficacia'] ?? '—'}',
              ),
            ),
          ),
      ],
    );
  }
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text('S\'ha produït un error', style: TextStyle(fontSize: 18, color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Torna-ho a intentar')),
          ],
        ),
      ),
    );
  }
}
