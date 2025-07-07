import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        // Pots afegir "Data_prev_fi" si cal
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obra creada!')));
      Navigator.pop(context); // Torna enrere un cop creada
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear obra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nova Obra', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInputField(_nomController, 'Nom', validator: true),
              const SizedBox(height: 12),
              _buildInputField(_ubicacioController, 'Ubicació'),
              const SizedBox(height: 12),
              _buildInputField(_pressupostController, 'Pressupost (€)', inputType: TextInputType.number),
              const SizedBox(height: 12),
              _buildInputField(_descripcioController, 'Descripció'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _estat,
                decoration: InputDecoration(
                  labelText: 'Estat',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Res Firmat', 'En execució', 'Finalitzada']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _estat = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) _submitForm();
                },
                icon: const Icon(Icons.save),
                label: const Text('Crear Obra'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text, bool validator = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator
          ? (value) => (value == null || value.isEmpty) ? 'Introdueix $label' : null
          : null,
    );
  }
}
