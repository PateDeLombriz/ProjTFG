import 'package:flutter/material.dart';

import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
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

  String _periodeFilter = '7d';
  String _estatFilter = 'tots';

  static const _periodeOptions = [
    ('avui', 'Avui'),
    ('7d', '7 dies'),
    ('30d', '30 dies'),
    ('tot', 'Tot'),
  ];

  static const _estatOptions = [
    ('tots', 'Tots'),
    ('oberts', 'Oberts'),
    ('tancats', 'Tancats'),
  ];

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _future = _service.fetchMyRegistreHorari();
  }

  Future<void> _reload({bool clearFeedback = true}) async {
    final nextFuture = _service.fetchMyRegistreHorari();

    setState(() {
      _future = nextFuture;
      if (clearFeedback) {
        _actionError = null;
        _actionSuccess = null;
      }
    });

    await nextFuture;
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

      await _reload(clearFeedback: false);
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
      if (!mounted) return;

      setState(() {
        _actionLoading = false;
      });
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

      await _reload(clearFeedback: false);
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
      if (!mounted) return;

      setState(() {
        _actionLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> registres) {
    final now = DateTime.now();

    return registres.where((registre) {
      final entrada = _entryDateTime(registre);
      final sortida = _exitDateTime(registre);
      final isOpen = sortida == null;

      final matchesEstat = switch (_estatFilter) {
        'oberts' => isOpen,
        'tancats' => !isOpen,
        _ => true,
      };

      final matchesPeriod = switch (_periodeFilter) {
        'avui' => entrada != null && _isSameDay(entrada, now),
        '7d' => entrada != null &&
            entrada.isAfter(now.subtract(const Duration(days: 7))),
        '30d' => entrada != null &&
            entrada.isAfter(now.subtract(const Duration(days: 30))),
        _ => true,
      };

      return matchesEstat && matchesPeriod;
    }).toList()
      ..sort((a, b) {
        final aDate = _entryDateTime(a);
        final bDate = _entryDateTime(b);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Control horari'),
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _reload(),
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
              onRetry: () => _reload(),
            );
          }

          final registres = snapshot.data ?? [];
          final summary = _HorariSummary.from(registres);
          final filtered = _applyFilters(registres);

          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              children: [
                _RegistreHeaderCard(summary: summary),
                const SizedBox(height: AppSpacing.md),
                _FitxarStatusCard(
                  summary: summary,
                  isLoading: _actionLoading,
                  error: _actionError,
                  success: _actionSuccess,
                  onFitxarEntrada: _fitxarEntrada,
                  onFitxarSortida: _fitxarSortida,
                ),
                const SizedBox(height: AppSpacing.md),
                _RegistreFilterPanel(
                  selectedPeriode: _periodeFilter,
                  selectedEstat: _estatFilter,
                  periodeOptions: _periodeOptions,
                  estatOptions: _estatOptions,
                  onPeriodeChanged: (value) {
                    setState(() {
                      _periodeFilter = value;
                    });
                  },
                  onEstatChanged: (value) {
                    setState(() {
                      _estatFilter = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _HistorialTitle(
                  total: filtered.length,
                  originalTotal: registres.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (filtered.isEmpty)
                  _HistorialBuit(hasAnyRegistres: registres.isNotEmpty)
                else
                  ...List.generate(filtered.length, (index) {
                    final registre = filtered[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filtered.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _RegistreItem(registre: registre),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RegistreHeaderCard extends StatelessWidget {
  final _HorariSummary summary;

  const _RegistreHeaderCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = summary.hasOpenEntry ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: scheme.onPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Registre horari',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.hasOpenEntry
                ? 'Tens una jornada oberta. Quan acabis, registra la sortida.'
                : 'Consulta el teu historial i registra l’entrada quan comencis la jornada.',
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Estat',
                  value: summary.hasOpenEntry ? 'Oberta' : 'Tancada',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'Registres',
                  value: summary.total.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'Darrer',
                  value: summary.lastEntryShortLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  summary.hasOpenEntry
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: scheme.onPrimary.withOpacity(0.88),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  summary.hasOpenEntry
                      ? 'Seguiment actiu'
                      : 'Sense jornada oberta',
                  style: TextStyle(
                    color: scheme.onPrimary.withOpacity(0.88),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({
    required this.label,
    required this.value,
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
        color: scheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onPrimary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.78),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FitxarStatusCard extends StatelessWidget {
  final _HorariSummary summary;
  final bool isLoading;
  final String? error;
  final String? success;
  final VoidCallback onFitxarEntrada;
  final VoidCallback onFitxarSortida;

  const _FitxarStatusCard({
    required this.summary,
    required this.isLoading,
    required this.error,
    required this.success,
    required this.onFitxarEntrada,
    required this.onFitxarSortida,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasOpen = summary.hasOpenEntry;
    final accent = hasOpen ? scheme.primary : scheme.tertiary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  hasOpen
                      ? Icons.timer_outlined
                      : Icons.timer_off_outlined,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasOpen ? 'Jornada en curs' : 'Fora de jornada',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasOpen
                          ? 'Entrada: ${summary.openEntryLabel}'
                          : 'Registra l’entrada quan comencis la jornada.',
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
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FeedbackBanner(text: error!, isError: true),
          ],
          if (success != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FeedbackBanner(text: success!, isError: false),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: hasOpen ? 'Fitxar sortida' : 'Fitxar entrada',
            icon: hasOpen ? Icons.logout_rounded : Icons.login_rounded,
            isLoading: isLoading,
            onPressed: isLoading
                ? null
                : hasOpen
                    ? onFitxarSortida
                    : onFitxarEntrada,
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool isError;

  const _FeedbackBanner({
    required this.text,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer.withOpacity(0.70)
        : scheme.primaryContainer.withOpacity(0.70);
    final foreground =
        isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistreFilterPanel extends StatelessWidget {
  final String selectedPeriode;
  final String selectedEstat;
  final List<(String, String)> periodeOptions;
  final List<(String, String)> estatOptions;
  final ValueChanged<String> onPeriodeChanged;
  final ValueChanged<String> onEstatChanged;

  const _RegistreFilterPanel({
    required this.selectedPeriode,
    required this.selectedEstat,
    required this.periodeOptions,
    required this.estatOptions,
    required this.onPeriodeChanged,
    required this.onEstatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterGroup(
            title: 'Període',
            selected: selectedPeriode,
            options: periodeOptions,
            onChanged: onPeriodeChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterGroup(
            title: 'Estat',
            selected: selectedEstat,
            options: estatOptions,
            onChanged: onEstatChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final String selected;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _FilterGroup({
    required this.title,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final key = option.$1;
              final label = option.$2;
              final isSelected = selected == key;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(key),
                  selectedColor: scheme.primaryContainer,
                  backgroundColor: scheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HistorialTitle extends StatelessWidget {
  final int total;
  final int originalTotal;

  const _HistorialTitle({
    required this.total,
    required this.originalTotal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Historial de jornades',
            style: AppTextStyles.labelLarge.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        Text(
          total == originalTotal ? '$total registres' : '$total de $originalTotal',
          style: AppTextStyles.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RegistreItem extends StatelessWidget {
  final Map<String, dynamic> registre;

  const _RegistreItem({
    required this.registre,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final entrada = _entryDateTime(registre);
    final sortida = _exitDateTime(registre);
    final isOpen = sortida == null;
    final accent = isOpen ? scheme.primary : scheme.tertiary;
    final duration = _durationLabel(entrada, sortida);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.75),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isOpen ? Icons.timelapse_rounded : Icons.check_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel(entrada),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _RegistreTag(
                          icon: Icons.login_rounded,
                          label: 'Entrada ${_timeLabel(entrada)}',
                          color: scheme.primary,
                        ),
                        _RegistreTag(
                          icon: Icons.logout_rounded,
                          label: isOpen
                              ? 'Sortida pendent'
                              : 'Sortida ${_timeLabel(sortida)}',
                          color: isOpen ? scheme.error : scheme.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isOpen
                          ? 'Jornada encara oberta'
                          : 'Durada registrada: $duration',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusPill(
                label: isOpen ? 'Actiu' : 'Tancat',
                active: isOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistreTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RegistreTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = active
        ? scheme.primaryContainer.withOpacity(0.72)
        : scheme.surfaceContainerHighest.withOpacity(0.80);
    final foreground =
        active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HistorialBuit extends StatelessWidget {
  final bool hasAnyRegistres;

  const _HistorialBuit({
    required this.hasAnyRegistres,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasAnyRegistres
                ? Icons.filter_list_off_rounded
                : Icons.history_outlined,
            size: 38,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasAnyRegistres ? 'Sense resultats' : 'Sense historial',
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasAnyRegistres
                ? 'No hi ha registres que coincideixin amb els filtres.'
                : 'Quan registris entrades i sortides, apareixeran aquí.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorariSummary {
  final int total;
  final Map<String, dynamic>? openEntry;
  final Map<String, dynamic>? lastEntry;

  const _HorariSummary({
    required this.total,
    required this.openEntry,
    required this.lastEntry,
  });

  bool get hasOpenEntry => openEntry != null;

  String get openEntryLabel {
    final entrada = openEntry == null ? null : _entryDateTime(openEntry!);
    return _formatDateTimeShort(entrada);
  }

  String get lastEntryShortLabel {
    final entrada = lastEntry == null ? null : _entryDateTime(lastEntry!);
    if (entrada == null) return '—';

    final now = DateTime.now();
    if (_isSameDay(entrada, now)) return 'Avui';

    return '${entrada.day.toString().padLeft(2, '0')}/${entrada.month.toString().padLeft(2, '0')}';
  }

  factory _HorariSummary.from(List<Map<String, dynamic>> registres) {
    Map<String, dynamic>? open;
    Map<String, dynamic>? last;

    for (final registre in registres) {
      final entrada = _entryDateTime(registre);
      final sortida = _exitDateTime(registre);

      if (sortida == null) {
        if (open == null) {
          open = registre;
        } else {
          final currentOpenDate = _entryDateTime(open);
          if (entrada != null &&
              (currentOpenDate == null || entrada.isAfter(currentOpenDate))) {
            open = registre;
          }
        }
      }

      if (last == null) {
        last = registre;
      } else {
        final lastDate = _entryDateTime(last);
        if (entrada != null &&
            (lastDate == null || entrada.isAfter(lastDate))) {
          last = registre;
        }
      }
    }

    return _HorariSummary(
      total: registres.length,
      openEntry: open,
      lastEntry: last,
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

DateTime? _entryDateTime(Map<String, dynamic> registre) {
  return _firstDateTime(registre, const [
        'data_entrada',
        'entrada',
        'data_inici',
        'created_at',
      ]) ??
      _combineDateAndTime(
        _firstStringValue(registre, const ['data', 'dia']),
        _firstStringValue(registre, const ['hora_entrada', 'hora_inici']),
      );
}

DateTime? _exitDateTime(Map<String, dynamic> registre) {
  final direct = _firstDateTime(registre, const [
    'data_sortida',
    'sortida',
    'data_fi',
  ]);

  if (direct != null) return direct;

  return _combineDateAndTime(
    _firstStringValue(registre, const ['data', 'dia']),
    _firstStringValue(registre, const ['hora_sortida', 'hora_fi']),
  );
}

DateTime? _firstDateTime(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _asDateTime(value);
    if (parsed != null) return parsed;
  }

  return null;
}

String? _firstStringValue(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }

  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

DateTime? _combineDateAndTime(String? rawDate, String? rawTime) {
  if (rawDate == null) return null;

  final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
  final time = rawTime == null
      ? '00:00:00'
      : rawTime.length >= 8
          ? rawTime.substring(0, 8)
          : rawTime;

  return DateTime.tryParse('$date $time') ?? DateTime.tryParse(date);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDateTimeShort(DateTime? value) {
  if (value == null) return '—';

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month · $hour:$minute';
}

String _dateLabel(DateTime? value) {
  if (value == null) return 'Data no indicada';

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}

String _timeLabel(DateTime? value) {
  if (value == null) return '—';

  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _durationLabel(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';

  final diff = end.difference(start);
  if (diff.isNegative) return '—';

  final hours = diff.inHours;
  final minutes = diff.inMinutes.remainder(60);

  if (hours == 0) {
    return '${minutes}min';
  }

  return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
}