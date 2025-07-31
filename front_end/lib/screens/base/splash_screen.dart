import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPrimary = Colors.indigo[700]; // to suau i agradable

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─────────────── Logo ───────────────
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorPrimary!.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(Icons.construction, size: 64, color: colorPrimary),
                  ),
                ),
                const SizedBox(height: 32),

                // ─────────────── Títol ───────────────
                Text(
                  'Benvingut a ObraÀgil',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ─────────────── Subtítol ───────────────
                Text(
                  'Gestiona les teves obres de manera fàcil i ràpida',
                  style: theme.textTheme.bodyMedium!.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // ─────────────── Botó Login ───────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/logIn'),
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar Sessió'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─────────────── Botó Registrar Empresa ───────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    icon: const Icon(Icons.app_registration),
                    label: const Text('Registrar Empresa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorPrimary,
                      side: BorderSide(color: colorPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
