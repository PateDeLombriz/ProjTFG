import 'package:flutter/material.dart';

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/models/app_capabilities.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorHomeScreen extends StatefulWidget {
  final AppCapabilities? capabilities;

  const TreballadorHomeScreen({
    super.key,
    this.capabilities,
  });

  @override
  State<TreballadorHomeScreen> createState() => _TreballadorHomeScreenState();
}

class _TreballadorHomeScreenState extends State<TreballadorHomeScreen> {
  late final TreballadorService _service;
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final results = await Future.wait<dynamic>([
      _service.fetchMyProfile(),
      _service.fetchMyTasques(),
      _service.fetchMyObresParticipades(),
      _service.fetchMyRegistreHorari(),
    ]);

    return _HomeData(
      profile: results[0] as TreballadorProfileData,
      tasques: _asMapList(results[1]),
      obres: _asMapList(results[2]),
      registreHorari: _asMapList(results[3]),
    );
  }

  Future<void> _reload() async {
    final nextFuture = _load();

    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant inici...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return AppErrorState(
              message: 'No s’han rebut dades per construir la pantalla d’inici.',
              onRetry: _reload,
            );
          }

          return _HomeContent(
            data: data,
            capabilities: widget.capabilities,
            onReload: _reload,
          );
        },
      ),
    );
  }
}

class _HomeData {
  final TreballadorProfileData profile;
  final List<Map<String, dynamic>> tasques;
  final List<Map<String, dynamic>> obres;
  final List<Map<String, dynamic>> registreHorari;

  const _HomeData({
    required this.profile,
    required this.tasques,
    required this.obres,
    required this.registreHorari,
  });

  int get totalTasques {
    if (tasques.isNotEmpty) return tasques.length;
    return profile.tasquesCount;
  }

  int get totalObres {
    if (obres.isNotEmpty) return obres.length;
    return profile.obresCount;
  }

  int get tasquesPendents => countTasquesByEstat('pendent');

  int get tasquesEnCurs => countTasquesByEstat('en_curs');

  int get tasquesPendentsRevisio =>
      countTasquesByEstat('finalitzada_pendent_revisio');

  int get tasquesAltaPrioritat {
    return tasques.where((tasca) {
      final prioritat = _asInt(tasca['prioritat']);
      return prioritat >= 7;
    }).length;
  }

  bool get hasTaskStatus {
    return tasques.any((tasca) {
      final estat = _asString(tasca['estat']);
      return estat != null && estat.isNotEmpty;
    });
  }

  int countTasquesByEstat(String estat) {
    final expected = estat.trim().toLowerCase();

    return tasques.where((tasca) {
      final current = _asString(tasca['estat'])?.toLowerCase();
      return current == expected;
    }).length;
  }

  List<Map<String, dynamic>> get properesTasques {
    final items = List<Map<String, dynamic>>.from(tasques);

    items.sort((a, b) {
      final aDate = _firstDateTime([
        a['data_fi'],
        a['data_prev_fi'],
        a['data_inici'],
      ]);
      final bDate = _firstDateTime([
        b['data_fi'],
        b['data_prev_fi'],
        b['data_inici'],
      ]);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return items.take(3).toList();
  }

  List<Map<String, dynamic>> get obresResum {
    return obres.take(3).toList();
  }

  Map<String, dynamic>? get darrerRegistre {
    if (registreHorari.isEmpty) return null;

    final items = List<Map<String, dynamic>>.from(registreHorari);

    items.sort((a, b) {
      final aDate = _registreDateTime(a);
      final bDate = _registreDateTime(b);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return -1;
      if (bDate == null) return 1;

      return aDate.compareTo(bDate);
    });

    return items.last;
  }

  bool get jornadaOberta {
    final registre = darrerRegistre;
    if (registre == null) return false;

    final sortida = _firstStringValue(registre, const [
      'hora_sortida',
      'hora_fi',
      'sortida',
      'data_sortida',
      'data_fi',
    ]);

    return sortida == null || sortida.isEmpty;
  }

  String get estatJornadaLabel {
    if (darrerRegistre == null) return 'Sense registre recent';
    return jornadaOberta ? 'Jornada oberta' : 'Jornada tancada';
  }

  String get darrerRegistreLabel {
    final registre = darrerRegistre;
    if (registre == null) {
      return 'Encara no hi ha registres horaris disponibles.';
    }

    final data = _firstStringValue(registre, const [
      'data',
      'data_inici',
      'dia',
      'created_at',
    ]);

    final entrada = _firstStringValue(registre, const [
      'hora_entrada',
      'hora_inici',
      'entrada',
    ]);

    final sortida = _firstStringValue(registre, const [
      'hora_sortida',
      'hora_fi',
      'sortida',
    ]);

    final parts = <String>[
      if (data != null) _formatDateText(data),
      if (entrada != null) 'Entrada: ${_formatTimeText(entrada)}',
      if (sortida != null) 'Sortida: ${_formatTimeText(sortida)}',
    ];

    return parts.isEmpty
        ? 'Darrer registre disponible.'
        : parts.join(' · ');
  }
}

class _HomeContent extends StatelessWidget {
  final _HomeData data;
  final AppCapabilities? capabilities;
  final Future<void> Function() onReload;

  const _HomeContent({
    required this.data,
    required this.onReload,
    this.capabilities,
  });

  @override
  Widget build(BuildContext context) {
    final caps = capabilities ?? const AppCapabilities.workerDefaults();

    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          _TreballadorHomeHeader(profile: data.profile),
          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _HomeMetricGrid(data: data),
          ),

          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _TaskSummaryCard(data: data),
          ),

          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _ObresSummaryCard(data: data),
          ),

          const SizedBox(height: AppSpacing.md),

          if (caps.canRegisterHorari) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: _HorariSummaryCard(data: data),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _NotificationsSummaryCard(data:data),
          ),
        ],
      ),
    );
  }
}

class _TreballadorHomeHeader extends StatelessWidget {
  final TreballadorProfileData profile;

  const _TreballadorHomeHeader({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
        AppSpacing.screenHorizontal,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
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
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _HeaderPill(
                      icon: Icons.badge_outlined,
                      label: profile.carrecLabel,
                    ),
                    _HeaderPill(
                      icon: Icons.business_outlined,
                      label: profile.empresaLabel,
                    ),
                    _HeaderPill(
                      icon: Icons.verified_user_outlined,
                      label: profile.estatLabel,
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
    final initials = _initials(profile.nomComplet);

    if (profile.hasFoto) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: scheme.onPrimary.withOpacity(0.18),
        backgroundImage: NetworkImage(profile.fotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: scheme.onPrimary.withOpacity(0.18),
      child: Text(
        initials,
        style: AppTextStyles.titleMedium.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
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
            size: 14,
            color: scheme.onPrimary.withOpacity(0.80),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onPrimary.withOpacity(0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMetricGrid extends StatelessWidget {
  final _HomeData data;

  const _HomeMetricGrid({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Tasques',
            value: data.totalTasques.toString(),
            icon: Icons.assignment_outlined,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'Obres',
            value: data.totalObres.toString(),
            icon: Icons.location_city_outlined,
            color: scheme.tertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'Contracte',
            value: data.profile.estatLabel,
            icon: Icons.verified_user_outlined,
            color: data.profile.isActiu ? scheme.primary : scheme.error,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  final _HomeData data;

  const _TaskSummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.assignment_outlined,
      title: 'Tasques assignades',
      subtitle:
          'Resum de feina assignada. La gestió detallada es fa des de la pantalla de tasques.',
      child: Column(
        children: [
          _InlineStats(
            items: [
              _InlineStatItem(
                label: 'Total',
                value: data.totalTasques.toString(),
                color: scheme.primary,
              ),
              _InlineStatItem(
                label: 'Pendents',
                value: data.hasTaskStatus ? data.tasquesPendents.toString() : '—',
                color: scheme.error,
              ),
              _InlineStatItem(
                label: 'En curs',
                value: data.hasTaskStatus ? data.tasquesEnCurs.toString() : '—',
                color: scheme.tertiary,
              ),
              _InlineStatItem(
                label: 'Prioritat alta',
                value: data.tasquesAltaPrioritat.toString(),
                color: scheme.secondary,
              ),
            ],
          ),
          if (!data.hasTaskStatus && data.totalTasques > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _SoftNotice(
              icon: Icons.info_outline,
              text:
                  'El resum d’estats apareixerà quan l’endpoint retorni el camp estat per cada tasca.',
            ),
          ],
          if (data.properesTasques.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _MiniList(
              items: data.properesTasques.map((tasca) {
                final title = _asString(tasca['descripcio']) ??
                    _asString(tasca['titol']) ??
                    'Tasca sense descripció';

                final date = _firstStringValue(tasca, const [
                  'data_fi',
                  'data_prev_fi',
                  'data_inici',
                ]);

                final prioritat = _asInt(tasca['prioritat']);

                return _MiniListItemData(
                  icon: Icons.task_alt_outlined,
                  title: title,
                  subtitle: [
                    if (date != null) _formatDateText(date),
                    if (prioritat > 0) 'Prioritat $prioritat',
                  ].join(' · '),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ObresSummaryCard extends StatelessWidget {
  final _HomeData data;

  const _ObresSummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.location_city_outlined,
      title: 'Obres participades',
      subtitle:
          'Informació resumida de les obres on tens participació o responsabilitat.',
      child: Column(
        children: [
          _InfoLine(
            label: 'Obres detectades',
            value: data.totalObres.toString(),
          ),
          if (data.obresResum.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _MiniList(
              items: data.obresResum.map((obra) {
                final title = _asString(obra['nom']) ??
                    _asString(obra['nom_obra']) ??
                    'Obra sense nom';

                final estat = _asString(obra['estat']);
                final descripcio = _asString(obra['descripcio']);

                return _MiniListItemData(
                  icon: Icons.apartment_outlined,
                  title: title,
                  subtitle: estat ?? descripcio ?? 'Sense informació addicional',
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            const _SoftNotice(
              icon: Icons.info_outline,
              text:
                  'Quan tenguis obres associades, apareixerà un resum aquí.',
            ),
          ],
        ],
      ),
    );
  }
}

class _HorariSummaryCard extends StatelessWidget {
  final _HomeData data;

  const _HorariSummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.access_time_rounded,
      title: 'Registre horari',
      subtitle:
          'Seguiment informatiu de la jornada. L’entrada i sortida es gestionen des de la pantalla corresponent.',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: data.jornadaOberta ? scheme.primary : scheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  data.estatJornadaLabel,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoLine(
            label: 'Darrer registre',
            value: data.darrerRegistreLabel,
          ),
        ],
      ),
    );
  }
}


class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 22,
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InlineStats extends StatelessWidget {
  final List<_InlineStatItem> items;

  const _InlineStats({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i != items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _InlineStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InlineStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
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
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniList extends StatelessWidget {
  final List<_MiniListItemData> items;

  const _MiniList({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _MiniListItem(item: items[i]),
          if (i != items.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MiniListItemData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MiniListItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _MiniListItem extends StatelessWidget {
  final _MiniListItemData item;

  const _MiniListItem({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 19,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
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
class _NotificationsSummaryCard extends StatelessWidget {
  final _HomeData data;

  const _NotificationsSummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.notifications_none_rounded,
      title: 'Notificacions',
      subtitle:
          'Resum d’avisos relacionats amb la teva activitat recent.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _NotificationMetric(
                  label: 'Noves',
                  value: '0',
                  icon: Icons.mark_email_unread_outlined,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NotificationMetric(
                  label: 'Pendents',
                  value: '0',
                  icon: Icons.pending_actions_outlined,
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _NotificationPreviewItem(
            icon: Icons.assignment_outlined,
            title: 'Tasques',
            message: data.totalTasques == 0
                ? 'No tens tasques assignades ara mateix.'
                : 'Tens ${data.totalTasques} tasques assignades.',
            status: data.tasquesPendentsRevisio > 0
                ? '${data.tasquesPendentsRevisio} pendents de revisió'
                : 'Sense avisos crítics',
          ),
          const SizedBox(height: AppSpacing.sm),
          _NotificationPreviewItem(
            icon: Icons.location_city_outlined,
            title: 'Obres',
            message: data.totalObres == 0
                ? 'Encara no hi ha obres associades.'
                : 'Participes en ${data.totalObres} obres.',
            status: 'Actualitzat',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _NotificationPreviewItem(
            icon: Icons.report_problem_outlined,
            title: 'Incidències',
            message: 'Les notificacions d’incidències apareixeran aquí.',
            status: 'Properament',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _NotificationPreviewItem(
            icon: Icons.inventory_2_outlined,
            title: 'Recursos',
            message: 'Els avisos sobre recursos i sol·licituds es mostraran aquí.',
            status: 'Properament',
          ),
        ],
      ),
    );
  }
}

class _NotificationMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NotificationMetric({
    required this.label,
    required this.value,
    required this.icon,
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
          color: color.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
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
                  value,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _NotificationPreviewItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String status;

  const _NotificationPreviewItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPending = status.toLowerCase().contains('properament');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _NotificationStatusPill(
                      label: status,
                      muted: isPending,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.30,
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

class _NotificationStatusPill extends StatelessWidget {
  final String label;
  final bool muted;

  const _NotificationStatusPill({
    required this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final background = muted
        ? scheme.surfaceContainerHighest.withOpacity(0.65)
        : scheme.primaryContainer.withOpacity(0.75);

    final foreground = muted
        ? scheme.onSurfaceVariant
        : scheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SoftNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SoftNotice({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSecondaryContainer,
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

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];

  return value.map((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    return <String, dynamic>{};
  }).toList();
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String? _firstStringValue(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _asString(map[key]);
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

DateTime? _firstDateTime(List<dynamic> values) {
  for (final value in values) {
    final parsed = _asDateTime(value);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _registreDateTime(Map<String, dynamic> registre) {
  final rawDate = _firstStringValue(registre, const [
    'data',
    'data_inici',
    'dia',
    'created_at',
  ]);

  final rawTime = _firstStringValue(registre, const [
    'hora_entrada',
    'hora_inici',
    'entrada',
  ]);

  if (rawDate == null) return null;

  final dateOnly = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
  final timeOnly = rawTime == null
      ? '00:00:00'
      : rawTime.length >= 8
          ? rawTime.substring(0, 8)
          : rawTime;

  return DateTime.tryParse('$dateOnly $timeOnly') ??
      DateTime.tryParse(dateOnly);
}

String _formatDateText(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();

  return '$day/$month/$year';
}

String _formatTimeText(String value) {
  final clean = value.trim();

  if (clean.length >= 5) {
    return clean.substring(0, 5);
  }

  return clean;
}

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