// Aquesta pantalla (`RootScreen`) comprova si hi ha una sessió d’usuari activa utilitzant `SharedPreferences`.
// Si hi ha un token i un rol guardats, redirigeix automàticament a la pantalla corresponent segons el rol ('empresa' o 'usuari').
// Si no hi ha sessió iniciada, es mostra la `SplashScreen` com a pantalla de benvinguda.
// Es fa servir un `FutureBuilder` per esperar l’accés a les preferències compartides i mostrar un indicador de càrrega mentrestant.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'package:front_end/screens/empresa/home_empresa.dart';

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
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
