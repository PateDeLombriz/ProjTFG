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
    _ubicacioController = TextEditingController(text: widget.obra.Ubicacio ?? '');
    _pressupostController = TextEditingController(text: widget.obra.Pressupost?.toString() ?? '');
    _descripcioController = TextEditingController(text: widget.obra.Descripcio ?? '');
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Obra actualitzada')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualitzar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar obra')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              TextFormField(
                controller: _ubicacioController,
                decoration: InputDecoration(labelText: 'Ubicació'),
              ),
              TextFormField(
                controller: _pressupostController,
                decoration: InputDecoration(labelText: 'Pressupost (€)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _descripcioController,
                decoration: InputDecoration(labelText: 'Descripció'),
              ),
              DropdownButtonFormField<String>(
                value: _estat,
                decoration: InputDecoration(labelText: 'Estat'),
                items: ['Res Firmat', 'En execució', 'Finalitzada']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _estat = value!),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateObra,
                child: Text('Actualitzar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
