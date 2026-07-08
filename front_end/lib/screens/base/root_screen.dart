import 'package:flutter/material.dart';
import 'package:front_end/screens/base/mainScaffold.dart';
import 'package:front_end/screens/treballador/treballador_main_scaffold.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  Future<Map<String, dynamic>> getSessionInfo() async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString('access') ?? prefs.getString('token');
  final localRole = prefs.getString('tipus');


  if (token == null || token.isEmpty || localRole == null || localRole.isEmpty) {
    return {
      'loggedIn': false,
      'role': null,
    };
  }

  try {
    final response = await http.get(
      Uri.parse(ApiConstants.me),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );


    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearSession();

      return {
        'loggedIn': false,
        'role': null,
      };
    }

    if (response.statusCode != 200) {
      return {
        'loggedIn': false,
        'role': null,
      };
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    final backendRole =
        data['tipus']?.toString().toLowerCase() ??
        data['role']?.toString().toLowerCase() ??
        localRole;

    return {
      'loggedIn': true,
      'role': backendRole,
    };
  } catch (e) {
    debugPrint('[SESSION] error validating token: $e');

    return {
      'loggedIn': false,
      'role': null,
    };
  }
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('token');
  await prefs.remove('access');
  await prefs.remove('refresh');
  await prefs.remove('tipus');
  await prefs.remove('role');
  await prefs.remove('subject_id');
  await prefs.remove('loggedIn');
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getSessionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: AppLoadingIndicator(),
          );
        }

        final session = snapshot.data!;
        //Revisar si l'usuari està loguejat i quin rol té per decidir quina pantalla mostrar en el backend. Si no està loguejat, mostrar SplashScreen. Si està loguejat, mostrar la pantalla corresponent segons el rol.
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
