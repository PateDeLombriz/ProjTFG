// register_screen.dart — Pantalla de registre d'empresa amb totes les relacions correctes
// Crea Usuari → UEmpresa → Contrasenya seguint els models del backend.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Les contrasenyes no coincideixen');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      /* ────────────────────────────────
       * 1) Crear Usuari (tipus = EMPRESA)
       * ──────────────────────────────── */
      final usuariRes = await http.post(
        Uri.parse('http://localhost:8000/api/usuaris/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipus': 'EMPRESA', // coincideix amb choices de UsuariTipus
          'telefon': int.tryParse(_phoneController.text),
        }),
      );

      if (usuariRes.statusCode != 201) {
        throw _parseBackendError('Error al crear usuari', usuariRes);
      }

      final int usuariId = jsonDecode(usuariRes.body)['id'];

      /* ────────────────────────────────
       * 2) Crear UEmpresa vinculada
       * ──────────────────────────────── */
      final empresaRes = await http.post(
        Uri.parse('http://localhost:8000/api/empreses/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuari': usuariId, // FK → Usuari
          'nom': _nameController.text,
          'correu': _emailController.text,
        }),
      );

      if (empresaRes.statusCode != 201) {
        throw _parseBackendError('Error al crear empresa', empresaRes);
      }

      /* ────────────────────────────────
       * 3) Desa contrasenya
       * ──────────────────────────────── */
      final pwdRes = await http.post(
        Uri.parse('http://localhost:8000/api/contrasenyes/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuari': usuariId,
          'clau': _passwordController.text,
          'data_creacio': DateTime.now().toIso8601String(),
        }),
      );

      if (pwdRes.statusCode != 201) {
        throw _parseBackendError('Error al guardar la contrasenya', pwdRes);
      }

      // Èxit: navega a Home
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Empresa registrada!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /* ────────────────────────────────────────────────────────────
   * Helper per convertir errors DRF (400) en text llegible
   * ──────────────────────────────────────────────────────────── */
  Exception _parseBackendError(String prefix, http.Response res) {
    try {
      final Map<String, dynamic> err = jsonDecode(res.body);
      return Exception('$prefix: ${err.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
    } catch (_) {
      return Exception('$prefix (codi ${res.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Registrar-se'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.app_registration, size: 72, color: Colors.blue),
            const SizedBox(height: 12),
            const Text('Registre d\'empresa',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nameController, 'Nom de l\'empresa', Icons.business),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Correu electrònic', Icons.email,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Telèfon de contacte', Icons.phone,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildPasswordField(_passwordController, 'Contrasenya'),
                  const SizedBox(height: 16),
                  _buildPasswordField(_confirmPasswordController, 'Confirma la contrasenya'),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save),
                    label: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Registrar-se'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ───────────────────────── Helpers UI ────────────────────── */
  Widget _buildTextField(TextEditingController c, String label, IconData icn,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icn),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Introdueix $label' : null,
    );
  }

  Widget _buildPasswordField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Introdueix $label' : null,
    );
  }
}
