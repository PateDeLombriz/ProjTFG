import 'package:flutter/material.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/screens/documents_obra_screen.dart';
import 'package:front_end/screens/treballador/recursos/treballador_sol_recurs.dart';
import 'package:front_end/screens/treballador/recursos/treballador_sol_recurs_list_screen.dart';
import 'package:front_end/shared/models/app_capabilities.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';
import 'package:front_end/shared/widgets/app_secondary_button.dart';
import 'package:front_end/shared/widgets/map_selector_widget.dart';


class TreballadorObraInfoScreen extends StatelessWidget {
  final Obra obra;
  final AppCapabilities? capabilities;

  const TreballadorObraInfoScreen({
    super.key,
    required this.obra,
    this.capabilities,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caps = capabilities ?? const AppCapabilities.workerDefaults();

    final obraId = _asIntOrNull(obra.id);
    final nom = _asString(obra.nom) ?? 'Obra sense nom';
    final estat = _asString(obra.estat);
    final estatKey = _normalizeEstat(estat);
    final descripcio = _asString(obra.descripcio);

    final dataInici = _formatDate(obra.dataInici);
    final dataPrevFi = _formatDate(obra.dataPrevFi);
    final dataFi = _formatDate(obra.dataFi);
    final ubicacio = obra.ubicacioInfo;
    print('Dades de ubicació: $ubicacio');
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Informació de l’obra'),
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            _ObraHeroCard(
              nom: nom,
              estatKey: estatKey,
              estatOriginal: estat,
              ubicacio: ubicacio?.adreca ?? '',
              descripcio: descripcio,
            ),
            const SizedBox(height: AppSpacing.md),

            _ObraDatesCard(
              dataInici: dataInici,
              dataPrevFi: dataPrevFi,
              dataFi: dataFi,
            ),
            const SizedBox(height: AppSpacing.md),

            _ObraLocationCard(ubicacio: ubicacio),
            const SizedBox(height: AppSpacing.md),

            _ObraActionsCard(
              obraId: obraId,
              nomObra: nom,
              canRequestResources: caps.canRequestResources,
            ),
          ],
        ),
      ),
    );
  }
}

class _ObraHeroCard extends StatelessWidget {
  final String nom;
  final String estatKey;
  final String? estatOriginal;
  final String ubicacio;
  final String? descripcio;

  const _ObraHeroCard({
    required this.nom,
    required this.estatKey,
    required this.estatOriginal,
    required this.ubicacio,
    required this.descripcio,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _estatColor(context, estatKey);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: scheme.onPrimary,
              size: 31,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            nom,
            style: AppTextStyles.headlineMedium.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _HeroPill(
                icon: Icons.flag_outlined,
                label: _estatLabel(estatKey, fallback: estatOriginal),
                accent: accent,
              ),
              _HeroPill(
                icon: Icons.location_on_outlined,
                label: ubicacio,
              ),
            ],
          ),
          if (descripcio != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              descripcio!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onPrimary.withOpacity(0.82),
                height: 1.36,
              ),
            ),
          ],
        ],
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
    final foreground = accent ?? scheme.onPrimary;

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
            color: foreground.withOpacity(0.92),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onPrimary.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObraDatesCard extends StatelessWidget {
  final String dataInici;
  final String dataPrevFi;
  final String dataFi;

  const _ObraDatesCard({
    required this.dataInici,
    required this.dataPrevFi,
    required this.dataFi,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.event_note_outlined,
            title: 'Calendari',
            subtitle: 'Dates principals de referència per al treballador.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  icon: Icons.play_arrow_rounded,
                  label: 'Inici',
                  value: dataInici,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DateBox(
                  icon: Icons.event_available_outlined,
                  label: 'Fi prevista',
                  value: dataPrevFi,
                ),
              ),
            ],
          ),
          if (dataFi != '—') ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoTile(
              icon: Icons.check_circle_outline,
              label: 'Data de finalització',
              value: dataFi,
            ),
          ],
        ],
      ),
    );
  }
}

class _ObraLocationCard extends StatelessWidget {
  final ObraUbicacioInfo? ubicacio;

  const _ObraLocationCard({
    required this.ubicacio,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.location_on_outlined,
            title: 'Ubicació',
            subtitle: 'Referència bàsica de localització de l’obra.',
          ),
          const SizedBox(height: AppSpacing.md),
          UbicacioMapPreview(
            ubicacio: ubicacio,
            height: 190,
            permetSeleccionarEnObrir: false,
          ),
        ],
      ),
    );
  }
}
class _ObraActionsCard extends StatelessWidget {
  final int? obraId;
  final String nomObra;
  final bool canRequestResources;

  const _ObraActionsCard({
    required this.obraId,
    required this.nomObra,
    required this.canRequestResources,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.touch_app_outlined,
            title: 'Accions disponibles',
            subtitle: 'Accessos relacionats amb aquesta obra.',
          ),
          const SizedBox(height: AppSpacing.md),

          AppPrimaryButton(
            label: 'Documents de l’obra',
            icon: Icons.folder_open_outlined,
            onPressed: obraId == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentsObraScreen(
                          obraId: obraId!,
                        ),
                      ),
                    ),
          ),
          if (obraId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Les meves sol·licituds',
              icon: Icons.inventory_2_outlined,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TreballadorSolRecursListScreen(),
                ),
              ),
            ),
          if (canRequestResources && obraId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Sol·licitar recurs',
              icon: Icons.inventory_2_outlined,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TreballadorSolRecursForm(
                    obraId: obraId!,
                    nomObra: nomObra,
                  ),
                ),
              ),
            ),
          ],

          if (obraId == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'No es pot obrir cap acció perquè falta l’identificador de l’obra.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ]
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

class _DateBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DateBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: scheme.primary,
            size: 21,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
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
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
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
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

/* ───────────────────────── Helpers ───────────────────────── */

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String _formatDate(dynamic value) {
  if (value == null) return '—';

  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();

  return '$day/$month/$year';
}

String _normalizeEstat(String? value) {
  if (value == null) return 'sense_estat';

  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  switch (normalized) {
    case 'planificacio':
      return 'planificacio';
    case 'en curs':
      return 'en_curs';
    case 'finalitzada':
      return 'finalitzada';
    case 'aturada':
      return 'aturada';
    default:
      return normalized.replaceAll(' ', '_');
  }
}

String _estatLabel(String normalized, {String? fallback}) {
  switch (normalized) {
    case 'res_firmat':
      return 'Res firmat';
    case 'en_execucio':
      return 'En curs';
    case 'en_curs':
      return 'En curs';
    case 'finalitzada':
      return 'Finalitzada';
    case 'pendent':
      return 'Pendent';
    case 'sense_estat':
      return 'Sense estat';
    default:
      return fallback ?? normalized;
  }
}

Color _estatColor(BuildContext context, String normalized) {
  final scheme = Theme.of(context).colorScheme;

  switch (normalized) {
    case 'planificacio':
      return scheme.onPrimary.withOpacity(0.82);
    case 'en_curs':
      return scheme.onPrimary;
    case 'finalitzada':
      return Colors.green.shade200;
    case 'pendent':
      return scheme.tertiaryContainer;
    default:
      return scheme.onPrimary.withOpacity(0.86);
  }
}
