import 'package:flutter/material.dart';
import 'package:front_end/models/empresa_models.dart';
import 'package:front_end/screens/base/register_confirmation_screen.dart';
import 'package:front_end/shared/services/AuthServices.dart';
import 'package:front_end/widgets/empresa_widgets.dart';
import 'package:http/http.dart' as http;

class RegisterEmpresaScreen extends StatefulWidget {
  const RegisterEmpresaScreen({super.key});

  @override
  State<RegisterEmpresaScreen> createState() => _RegisterEmpresaScreenState();
}

class _RegisterEmpresaScreenState extends State<RegisterEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomEmpresaController = TextEditingController();
  final _cifController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _personaContacteController = TextEditingController();
  final _sectorController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      client: http.Client(),
    );
  }

  @override
  void dispose() {
    _nomEmpresaController.dispose();
    _cifController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _personaContacteController.dispose();
    _sectorController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final input = EmpresaRegisterInput(
        nomEmpresa: _nomEmpresaController.text,
        cif: _cifController.text,
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
        telefon: _telefonController.text.trim().isEmpty
            ? null
            : _telefonController.text,
        personaContacte: _personaContacteController.text.trim().isEmpty
            ? null
            : _personaContacteController.text,
        sector: _sectorController.text.trim().isEmpty
            ? null
            : _sectorController.text,
      );

      final result = await _authService.registerEmpresa(input);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailConfirmationSentScreen(
            email: result.email,
            message: result.message,
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperat: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Introdueix $label';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final base = _validateRequired(value, 'el correu electrònic');
    if (base != null) return base;

    final email = value!.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'Introdueix un correu vàlid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final base = _validateRequired(value, 'la contrasenya');
    if (base != null) return base;

    if (value!.length < 8) {
      return 'La contrasenya ha de tenir mínim 8 caràcters';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    final base = _validateRequired(value, 'la confirmació de contrasenya');
    if (base != null) return base;

    if (value != _passwordController.text) {
      return 'Les contrasenyes no coincideixen';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Registrar empresa'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EmpresaRegisterHeader(),
                    const SizedBox(height: 18),

                    EmpresaSectionCard(
                      title: 'Dades principals',
                      icon: Icons.business_center_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nomEmpresaController,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Nom de l’empresa',
                              icon: Icons.business_center,
                            ),
                            validator: (v) =>
                                _validateRequired(v, 'el nom de l’empresa'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _cifController,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'CIF',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) => _validateRequired(v, 'el CIF'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Correu electrònic',
                              icon: Icons.alternate_email_rounded,
                            ),
                            validator: _validateEmail,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    EmpresaSectionCard(
                      title: 'Informació addicional',
                      icon: Icons.contact_phone_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _telefonController,
                            keyboardType: TextInputType.phone,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Telèfon (opcional)',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _personaContacteController,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Persona de contacte (opcional)',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _sectorController,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Sector (opcional)',
                              icon: Icons.work_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    EmpresaSectionCard(
                      title: 'Seguretat del compte',
                      icon: Icons.lock_outline_rounded,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Contrasenya',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordConfirmController,
                            obscureText: _obscurePasswordConfirm,
                            decoration: buildEmpresaInputDecoration(
                              context,
                              label: 'Confirmar contrasenya',
                              icon: Icons.lock_reset_outlined,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePasswordConfirm =
                                        !_obscurePasswordConfirm;
                                  });
                                },
                                icon: Icon(
                                  _obscurePasswordConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePasswordConfirm,
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      EmpresaFormErrorBanner(message: _errorMessage!),
                    ],

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    scheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text(
                                'Crear compte',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'En completar el registre, t’enviarem un correu per verificar el compte.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}