import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/themes/app_colors.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';

/// Pantalla per marcar una tasca com a finalitzada pendent de revisio.
///
/// Rep [tascaId] i [tascaDescripcio] per mostrar context a l'usuari.
/// Crida PATCH /treballadors/me/tasques/<id>/finalitzar/ al confirmar.
/// En cas d'exit, fa pop(true) per notificar la pantalla anterior.
class FinalitzarTascaScreen extends StatefulWidget {
  final int tascaId;
  final String tascaDescripcio;

  const FinalitzarTascaScreen({
    super.key,
    required this.tascaId,
    required this.tascaDescripcio,
  });

  @override
  State<FinalitzarTascaScreen> createState() => _FinalitzarTascaScreenState();
}

class _FinalitzarTascaScreenState extends State<FinalitzarTascaScreen> {
  late final TreballadorService _service;

  bool _loading = false;
  String? _error;

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _apiBase);
  }

  Future<void> _confirmar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.finalitzarTasca(widget.tascaId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TreballadorServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // CANVI 1+2: sense backgroundColor explícit ni colors d'AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalitzar tasca'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Confirmar finalització',
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "Estàs a punt de marcar la tasca com a finalitzada pendent de revisió:",
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tascaDescripcio.isEmpty
                          ? 'Tasca #${widget.tascaId}'
                          : widget.tascaDescripcio,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "L'empresa haurà de revisar i aprovar la finalització.",
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
            const Spacer(),
            AppPrimaryButton(
              label: 'Confirmar finalització',
              icon: Icons.check_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _confirmar,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed:
                  _loading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel·lar'),
            ),
          ],
        ),
      ),
    );
  }
}

