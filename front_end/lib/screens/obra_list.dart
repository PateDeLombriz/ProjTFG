import 'package:flutter/material.dart';
import '../models/obra.dart';
import '../services/api_service.dart';

class ObraList extends StatefulWidget {
  const ObraList({super.key});

  @override
  State<ObraList> createState() => _ObraListState();
}

class _ObraListState extends State<ObraList> {
  late Future<List<Obra>> obres;

  @override
  void initState() {
    super.initState();
    obres = getObres();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Llista d\'Obres'),
      ),
      body: FutureBuilder<List<Obra>>(
        future: obres,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('No hi ha obres disponibles.'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final obra = data[index];
              return ListTile(
                title: Text(obra.Nom),
                subtitle: Text('Ubicació: ${obra.Ubicacio ?? "-"}'),
                trailing: Text(obra.Estat),
              );
            },
          );
        },
      ),
    );
  }
}
