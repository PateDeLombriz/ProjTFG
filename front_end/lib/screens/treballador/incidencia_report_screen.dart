import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/services/incidencia_service.dart';
import 'package:front_end/shared/themes/app_colors.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';

/// Pantalla per reportar una incidencia des d'una tasca assignada.
///
/// Requereix [tascaId] (obligatori al backend per a treballadors).
/// Opcionalment rep [tascaDescripcio] per mostrar context.
/// En cas d'exit, fa pop(true) per notificar la pantalla anterior.
///
/// PREREQUISIT BACKEND:
///   views_Modif.py CANVI 3 — IncidenciaList.post ha de permetre treballadors
///   amb id_tasca assignada.
class IncidenciaReportScreen extends StatefulWidget {
  final int tascaId;
  final String? tascaDescripcio;

  const IncidenciaReportScreen({
    super.key,
    required this.tascaId,
    this.tascaDescripcio,
  });

  @override
  State<IncidenciaReportScreen> createState() => _IncidenciaReportScreenState();
}

class _IncidenciaReportScreenState extends State<IncidenciaReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcioCtrl = TextEditingController();

  late final IncidenciaService _service;

  int _prioritat = 3;
  int _criticitat = 3;

  bool _loading = false;
  String? _error;

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = IncidenciaService();
  }

  @override
  void dispose() {
    _descripcioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.createIncidencia({
        'id_tasca': widget.tascaId,
        'descripcio': _descripcioCtrl.text.trim(),
        'prioritat': _prioritat,
        'criticitat': _criticitat,
        'data_inici': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on IncidenciaServiceException catch (e) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        title: const Text('Reportar incidència'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            if (widget.tascaDescripcio != null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.tascaDescripcio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Descripció de la incidència', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _descripcioCtrl,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Descriu la incidència amb detall...',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'La descripció és obligatòria'
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nivell de prioritat', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Valor: $_prioritat (1 = baixa, 5 = molt alta)',
                    style: AppTextStyles.bodySmall,
                  ),
                  Slider(
                    value: _prioritat.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_prioritat',
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _prioritat = v.round()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nivell de criticitat', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Valor: $_criticitat (1 = baixa, 5 = crítica)',
                    style: AppTextStyles.bodySmall,
                  ),
                  Slider(
                    value: _criticitat.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_criticitat',
                    activeColor: AppColors.error,
                    onChanged: (v) => setState(() => _criticitat = v.round()),
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
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: 'Enviar incidència',
              icon: Icons.send_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _enviar,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel·lar'),
            ),
          ],
        ),
      ),
    );
  }
}
