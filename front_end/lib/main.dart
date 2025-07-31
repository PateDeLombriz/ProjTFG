import 'package:flutter/material.dart';
import 'package:front_end/screens/base/mainScaffold.dart';
import 'package:front_end/screens/base/splash_screen.dart';

import 'package:front_end/screens/treballador/perfil_treb.dart';
import 'package:front_end/screens/base/log_in.dart';
import 'screens/base/log_in.dart'; // Ruta correcta si tens obra_list.dart a lib/screens
import 'screens/base/registerE.dart'; // Ruta correcta si tens register.dart a lib/screens
import 'screens/obra_edit.dart'; // Ruta correcta si tens obra_create.dart a lib/screens
import 'screens/base/splash_screen.dart'; // Ruta correcta si tens splash_screen.dart a lib/screens
import 'screens/base/root_screen.dart'; 
import 'screens/empresa/obra_form.dart'; // Ruta correcta si tens obra_edit.dart a lib/screens
import 'screens/empresa/home_empresa.dart'; // Ruta correcta si tens home_screen.dart a lib/screens
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
      routes: {
        //Aquestes son les rutes interenes o nominals, no son les que s'utilitzen en el navegador, serveixen per navegar entre pantalles dins de l'aplicació
        
        //IMPORTANT: No totes les pantalles tenen rutes, algunes es mostren directament en la pantalla inicial
        // i no tenen una ruta pròpia. Per exemple, la pantalla d'editarObres no té una ruta pròpia perquè es mostra
        // dins de la pantalla d'ObraList quan es selecciona una obra per editar

        //El meu CRITERI per declarar les rutes és que totes les pantalles que tenen una funció específica i que poden ser accedides directament

        //ENTRADA A L'APLICACIÓ---------------------------------------------------
        '/root': (context) => const RootScreen(), // Pantalla inicial , guarda inici de sessui i escollegix les pantalles que es mostre
        //ENREGISTRAMENT D'USUARI------------------------------------------------
        '/logIn': (context) => const LoginScreen(),
        '/register':(context) => const RegisterScreen(), // Pantalla de registre, encara no s'utilitza

        //HOME SCREEN--------------------------------------------------------
        '/home': (context) => const MainScaffold(),
        //'/perfilU': (context) => const TreballadorProfileScreen(),
      },
      
      
    );

  }
}
