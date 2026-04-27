import 'package:flutter/material.dart';

class EmailConfirmationSentScreen extends StatelessWidget {
  final String email;
  final String message;

  const EmailConfirmationSentScreen({
    super.key,
    required this.email,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 88,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Correu de verificació enviat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'T’hem enviat un correu per verificar el teu compte.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Tornar a iniciar sessió'),
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