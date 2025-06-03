import 'package:flutter/material.dart';
import 'screens/obra_list.dart'; // Ruta correcta si tens obra_list.dart a lib/screens
import 'screens/obra_edit.dart'; // Ruta correcta si tens obra_create.dart a lib/screens
import 'screens/obra_form.dart'; // Ruta correcta si tens obra_edit.dart a lib/screens
import 'models/obra.dart'; // Ruta correcta si tens obra.dart a lib/models
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestió d\'Obres',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => const ObraList(),
        '/create': (context) => const ObraForm(),
        //'/edit': (context) => const ObraEdit(), // Ex: quan li passis una obra
      },
    );
  }
}
