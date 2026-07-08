import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/screens/base/splash_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorProfileScreen extends StatefulWidget {
  final int? treballadorId;

  const TreballadorProfileScreen({
    super.key,
    this.treballadorId,
  });

  @override
  State<TreballadorProfileScreen> createState() =>
      _TreballadorProfileScreenState();
}

class _TreballadorProfileScreenState extends State<TreballadorProfileScreen> {
  late final TreballadorService _service;
  late Future<TreballadorProfileData> _futureProfile;

  bool get _isOwnProfile => widget.treballadorId == null;

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _futureProfile = _loadProfile();
  }

  Future<TreballadorProfileData> _loadProfile() {
    if (widget.treballadorId != null) {
      return _service.fetchTreballadorProfile(widget.treballadorId!);
    }

    return _service.fetchMyProfile();
  }

  Future<void> _reload() async {
    final nextFuture = _loadProfile();

    setState(() {
      _futureProfile = nextFuture;
    });

    await nextFuture;
  }

  Future<void> _logout() async {
    final confirmed = await _confirmLogout();
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Future<bool?> _confirmLogout() {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Tancar sessió'),
          content: const Text(
            'Vols sortir del teu compte de treballador?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel·la'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Tanca sessió'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: FutureBuilder<TreballadorProfileData>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant perfil...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final profile = snapshot.data;

          if (profile == null) {
            return AppErrorState(
              message: 'No s’han rebut dades del perfil.',
              onRetry: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              children: [
                _ProfileHeroCard(profile: profile),
                const SizedBox(height: AppSpacing.md),
                _ProfileWorkSummaryCard(profile: profile),
                const SizedBox(height: AppSpacing.md),
                _ProfileContactCard(profile: profile),
                const SizedBox(height: AppSpacing.md),
                _ProfileParticipationCard(profile: profile),
                if (_isOwnProfile) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ProfileSessionCard(onLogout: _logout),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const _ProfileHeroCard({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(context, profile.estatKey);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(profile: profile),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nomComplet,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                if (profile.hasNickname) ...[
                  const SizedBox(height: 5),
                  Text(
                    profile.aliasVisible,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: scheme.onPrimary.withOpacity(0.78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _HeroPill(
                      icon: Icons.badge_outlined,
                      label: profile.carrecLabel,
                    ),
                    _HeroPill(
                      icon: Icons.business_outlined,
                      label: profile.empresaLabel,
                    ),
                    _HeroPill(
                      icon: Icons.verified_user_outlined,
                      label: profile.estatLabel,
                      accent: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final TreballadorProfileData profile;

  const _ProfileAvatar({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (profile.hasFoto) {
      return CircleAvatar(
        radius: 34,
        backgroundColor: scheme.onPrimary.withOpacity(0.18),
        backgroundImage: NetworkImage(profile.fotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 34,
      backgroundColor: scheme.onPrimary.withOpacity(0.18),
      child: Text(
        _initials(profile.nomComplet),
        style: AppTextStyles.titleLarge.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _HeroPill({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.onPrimary.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color.withOpacity(0.90),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onPrimary.withOpacity(0.90),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileWorkSummaryCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const _ProfileWorkSummaryCard({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.work_outline_rounded,
            title: 'Situació laboral',
            subtitle: 'Informació resumida del teu context actual.',
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoTile(
            icon: Icons.business_outlined,
            label: 'Empresa actual',
            value: profile.empresaLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'Càrrec',
            value: profile.carrecLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoTile(
            icon: Icons.verified_user_outlined,
            label: 'Estat del contracte',
            value: profile.estatLabel,
            accent: profile.isActiu ? scheme.primary : scheme.error,
          ),
        ],
      ),
    );
  }
}

class _ProfileContactCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const _ProfileContactCard({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.contact_phone_outlined,
            title: 'Contacte',
            subtitle: 'Dades visibles associades al teu perfil.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (!profile.hasContactInfo)
            const _EmptyInline(
              icon: Icons.info_outline_rounded,
              text: 'No hi ha dades de contacte disponibles.',
            )
          else ...[
            if ((profile.telefon ?? '').trim().isNotEmpty)
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Telèfon',
                value: profile.telefon!,
              ),
            if ((profile.telefon ?? '').trim().isNotEmpty &&
                (profile.email ?? '').trim().isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            if ((profile.email ?? '').trim().isNotEmpty)
              _InfoTile(
                icon: Icons.mail_outline_rounded,
                label: 'Correu',
                value: profile.email!,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileParticipationCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const _ProfileParticipationCard({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.insights_outlined,
            title: 'Participació',
            subtitle: 'Resum general. El detall es consulta a Tasques i Obres.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  icon: Icons.assignment_outlined,
                  label: 'Tasques',
                  value: profile.tasquesCount.toString(),
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricBox(
                  icon: Icons.location_city_outlined,
                  label: 'Obres',
                  value: profile.obresCount.toString(),
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _EmptyInline(
            icon: Icons.open_in_new_rounded,
            text:
                'Per consultar informació completa, utilitza les pestanyes de Tasques i Obres.',
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileSessionCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _ProfileSessionCard({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.errorContainer.withOpacity(0.60),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: scheme.onErrorContainer,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sessió',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tanca la sessió d’aquest dispositiu quan acabis.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.30,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Tanca sessió'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(
                        color: scheme.error.withOpacity(0.45),
                      ),
                    ),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.30,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
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

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;

  const _EmptyInline({
    required this.icon,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'TR';

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

Color _statusColor(BuildContext context, String key) {
  final scheme = Theme.of(context).colorScheme;

  switch (key) {
    case 'actiu':
      return scheme.onPrimary;
    case 'baixa':
      return scheme.errorContainer;
    case 'acomiadat':
      return scheme.errorContainer;
    default:
      return scheme.onPrimary.withOpacity(0.80);
  }
}