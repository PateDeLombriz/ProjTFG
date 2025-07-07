import 'package:flutter/material.dart';
import 'package:front_end/screens/splash_screen.dart';
import 'screens/obra_list.dart'; // Ruta correcta si tens obra_list.dart a lib/screens
import 'screens/obra_edit.dart'; // Ruta correcta si tens obra_create.dart a lib/screens
import 'screens/splash_screen.dart'; // Ruta correcta si tens splash_screen.dart a lib/screens
import 'screens/root_screen.dart'; 
import 'screens/empresa/obra_form.dart'; // Ruta correcta si tens obra_edit.dart a lib/screens
import 'screens/empresa/home_empresa.dart'; // Ruta correcta si tens home_screen.dart a lib/screens
import 'screens/usuari/home_usuari.dart'; // Ruta correcta si tens home_usuari.dart a lib/screens
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
      initialRoute: '/root',
      routes: {//Aquestes son les rutes interenes, no son les que s'utilitzen en el navegador, serveixen per navegar entre pantalles dins de l'aplicació
        '/root': (context) => const RootScreen(), // Pantalla inicial , guarda inici de sessui i escollegix les pantalles que es mostre
        // depenent de l'usuari qu e ha entrarçt
        '/list': (context) => const ObraList(),
        //'/edit': (context) => const ObraEdit(), // Fa falta passsar un id de la obra per editar, encara no s'utilitza
        

        ///EMPRESA---------------------------------------------------------------------
        '/homeE': (context) => const HomeEmpresa(),
        //USUARI------------------------------------------------------------------
        '/homeU': (context) => const HomeScreen(),
        
      },
    );
  }
}
