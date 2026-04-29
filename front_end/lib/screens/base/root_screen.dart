import 'package:flutter/material.dart';
import 'package:front_end/screens/base/mainScaffold.dart';
import 'package:front_end/screens/treballador/treballador_main_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  Future<Map<String, dynamic>> getSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('tipus');

    if (token != null && role != null) {
      return {'loggedIn': true, 'role': role};
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
            return const MainScaffold();
          // CANVI 3: treballador → TreballadorMainScaffold
          case 'treballador':
            return const TreballadorMainScaffold();
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
