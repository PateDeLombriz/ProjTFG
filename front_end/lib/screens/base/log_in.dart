// lib/screen/login/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../treballador/perfil_treb.dart'; // ← rutes reals
import '../empresa/home_empresa.dart'; // ← rutes reals

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
  final _storage = const FlutterSecureStorage();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse('http://localhost:8000/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identificador': _identController.text.trim(),
          'password': _passController.text,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _storage.write(key: 'token', value: data['token']);

        if (!mounted) return;
        if (data['tipus'] == 'TREBALLADOR') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => TreballadorProfileScreen(usuariId: data['user_id']),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeEmpresa()),
          );
        }
      } else {
        setState(() {
          _error = jsonDecode(res.body)['detail'] ?? 'Credencials incorrectes';
        });
      }
    } catch (e) {
      setState(() => _error = 'Error de connexió: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Introdueix el camp'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscurePassword,
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
                      validator:
                          (v) =>
                              v == null || v.isEmpty
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
                        child:
                            _loading
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
