import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecursDetail extends StatefulWidget {
  final int recursId;

  const RecursDetail({super.key, required this.recursId});

  @override
  State<RecursDetail> createState() => _RecursDetailState();
}

class _RecursDetailState extends State<RecursDetail> {
  Map<String, dynamic>? recurs;
  List<dynamic> solRecursos = [];

  @override
  void initState() {
    super.initState();
    _carregarDetallsRecurs();
  }

  Future<void> _carregarDetallsRecurs() async {
    try {
      final recursRes = await http.get(
        Uri.parse('http://localhost:8000/api/recursos/${widget.recursId}/'),
      );

      if (recursRes.statusCode == 200) {
        setState(() {
          recurs = jsonDecode(recursRes.body);
        });

        await _carregarSolRecursos(widget.recursId);
      } else {
        debugPrint('Error recurs: ${recursRes.statusCode}');
      }
    } catch (e) {
      debugPrint('Error de connexió: $e');
    }
  }

  Future<void> _carregarSolRecursos(int idRecurs) async {
    final url = Uri.parse('http://localhost:8000/api/sol_recursos/?id_recurs=$idRecurs');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          solRecursos = jsonDecode(res.body);
        });
      } else {
        debugPrint('Error sol_recurs: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sol_recurs connexió: $e');
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
      );

  Widget _buildInfoTile(String label, String value) => ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      );

  @override
  Widget build(BuildContext context) {
    if (recurs == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Detall del Recurs'),
        backgroundColor: Colors.blue[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Informació del recurs'),
          _buildInfoTile('Nom', recurs!['nom'] ?? '-'),
          _buildInfoTile('Unitats de mesura', recurs!['unitats_mesura'] ?? '-'),
          _buildInfoTile('Quantitat en stock', '${recurs!['quantitat_stock']}'),
          _buildInfoTile('Tipus', recurs!['tipus_recurs'] ?? '-'),

          _buildSectionTitle('Sol·licituds associades'),
          if (solRecursos.isEmpty)
            const Text('No hi ha sol·licituds per aquest recurs.'),
          for (var sr in solRecursos)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: Text('Quantitat: ${sr['quantitat']}'),
                subtitle: Text(
                  'Obra ID: ${sr['id_obra']} · Necessari el: ${sr['data_necessitat'] ?? '-'}\n'
                  'Proveïdor: ${sr['proveidor'] ?? 'N/D'} · Entrega: ${sr['data_entrega'] ?? '-'}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }
}
