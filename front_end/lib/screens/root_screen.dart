//Redirigeix a la pantalla inicial depenent de l'usuari que ha entrat
// Si no hi ha cap usuari, redirigeix a la pantalla de benvinguda

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'package:front_end/screens/empresa/home_empresa.dart';
import 'package:front_end/screens/usuari/home_usuari.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  Future<Map<String, dynamic>> getSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token');
    final role = prefs.getString('user_role'); // 'empresa' o 'usuari'
    
    if (token != null && role != null) {
      return {
        'loggedIn': true,
        'role': role,
      };
    } else {
      return {'loggedIn': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getSessionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data!;
        if (!session['loggedIn']) {
          return const SplashScreen();
        }

        switch (session['role']) {
          case 'empresa':
            return const HomeEmpresa();
          case 'usuari':
            return const HomeScreen();
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
