import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/screens/empresa/obra_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> obres = [];
  bool isLoading = true;
  String selectedFilter = 'Totes';
  int currentIndex = 0; // Per al BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _loadObres();
  }

  Future<void> _loadObres() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/obres/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          obres = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al carregar les obres: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredObres {
    if (selectedFilter == 'Totes') return obres;
    return obres.where((obra) => obra['Estat'] == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestió d\'Obres'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // notificacions
            },
          ),
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[800],
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menú d\'usuari', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Canviar d\'obra'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administració'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Ajuda'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Tancar sessió'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 20),
            _buildFilterDropdown(),
            const SizedBox(height: 12),
            Expanded(child: _buildObraList()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          // Aquí pots navegar entre pantalles segons l'índex
        },
        selectedItemColor: Colors.blue[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Obres'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasques'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Materials'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ObraForm()),
          ).then((_) => _loadObres());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Obra'),
        backgroundColor: Colors.blue[800],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('Total', obres.length.toString(), Icons.business),
          _buildStatCard('Execució', obres.where((o) => o['Estat'] == 'En execució').length.toString(), Icons.construction),
          _buildStatCard('Finalitzades', obres.where((o) => o['Estat'] == 'Finalitzada').length.toString(), Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Row(
      children: [
        const Text('Filtrar per estat:'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedFilter,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: ['Totes', 'Res Firmat', 'En execució', 'Finalitzada']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => selectedFilter = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildObraList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (filteredObres.isEmpty) {
      return const Center(child: Text('No s\'han trobat obres'));
    }
    return RefreshIndicator(
      onRefresh: _loadObres,
      child: ListView.builder(
        itemCount: filteredObres.length,
        itemBuilder: (context, index) => _buildObraCard(filteredObres[index]),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildObraCard(Map<String, dynamic> obra) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(obra['nom'] ?? 'Sense nom'),
        subtitle: Text(obra['ubicacio'] ?? 'Sense ubicació'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showObraDetails(obra),
      ),
    );
  }

  void _showObraDetails(Map<String, dynamic> obra) {
    // Implementació igual que abans
  }
}
