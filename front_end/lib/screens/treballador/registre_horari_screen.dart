import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/themes/app_colors.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';

class RegistreHorariScreen extends StatefulWidget {
  const RegistreHorariScreen({super.key});

  @override
  State<RegistreHorariScreen> createState() => _RegistreHorariScreenState();
}

class _RegistreHorariScreenState extends State<RegistreHorariScreen> {
  late final TreballadorService _service;
  late Future<List<Map<String, dynamic>>> _future;

  bool _actionLoading = false;
  String? _actionError;
  String? _actionSuccess;

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _apiBase);
    _future = _service.fetchMyRegistreHorari();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchMyRegistreHorari();
      _actionError = null;
      _actionSuccess = null;
    });
    await _future;
  }

  Future<void> _fitxarEntrada() async {
    setState(() {
      _actionLoading = true;
      _actionError = null;
      _actionSuccess = null;
    });
    try {
      await _service.fitxarEntrada();
      if (!mounted) return;
      setState(() {
        _actionSuccess = 'Entrada registrada correctament.';
      });
      await _reload();
    } on TreballadorServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _fitxarSortida() async {
    setState(() {
      _actionLoading = true;
      _actionError = null;
      _actionSuccess = null;
    });
    try {
      await _service.fitxarSortida();
      if (!mounted) return;
      setState(() {
        _actionSuccess = 'Sortida registrada correctament.';
      });
      await _reload();
    } on TreballadorServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  bool _teEntradaOberta(List<Map<String, dynamic>> registres) {
    return registres.any(
      (r) => r['data_sortida'] == null || r['data_sortida'] == '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        title: const Text('Control horari'),
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant registre...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final registres = snapshot.data ?? [];
          final teEntradaOberta = _teEntradaOberta(registres);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              children: [
                _FitxarCard(
                  teEntradaOberta: teEntradaOberta,
                  isLoading: _actionLoading,
                  error: _actionError,
                  success: _actionSuccess,
                  onFitxarEntrada: _fitxarEntrada,
                  onFitxarSortida: _fitxarSortida,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Historial de jornades',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (registres.isEmpty)
                  _HistorialBuit()
                else
                  ...registres.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RegistreItem(registre: r),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FitxarCard extends StatelessWidget {
  final bool teEntradaOberta;
  final bool isLoading;
  final String? error;
  final String? success;
  final VoidCallback onFitxarEntrada;
  final VoidCallback onFitxarSortida;

  const _FitxarCard({
    required this.teEntradaOberta,
    required this.isLoading,
    required this.error,
    required this.success,
    required this.onFitxarEntrada,
    required this.onFitxarSortida,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: teEntradaOberta
                      ? AppColors.successSoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  teEntradaOberta
                      ? Icons.timer_outlined
                      : Icons.timer_off_outlined,
                  color: teEntradaOberta ? AppColors.success : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teEntradaOberta ? 'Jornada en curs' : 'Fora de jornada',
                    style: AppTextStyles.titleMedium,
                  ),
                  Text(
                    teEntradaOberta
                        ? 'Pots registrar la sortida'
                        : 'Pots registrar l\'entrada',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FeedbackBanner(text: error!, isError: true),
          ],
          if (success != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FeedbackBanner(text: success!, isError: false),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (!teEntradaOberta)
            AppPrimaryButton(
              label: 'Fichar entrada',
              icon: Icons.login_rounded,
              isLoading: isLoading,
              onPressed: isLoading ? null : onFitxarEntrada,
            )
          else
            AppPrimaryButton(
              label: 'Fichar sortida',
              icon: Icons.logout_rounded,
              isLoading: isLoading,
              onPressed: isLoading ? null : onFitxarSortida,
            ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool isError;

  const _FeedbackBanner({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorSoft : AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: isError ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}

class _RegistreItem extends StatelessWidget {
  final Map<String, dynamic> registre;

  const _RegistreItem({required this.registre});

  String _formatDatetime(dynamic value) {
    if (value == null) return '—';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $h:$m';
  }

  String _durada(dynamic entrada, dynamic sortida) {
    if (entrada == null || sortida == null) return '—';
    final dtE =
        entrada is DateTime ? entrada : DateTime.tryParse(entrada.toString());
    final dtS =
        sortida is DateTime ? sortida : DateTime.tryParse(sortida.toString());
    if (dtE == null || dtS == null) return '—';
    final diff = dtS.difference(dtE);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  @override
  Widget build(BuildContext context) {
    final entrada = registre['data_entrada'];
    final sortida = registre['data_sortida'];
    final obert = sortida == null || sortida == '';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: obert ? AppColors.success : AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDatetime(entrada),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      obert ? 'En curs...' : _formatDatetime(sortida),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: obert ? AppColors.success : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!obert)
            Text(
              _durada(entrada, sortida),
              style: AppTextStyles.labelMedium,
            ),
          if (obert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Actiu',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorialBuit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history_outlined,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sense historial',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
