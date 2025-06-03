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
        // pots afegir Data_prev_fi si cal
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Obra creada!')));
      Navigator.pop(context); // Torna enrere un cop creat
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
