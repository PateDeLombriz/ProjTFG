import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TascaDetailScreen extends StatefulWidget {
  final int tascaId;

  const TascaDetailScreen({super.key, required this.tascaId});

  @override
  State<TascaDetailScreen> createState() => _TascaDetailScreenState();
}

class _TascaDetailScreenState extends State<TascaDetailScreen> {
  Map<String, dynamic>? tascaData;
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchTascaDetails();
  }

  Future<void> fetchTascaDetails() async {
    final url = Uri.parse('http://localhost:8000/api/tasques/${widget.tascaId}/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          tascaData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error de connexió: $e';
        isLoading = false;
      });
    }
  }

  Widget buildInfoTile(String title, String? value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? 'No disponible'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalls de la Tasca')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : tascaData == null
                  ? const Center(child: Text('No s\'han trobat dades.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Informació bàsica',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        buildInfoTile('Descripció', tascaData!['descripcio']),
                        buildInfoTile('Data inici', tascaData!['data_inici']),
                        buildInfoTile('Data final', tascaData!['data_fi']),
                        buildInfoTile('Prioritat', tascaData!['prioritat']?.toString()),
                        buildInfoTile('Visible', tascaData!['visibilitat_tasca'] == true ? 'Sí' : 'No'),
                        const Divider(height: 30),
                        const Text('Obra associada',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        buildInfoTile('Nom Obra', tascaData!['obra']?['nom']),
                        buildInfoTile('Ubicació', tascaData!['obra']?['ubicacio']),
                        const Divider(height: 30),
                        const Text('Tasca pare',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        buildInfoTile('Descripció pare', tascaData!['tasca_pare']?['descripcio']),
                        const Divider(height: 30),
                        const Text('Treballador assignat',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        buildInfoTile('Nom', tascaData!['treballador']?['nom']),
                        buildInfoTile('Comentari', tascaData!['treballador']?['comentari']),
                        const Divider(height: 30),
                        const Text('Incidències relacionades',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ...(tascaData!['incidencies'] as List<dynamic>)
                            .map((inc) => buildInfoTile(' -', inc['descripcio']))
                            .toList(),
                        const Divider(height: 30),
                        const Text('Solucions proposades',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ...(tascaData!['solucions'] as List<dynamic>)
                            .map((sol) => buildInfoTile(' -', sol['descripcio']))
                            .toList(),
                      ],
                    ),
    );
  }
}
