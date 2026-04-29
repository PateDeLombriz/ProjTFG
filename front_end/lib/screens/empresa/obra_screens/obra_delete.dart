import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package: lib/models/obra.dart'; // Importa la classe Obra
//import 'package: lib/services/api_service.dart'; // Importa la funció getObres

class DeleteConfirmationPage extends StatelessWidget {
  final int obraId;

  const DeleteConfirmationPage({super.key, required this.obraId});

  Future<void> _deleteObra(BuildContext context) async {
    final response = await http.delete(
      Uri.parse('http://localhost:8000/api/obres/$obraId/'),
    );

    if (response.statusCode == 204) {
      Navigator.pop(context, true); // Indica que s’ha esborrat
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar l\'obra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Eliminar obra'),
      content: Text('Vols eliminar aquesta obra?'),
      actions: [
        TextButton(
          child: Text('Cancel·la'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Confirma'),
          onPressed: () => _deleteObra(context),
        ),
      ],
    );
  }
}

