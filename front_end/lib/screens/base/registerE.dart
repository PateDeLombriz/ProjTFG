// register_screen.dart — Registre d'EMPRESA (model nou) amb Ubicacio i Contrasenya hash (Django PBKDF2)
// Flux: (opcional) POST /ubicacio(ns)/ -> id  →  POST /empreses/ -> id  →  POST /contrasenyes/ amb id_empresa + hash
import 'dart:convert';
import 'dart:math';
//import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ───────────── Config API (ajusta paths si calen) ─────────────
  static const _apiBase = 'http://localhost:8000/api';
  static const _epEmpreses   = '$_apiBase/empreses/';     // POST empresa
  static const _epUbicacions = '$_apiBase/ubicacio/';     // POST ubicació (⚠️ si al teu urls és /ubicacions/, canvia-ho)
  static const _epPwds       = '$_apiBase/contrasenyes/'; // POST contrasenya

  // ───────────── Formulari ─────────────
  final _formKey = GlobalKey<FormState>();

  // Empresa (obligatoris/recomanats)
  final _nameController = TextEditingController();   // nom_empresa
  final _emailController = TextEditingController();  // email (opcional però recomanat si login per email)
  final _phoneController = TextEditingController();  // telefon (opcional)
  final _cifController = TextEditingController();    // CIF (OBLIGATORI)
  final _webController = TextEditingController();    // web (opc)
  final _sectorController = TextEditingController(); // sector (opc)
  final _personaContacteController = TextEditingController(); // persona_contacte (opc)
  final _numEmpleatsController = TextEditingController();     // num_empleats (opc, int)

  // Ubicacio (opcional)
  final _adrecaController = TextEditingController();
  final _ciutatController = TextEditingController();
  final _codiPostalController = TextEditingController();     
  final _provinciaController = TextEditingController();
  final _paisController = TextEditingController(text: 'Espanya');

  // Password
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // ───────────── Helpers Hash (format Django) ─────────────
  String _randomSalt([int length = 12]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  // ───────────── Registre (Ubicacio? -> Empresa -> Contrasenya hash) ─────────────
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
      final nomEmpresa = _nameController.text.trim();
      final cif        = _cifController.text.trim();
      final email      = _emailController.text.trim();
      final telefon    = _phoneController.text.trim();

      if (cif.isEmpty) {
        throw Exception('Cal indicar el CIF');
      }

      // 1) (Opcional) Crear UBICACIO si hi ha alguna dada
      int? ubicacioId;
      final haveUbicacio = [
        _adrecaController.text,
        _ciutatController.text,
        _codiPostalController.text,
        _provinciaController.text,
        _paisController.text,
      ].any((v) => v.trim().isNotEmpty);

      if (haveUbicacio) {
        final uRes = await http.post(
          Uri.parse(_epUbicacions),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'adreca': _adrecaController.text.trim(),
            'ciutat': _ciutatController.text.trim(),
            'codi_postal': _codiPostalController.text.trim(),
            'provincia': _provinciaController.text.trim(),
            'pais': _paisController.text.trim().isEmpty ? 'Espanya' : _paisController.text.trim(),
          }),
        );
        if (uRes.statusCode != 201) {
          throw _parseBackendError('Error creant ubicació', uRes);
        }
        final uBody = jsonDecode(uRes.body) as Map<String, dynamic>;
        // El serializer de Ubicacio sol retornar 'id'
        ubicacioId = (uBody['id'] as num).toInt();
      }

      // 2) Crear EMPRESA
      final eRes = await http.post(
        Uri.parse(_epEmpreses),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom_empresa': nomEmpresa,
          'cif': cif,
          'email': email.isEmpty ? null : email,
          'telefon': telefon.isEmpty ? null : telefon,
          'web': _webController.text.trim().isEmpty ? null : _webController.text.trim(),
          'sector': _sectorController.text.trim().isEmpty ? null : _sectorController.text.trim(),
          'persona_contacte': _personaContacteController.text.trim().isEmpty ? null : _personaContacteController.text.trim(),
          'num_empleats': int.tryParse(_numEmpleatsController.text.trim()),
          if (ubicacioId != null) 'ubicacio': ubicacioId, // FK pel serializer
        }),
      );
      if (eRes.statusCode != 201) {
        throw _parseBackendError('Error creant empresa', eRes);
      }
      final eBody = jsonDecode(eRes.body) as Map<String, dynamic>;
      final empresaId = (eBody['id'] as num).toInt(); // serializer de Empresa sol retornar 'id'

      // 3) Hash + CONTRASENYA (XOR → id_empresa)
     // final pwdHash = await _djangoHash(_passwordController.text);
      final pRes = await http.post(
        Uri.parse(_epPwds),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_empresa': empresaId,
          'clau': _passwordController.text, // <-- ja encriptada (format Django)
          'data_creacio': DateTime.now().toIso8601String(),
        }),
      );
      if (pRes.statusCode != 201) {
        throw _parseBackendError('Error creant contrasenya', pRes);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa registrada correctament')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ───────────── Helper per errors DRF ─────────────
  Exception _parseBackendError(String prefix, http.Response res) {
    try {
      final Map<String, dynamic> err = jsonDecode(res.body);
      return Exception('$prefix: ${err.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
    } catch (_) {
      return Exception('$prefix (codi ${res.statusCode})');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cifController.dispose();
    _webController.dispose();
    _sectorController.dispose();
    _personaContacteController.dispose();
    _numEmpleatsController.dispose();
    _adrecaController.dispose();
    _ciutatController.dispose();
    _codiPostalController.dispose();
    _provinciaController.dispose();
    _paisController.dispose();
    super.dispose();
    super.dispose();
  }

  // ───────────── UI ─────────────
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
            const Text(
              'Registre d\'empresa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nameController, 'Nom de l\'empresa', Icons.business),
                  const SizedBox(height: 16),
                  _buildTextField(_cifController, 'CIF', Icons.badge),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Correu electrònic', Icons.email,
                      keyboard: TextInputType.emailAddress, required: false),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Telèfon de contacte', Icons.phone,
                      keyboard: TextInputType.phone, required: false),
                  const SizedBox(height: 16),
                  _buildPasswordField(_passwordController, 'Contrasenya'),
                  const SizedBox(height: 16),
                  _buildPasswordField(_confirmPasswordController, 'Confirma la contrasenya'),
                  const SizedBox(height: 16),
                  _buildTextField(_webController, 'Web (opcional)', Icons.link,
                      keyboard: TextInputType.url, required: false),
                  const SizedBox(height: 16),
                  _buildTextField(_sectorController, 'Sector (opcional)', Icons.business_center,
                      required: false),
                  const SizedBox(height: 16),
                  _buildTextField(_personaContacteController, 'Persona de contacte (opcional)', Icons.person,
                      required: false),
                  const SizedBox(height: 16),
                  _buildTextField(_numEmpleatsController, 'Número d\'empleats (opcional)', Icons.groups,
                      keyboard: TextInputType.number, required: false),

                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ubicació (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_adrecaController, 'Adreça', Icons.home, required: false),
                  const SizedBox(height: 12),
                  _buildTextField(_ciutatController, 'Ciutat', Icons.location_city, required: false),
                  const SizedBox(height: 12),
                  _buildTextField(_codiPostalController, 'Codi postal', Icons.markunread_mailbox, required: false),
                  const SizedBox(height: 12),
                  _buildTextField(_provinciaController, 'Província', Icons.map, required: false),
                  const SizedBox(height: 12),
                  _buildTextField(_paisController, 'País', Icons.public, required: false),

                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _register,
                      icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
                      label: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Registrar-se'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  // ───────────── Helpers UI ─────────────
  String? _requiredOrNull(String? v, String label, {bool required = true}) {
    if (!required) return null;
    return (v == null || v.isEmpty) ? 'Introdueix $label' : null;
  }

  Widget _buildTextField(
    TextEditingController c,
    String label,
    IconData icn, {
    TextInputType keyboard = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icn),
      ),
      validator: (v) => _requiredOrNull(v, label, required: required),
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
      validator: (v) => _requiredOrNull(v, label),
    );
  }
}
