import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/screens/tascaDetailScreen.dart';


class IncidenciaDetail extends StatefulWidget {
  final int incidenciaId;

  const IncidenciaDetail({super.key, required this.incidenciaId});

  @override
  State<IncidenciaDetail> createState() => _IncidenciaDetailState();
}

class _IncidenciaDetailState extends State<IncidenciaDetail> {
  Map<String, dynamic>? incidencia;
  Map<String, dynamic>? obra;
  Map<String, dynamic>? tasca;
  List<dynamic> solucions = [];

  @override
  void initState() {
    super.initState();
    _carregarDadesIncidencia();
  }

  Future<void> _carregarDadesIncidencia() async {
    final url = Uri.parse('http://localhost:8000/api/incidencies/${widget.incidenciaId}/');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          incidencia = data;
        });

        await Future.wait([
          _carregarObra(data['id_obra']),
          if (data['id_tasca'] != null) _carregarTasca(data['id_tasca']),
          _carregarSolucions(widget.incidenciaId),
        ]);
      } else {
        debugPrint('Error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error de connexió: $e');
    }
  }

  Future<void> _carregarObra(int id) async {
    final res = await http.get(Uri.parse('http://localhost:8000/api/obres/$id/'));
    if (res.statusCode == 200) {
      setState(() => obra = jsonDecode(res.body));
    }
  }

  Future<void> _carregarTasca(int id) async {
    final res = await http.get(Uri.parse('http://localhost:8000/api/tasca/$id/'));
    if (res.statusCode == 200) {
      setState(() => tasca = jsonDecode(res.body));
    }
  }

  Future<void> _carregarSolucions(int incidenciaId) async {
    final res = await http.get(Uri.parse('http://localhost:8000/api/solucions/?id_incidencia=$incidenciaId'));
    if (res.statusCode == 200) {
      setState(() => solucions = jsonDecode(res.body));
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
      );

  Widget _buildInfoTile(String label, String value) => ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      );

  @override
  Widget build(BuildContext context) {
    if (incidencia == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text('Detall de la Incidència'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Incidència'),
          _buildInfoTile('Descripció', incidencia!['descripcio'] ?? '-'),
          _buildInfoTile('Data inici', incidencia!['data_inici'] ?? '-'),
          _buildInfoTile('Data fi', incidencia!['data_fi'] ?? '-'),
          _buildInfoTile('Criticitat', '${incidencia!['criticitat']}'),
          _buildInfoTile('Prioritat', '${incidencia!['prioritat']}'),
          _buildInfoTile('Categoria', '${incidencia!['categoria']}'),
          _buildInfoTile('Estat', incidencia!['estat'] ?? '-'),

          if (obra != null) ...[
            _buildSectionTitle('Obra associada'),
            _buildInfoTile('Nom', obra!['nom']),
            _buildInfoTile('Ubicació', obra!['ubicacio'] ?? '-'),
            _buildInfoTile('Pressupost', '${obra!['pressupost'] ?? 'N/D'} €'),
          ],

          if (tasca != null) ...[
            _buildSectionTitle('Tasca associada'),
            _buildInfoTile('Descripció', tasca!['descripcio']),
            _buildInfoTile('Inici', tasca!['data_inici'] ?? '-'),
            _buildInfoTile('Fi', tasca!['data_fi'] ?? '-'),
          ],

          _buildSectionTitle('Solucions proposades'),
          if (solucions.isEmpty)
            const Text('No hi ha solucions associades.'),
          for (var sol in solucions)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.handyman),
                title: Text(sol['descripcio']),
                subtitle: Text(
                  'Cost: ${sol['cost_monetari']} € · Eficàcia: ${sol['eficacia']} · Impacte: ${sol['impacte']}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
