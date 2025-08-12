import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ****************************
///  TreballadorProfileScreen
/// ****************************
/// Mostra el perfil públic (per al propi
/// treballador) amb la mateixa estètica que la
/// resta de l'app (cards arrodonides, padding
/// 16, ExpansionTiles per llistes secundàries…)
/// ***********************************************************
class TreballadorProfileScreen extends StatefulWidget {
  const TreballadorProfileScreen({super.key, required this.treballadorId});

  final int treballadorId;

  @override
  State<TreballadorProfileScreen> createState() => _TreballadorProfileScreenState();
}

class _TreballadorProfileScreenState extends State<TreballadorProfileScreen> {
  late Future<Map<String, dynamic>> _ficha;

  @override
  void initState() {
    super.initState();
    _ficha = _fetchWorker();
  }

  Future<Map<String, dynamic>> _fetchWorker() async {
    final url = Uri.parse('https://tu-backend.com/api/treballadors/${widget.treballadorId}/');
    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      // Afegir Bearer token si ja tens auth
    });
    if (res.statusCode != 200) throw Exception('Error carregant perfil');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Refresca via pull‑to‑refresh
  Future<void> _onRefresh() async {
    setState(() {
      _ficha = _fetchWorker();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('El meu perfil')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _ficha,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final data = snap.data!;
            final ubis = data['ubicacio'] as Map<String, dynamic>?;
            final tasques = (data['tasques'] as List?) ?? [];
            final obres = (data['obres_responsable'] as List?) ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(data: data),
                const SizedBox(height: 20),
                _SectionTitle('Informació bàsica'),
                _InfoTile(label: 'Nom complet', value: '${data['nom']} ${data['cognoms']}'),
                _InfoTile(label: 'DNI/NIE', value: data['dni_nie_passaport'] ?? '—'),
                if (data['data_naixement'] != null)
                  _InfoTile(label: 'Naixement', value: data['data_naixement']),
                const SizedBox(height: 12),
                _SectionTitle('Contacte'),
                _InfoTile(label: 'Telèfon', value: data['telefon'] ?? '—'),
                _InfoTile(label: 'Email', value: data['email'] ?? '—'),
                if (ubis != null)
                  _InfoTile(
                    label: 'Ubicació',
                    value: [ubis['adreça'], ubis['ciutat'], ubis['provincia']]
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .join(', '),
                  ),
                const SizedBox(height: 20),
                _SectionTitle('Configuració'),
                if (data['configuracio'] == null)
                  const Text('Sense configuració', style: TextStyle(color: Colors.grey)),
                if (data['configuracio'] != null)
                  _ConfigCard(cfg: data['configuracio']),
                const SizedBox(height: 20),
                ExpansionTile(
                  title: _SectionTitle('Tasques assignades', inline: true),
                  children: [
                    if (tasques.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Cap tasca assignada'),
                      )
                    else
                      ...tasques.map((t) => _TaskCard(t)).toList(),
                  ],
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: _SectionTitle('Responsable d\'obra', inline: true),
                  children: [
                    if (obres.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No ets responsable de cap obra'),
                      )
                    else
                      ...obres.map((o) => _ObraCard(o)).toList(),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ----------------- UI helpers -----------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final photoUrl = data['foto'] as String?;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) as ImageProvider : null,
              child: photoUrl == null
                  ? Text(
                      data['nom'][0],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data['nom']} ${data['cognoms']}',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.inline = false});
  final String text;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final widget = Text(text, style: Theme.of(context).textTheme.titleMedium);
    return inline ? widget : Padding(padding: const EdgeInsets.only(bottom: 8), child: widget);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value.isEmpty ? '—' : value),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.cfg});
  final Map<String, dynamic> cfg;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoTile(label: 'Idioma', value: cfg['idioma'] ?? '—'),
              _InfoTile(label: 'Accepta T&C', value: cfg['acceptacio_terms'] == true ? 'Sí' : 'No'),
            ],
          ),
        ),
      );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard(this.t);
  final Map<String, dynamic> t;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(t['descripcio'] ?? ''),
        subtitle: Text('Inici: ${t['data_inici']}  ·  Fi: ${t['data_fi'] ?? '—'}'),
        trailing: Chip(label: Text('P${t['prioritat']}')),
      ),
    );
  }
}

class _ObraCard extends StatelessWidget {
  const _ObraCard(this.o);
  final Map<String, dynamic> o;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: ListTile(
          title: Text(o['nom_obra'] ?? ''),
          subtitle: Text('Responsable des de ${o['data_inici_resp']}'),
          trailing: Text(o['estat_obra'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
}
