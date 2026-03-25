import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../base/mainScaffold.dart';
import '../treballador/perfil_treb.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _identController = TextEditingController();
  final _passController = TextEditingController();

  // IMPORTANT:
  // - Flutter Web al mateix PC: localhost
  // - Android emulator: 10.0.2.2
  // - dispositiu físic: IP LAN del PC
  static String get _apiBase {
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/';
  }
  return 'http://localhost:8000/api/';
}

  static String get _apiLogin => '${_apiBase}login/';

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiLogin),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginField': _identController.text.trim(),
          'password': _passController.text,
        }),
      );

      final rawBody = utf8.decode(response.bodyBytes);
      debugPrint('LOGIN status=${response.statusCode}');
      debugPrint('LOGIN body=$rawBody');
      debugPrint('LOGIN headers=${response.headers}');

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(rawBody) as Map<String, dynamic>;
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 && data != null) {
        final access = data['access']?.toString();
        final refresh = data['refresh']?.toString();
        final tipus = data['tipus']?.toString().toLowerCase();
        final subjectId = _parseInt(data['subject_id']);

        if (access == null ||
            access.isEmpty ||
            refresh == null ||
            refresh.isEmpty ||
            tipus == null ||
            tipus.isEmpty ||
            subjectId == null) {
          setState(() {
            _error = 'Resposta de login incompleta.';
          });
          return;
        }

        await _saveSession(
          access: access,
          refresh: refresh,
          tipus: tipus,
          subjectId: subjectId,
        );

        if (!mounted) return;

        if (tipus == 'treballador') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TreballadorProfileScreen(
                usuariId: subjectId,
              ),
            ),
          );
          return;
        }

        if (tipus == 'empresa') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainScaffold(),
            ),
          );
          return;
        }

        setState(() {
          _error = 'Tipus d\'usuari desconegut: $tipus';
        });
        return;
      }

      setState(() {
        _error = _extractErrorMessage(data, rawBody, response.statusCode);
      });
    } catch (e) {
      setState(() {
        _error = 'Error de connexió: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _extractErrorMessage(
    Map<String, dynamic>? data,
    String rawBody,
    int statusCode,
  ) {
    if (data == null) {
      return 'Error $statusCode: $rawBody';
    }

    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final nonFieldErrors = data['non_field_errors'];
    if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
      return nonFieldErrors.first.toString();
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Credencials incorrectes.';
  }

  Future<void> _saveSession({
    required String access,
    required String refresh,
    required String tipus,
    required int subjectId,
  }) async {
    final sp = await SharedPreferences.getInstance();

    // Mantinc "token" per compatibilitat amb codi antic del projecte.
    await sp.setString('token', access);

    // Claus noves explícites.
    await sp.setString('access', access);
    await sp.setString('refresh', refresh);
    await sp.setString('tipus', tipus);
    await sp.setInt('subject_id', subjectId);

    debugPrint('SESSION saved -> tipus=$tipus, subject_id=$subjectId');
  }

  Future<String> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('token') ?? '';
  }

  Future<int?> getSubjectId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('subject_id');
  }

  Future<String?> getTipus() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('tipus');
  }

  Future<bool> clearToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Inici de Sessió',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _identController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname o correu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Introdueix el camp' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Contrasenya',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Introdueix la contrasenya'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            68,
                            98,
                            133,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
