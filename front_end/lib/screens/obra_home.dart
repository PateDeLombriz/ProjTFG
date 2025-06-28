import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> obres = [];
  bool isLoading = true;
  String selectedFilter = 'Totes';

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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al carregar les obres: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredObres {
    if (selectedFilter == 'Totes') return obres;
    return obres.where((obra) => obra['Estat'] == selectedFilter).toList();
  }

  Color _getStateColor(String estat) {
    switch (estat.toLowerCase()) {
      case 'en execució':
        return Colors.orange;
      case 'finalitzada':
        return Colors.green;
      case 'res firmat':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String estat) {
    switch (estat.toLowerCase()) {
      case 'en execució':
        return Icons.construction;
      case 'finalitzada':
        return Icons.check_circle;
      case 'res firmat':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 €';
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gestió d\'Obres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'nova_obra':
                  // Navegar a formulari nova obra
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ObraForm()),
                  ).then((_) => _loadObres());
                  break;
                case 'configuracio':
                  // Navegar a configuració
                  break;
                case 'informes':
                  // Navegar a informes
                  break;
                case 'tancar_sessio':
                  // Tancar sessió
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'nova_obra',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Nova Obra'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'informes',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Informes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'configuracio',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Configuració'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'tancar_sessio',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Tancar Sessió'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header amb estadístiques
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Total Obres', obres.length.toString(), Icons.business),
                    _buildStatCard(
                      'En Execució', 
                      obres.where((o) => o['Estat'] == 'En execució').length.toString(),
                      Icons.construction
                    ),
                    _buildStatCard(
                      'Finalitzades',
                      obres.where((o) => o['Estat'] == 'Finalitzada').length.toString(),
                      Icons.check_circle
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filtrar per estat:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    items: ['Totes', 'Res Firmat', 'En execució', 'Finalitzada']
                        .map((estat) => DropdownMenuItem(
                              value: estat,
                              child: Text(estat),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Llista d'obres
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredObres.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No s\'han trobat obres',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadObres,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredObres.length,
                          itemBuilder: (context, index) {
                            final obra = filteredObres[index];
                            return _buildObraCard(obra);
                          },
                        ),
                      ),
          ),
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
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildObraCard(Map<String, dynamic> obra) {
    final estat = obra['Estat'] ?? 'Desconegut';
    final stateColor = _getStateColor(estat);
    final stateIcon = _getStateIcon(estat);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegar als detalls de l'obra
          _showObraDetails(obra);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      obra['Nom'] ?? 'Sense nom',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stateColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stateColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stateIcon, size: 16, color: stateColor),
                        const SizedBox(width: 4),
                        Text(
                          estat,
                          style: TextStyle(
                            color: stateColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (obra['Ubicacio'] != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        obra['Ubicacio'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.euro, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _formatCurrency(obra['Pressupost']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (obra['Data_inici'] != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateTime.parse(obra['Data_inici']).day.toString() +
                              '/' +
                              DateTime.parse(obra['Data_inici']).month.toString() +
                              '/' +
                              DateTime.parse(obra['Data_inici']).year.toString(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                ],
              ),
              if (obra['Descripcio'] != null && obra['Descripcio'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  obra['Descripcio'],
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showObraDetails(Map<String, dynamic> obra) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                obra['Nom'] ?? 'Sense nom',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Ubicació', obra['Ubicacio'], Icons.location_on),
              _buildDetailRow('Estat', obra['Estat'], Icons.info),
              _buildDetailRow('Pressupost', _formatCurrency(obra['Pressupost']), Icons.euro),
              if (obra['Data_inici'] != null)
                _buildDetailRow('Data d\'inici', 
                  DateTime.parse(obra['Data_inici']).day.toString() + '/' +
                  DateTime.parse(obra['Data_inici']).month.toString() + '/' +
                  DateTime.parse(obra['Data_inici']).year.toString(),
                  Icons.calendar_today),
              const SizedBox(height: 16),
              if (obra['Descripcio'] != null && obra['Descripcio'].isNotEmpty) ...[
                const Text(
                  'Descripció:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  obra['Descripcio'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navegar a tasques de l'obra
                      },
                      icon: const Icon(Icons.task),
                      label: const Text('Tasques'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navegar a documents de l'obra
                      },
                      icon: const Icon(Icons.folder),
                      label: const Text('Documents'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'No especificat',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

// Aquí necessitaràs importar la teva classe ObraForm existent
class ObraForm extends StatefulWidget {
  const ObraForm({super.key});

  @override
  State<ObraForm> createState() => _ObraFormState();
}

class _ObraFormState extends State<ObraForm> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _ubicacioController = TextEditingController();
  final _pressupostController = TextEditingController();
  final _descripcioController = TextEditingController();
  String _estat = "Res Firmat";

  Future<void> _submitForm() async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/obres/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "Nom": _nomController.text,
        "Ubicacio": _ubicacioController.text,
        "Pressupost": double.tryParse(_pressupostController.text),
        "Descripcio": _descripcioController.text,
        "Estat": _estat,
        "Data_inici": DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Obra creada!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear obra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nova obra")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) => value!.isEmpty ? 'Introdueix un nom' : null,
              ),
              TextFormField(
                controller: _ubicacioController,
                decoration: InputDecoration(labelText: 'Ubicació'),
              ),
              TextFormField(
                controller: _pressupostController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Pressupost'),
              ),
              TextFormField(
                controller: _descripcioController,
                decoration: InputDecoration(labelText: 'Descripció'),
              ),
              DropdownButtonFormField<String>(
                value: _estat,
                items: ['Res Firmat', 'En execució', 'Finalitzada']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _estat = value!),
                decoration: InputDecoration(labelText: 'Estat'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) _submitForm();
                },
                child: Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}