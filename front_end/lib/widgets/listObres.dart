import 'package:flutter/material.dart';
import '../models/obra_models.dart'; // Importa la classe Obra
import '../services/api_service.dart'; // Importa la funció fetchObres
class ObraListWidget extends StatefulWidget {
  const ObraListWidget({super.key});

  @override
  _ObraListWidgetState createState() => _ObraListWidgetState();
}

class _ObraListWidgetState extends State<ObraListWidget> {
  List<Obra> obres = [];

  @override
  void initState() {
    super.initState();
    // Carrega les obres en iniciar el widget
    getObres().then((data) {
      setState(() {
        obres = data;
      });
    }).catchError((error) {
      // Aquí podríem gestionar errors, p. ex. mostrant un missatge
      print('Error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Llista d\'obres')),
      body: ListView.builder(
        itemCount: obres.length,
        itemBuilder: (context, index) {
          final obra = obres[index];
          return ListTile(
            title: Text(obra.nom),
            subtitle: Text('${obra.ubicacio} – Inici: ${obra.dataInici}'),
          );
        },
      ),
    );
  }
}
