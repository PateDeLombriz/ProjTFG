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

    debugPrint('[SESSION] access: ${prefs.getString('access') != null}');
    debugPrint('[SESSION] token: ${prefs.getString('token') != null}');
    debugPrint('[SESSION] tipus local: ${prefs.getString('tipus')}');

    // L'únic imprescindible localment és tenir un access token.
    if (token == null || token.isEmpty) {
      debugPrint('[SESSION] No hi ha token guardat.');

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

      debugPrint('[SESSION] GET ${ApiConstants.me}');
      debugPrint('[SESSION] status: ${response.statusCode}');
      debugPrint('[SESSION] body: ${response.body}');

      // Només un 401 significa que el JWT ja no és vàlid.
      if (response.statusCode == 401) {
        debugPrint('[SESSION] Token no vàlid. Esborra sessió.');

        await clearSession();

        return {
          'loggedIn': false,
          'role': null,
        };
      }

      // Un 500, 404, error backend, etc. NO implica que
      // l'usuari hagi deixat d'estar autenticat.
      if (response.statusCode != 200) {
        debugPrint(
          '[SESSION] Error del servidor validant sessió: '
          '${response.statusCode}',
        );

        return {
          'loggedIn': false,
          'role': null,
          'error': true,
        };
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      final String? backendRoleRaw =
          data['tipus']?.toString().trim().toLowerCase();

      if (backendRoleRaw == null ||
          (backendRoleRaw != 'empresa' && backendRoleRaw != 'treballador')) {
        debugPrint(
          '[SESSION] Rol retornat pel backend no vàlid: $backendRoleRaw',
        );

        return {
          'loggedIn': false,
          'role': null,
        };
      }

// A partir d'aquí sabem segur que és un String vàlid.
      final String backendRole = backendRoleRaw;

      await prefs.setString('tipus', backendRole);

      if (data['subject_id'] != null) {
        await prefs.setString(
          'subject_id',
          data['subject_id'].toString(),
        );
      }

      if (data['id_empresa'] != null) {
        await prefs.setString(
          'id_empresa',
          data['id_empresa'].toString(),
        );
      }

      debugPrint(
        '[SESSION] Sessió vàlida. Rol: $backendRole',
      );

      return {
        'loggedIn': true,
        'role': backendRole,
      };
    } catch (e) {
      debugPrint(
        '[SESSION] Error de xarxa validant token: $e',
      );

      // Important: no esborram el token per un error de xarxa.
      return {
        'loggedIn': false,
        'role': null,
        'error': true,
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
