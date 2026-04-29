
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/screens/treballador/perfil_treb.dart';
import 'package:front_end/screens/treballador/registre_horari_screen.dart';
import 'package:front_end/screens/treballador/treballador_tasques_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/themes/app_colors.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';

class TreballadorHomeScreen extends StatefulWidget {
  const TreballadorHomeScreen({super.key});

  @override
  State<TreballadorHomeScreen> createState() => _TreballadorHomeScreenState();
}

class _TreballadorHomeScreenState extends State<TreballadorHomeScreen> {
  late final TreballadorService _service;
  late Future<_HomeData> _future;

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _apiBase);
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final results = await Future.wait([
      _service.fetchMyProfile(),
      _service.fetchMyTasques(),
    ]);
    return _HomeData(
      profile: results[0] as TreballadorProfileData,
      tasques: results[1] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CANVI 2+3: AppBar usa tema per defecte (fons clar, = estil empresa)
      appBar: AppBar(
        title: const Text('Inici'),
        automaticallyImplyLeading: false,
        actions: [
          // CANVI 4: sense botó de logout (passa a la pestanya Perfil)
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          return _HomeContent(
            data: data,
            onReload: _reload,
            onNavigateTasques: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TreballadorTasquesScreen()),
            ),
            onNavigateRegistre: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistreHorariScreen()),
            ),
            onNavigatePerfil: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TreballadorProfileScreen()),
            ),
          );
        },
      ),
    );
  }
}

class _HomeData {
  final TreballadorProfileData profile;
  final List<Map<String, dynamic>> tasques;

  const _HomeData({required this.profile, required this.tasques});

  int countByEstat(String estat) =>
      tasques.where((t) => t['estat'] == estat).length;
}

class _HomeContent extends StatelessWidget {
  final _HomeData data;
  final Future<void> Function() onReload;
  final VoidCallback onNavigateTasques;
  final VoidCallback onNavigateRegistre;
  final VoidCallback onNavigatePerfil;

  const _HomeContent({
    required this.data,
    required this.onReload,
    required this.onNavigateTasques,
    required this.onNavigateRegistre,
    required this.onNavigatePerfil,
  });

  @override
  Widget build(BuildContext context) {
    final pendent = data.countByEstat('pendent');
    final enCurs = data.countByEstat('en_curs');
    final pendentRevisio = data.countByEstat('finalitzada_pendent_revisio');

    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          _GreetingHeader(profile: data.profile),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Pendents',
                    count: pendent,
                    color: AppColors.warning,
                    softColor: AppColors.warningSoft,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'En curs',
                    count: enCurs,
                    color: AppColors.info,
                    softColor: AppColors.infoSoft,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Pend. revisió',
                    count: pendentRevisio,
                    color: AppColors.secondary,
                    softColor: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Control horari',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Registra la teva entrada o sortida de la jornada.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    label: 'Fichar entrada / sortida',
                    icon: Icons.login_rounded,
                    onPressed: onNavigateRegistre,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Text('Accions ràpides', style: AppTextStyles.labelLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    label: 'Les meves tasques',
                    icon: Icons.assignment_outlined,
                    onTap: onNavigateTasques,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickActionCard(
                    label: 'El meu perfil',
                    icon: Icons.person_outline,
                    onTap: onNavigatePerfil,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final TreballadorProfileData profile;

  const _GreetingHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.primary,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
        AppSpacing.screenHorizontal,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benvingut,',
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onPrimary.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.nomComplet,
            style: AppTextStyles.headlineMedium.copyWith(
              color: scheme.onPrimary,
            ),
          ),
          if (profile.carrecActual != null &&
              profile.carrecActual!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              profile.carrecLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
          if (profile.empresaLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 13,
                  color: scheme.onPrimary.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  profile.empresaLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color softColor;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTextStyles.headlineMedium.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}