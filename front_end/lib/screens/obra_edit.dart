import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/obra.dart';

class ObraEdit extends StatefulWidget {
  final Obra obra;

  const ObraEdit({super.key, required this.obra});

  @override
  State<ObraEdit> createState() => _ObraEditState();
}

class _ObraEditState extends State<ObraEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _ubicacioController;
  late TextEditingController _pressupostController;
  late TextEditingController _descripcioController;
  late String _estat;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.obra.Nom);
    _ubicacioController = TextEditingController(
      text: widget.obra.Ubicacio ?? '',
    );
    _pressupostController = TextEditingController(
      text: widget.obra.Pressupost?.toString() ?? '',
    );
    _descripcioController = TextEditingController(
      text: widget.obra.Descripcio ?? '',
    );
    _estat = widget.obra.Estat;
  }

  Future<void> _updateObra() async {
    final response = await http.put(
      Uri.parse('http://localhost:8000/api/obres/${widget.obra.Id}/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "Nom": _nomController.text,
        "Ubicacio": _ubicacioController.text,
        "Pressupost": double.tryParse(_pressupostController.text),
        "Descripcio": _descripcioController.text,
        "Estat": _estat,
        "Data_inici": widget.obra.DataInici.toIso8601String(),
        "Data_prev_fi": widget.obra.DataPrevFi?.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Obra actualitzada')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualitzar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Editar Obra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInputField(_nomController, 'Nom'),
              const SizedBox(height: 12),
              _buildInputField(_ubicacioController, 'Ubicació'),
              const SizedBox(height: 12),
              _buildInputField(
                _pressupostController,
                'Pressupost (€)',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildInputField(_descripcioController, 'Descripció'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _estat,
                decoration: InputDecoration(
                  labelText: 'Estat',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    ['Res Firmat', 'En execució', 'Finalitzada']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) => setState(() => _estat = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _updateObra,
                icon: const Icon(Icons.save),
                label: const Text('Actualitzar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
