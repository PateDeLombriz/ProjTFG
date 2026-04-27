import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class EmpresaRegisterHeader extends StatelessWidget {
  const EmpresaRegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outline.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.apartment_rounded,
              size: 42,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Crear compte d’empresa',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dona d’alta la teva empresa per començar a gestionar obres, treballadors i recursos dins l’aplicació.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class EmpresaSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const EmpresaSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class EmpresaFormErrorBanner extends StatelessWidget {
  final String message;

  const EmpresaFormErrorBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.error.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration buildEmpresaInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  final scheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: scheme.primary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withOpacity(0.35),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outline.withOpacity(0.20)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outline.withOpacity(0.16)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.error, width: 1.4),
    ),
  );
}

class EmpresaProfileDropdown extends StatelessWidget {
  const EmpresaProfileDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.person),
      onSelected: (value) {
        switch (value) {
          case 'Perfil':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil seleccionat')),
            );
            break;
          case 'Configuració':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuració seleccionada')),
            );
            break;
          case 'Suggeriments':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Suggeriments seleccionats')),
            );
            break;
          case 'Tancar Sessió':
            _logout(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Perfil', child: Text('Perfil')),
        const PopupMenuItem(value: 'Configuració', child: Text('Configuració')),
        const PopupMenuItem(value: 'Suggeriments', child: Text('Suggeriments')),
        const PopupMenuItem(value: 'Tancar Sessió', child: Text('Tancar Sessió')),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (kIsWeb) {
      html.window.localStorage.clear();
      html.window.sessionStorage.clear();
    }
    Navigator.of(context).pushReplacementNamed('/logIn');
  }
}