import 'package:flutter/material.dart';
import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/utils/date_formatter.dart';
import 'package:front_end/shared/widgets/app_avatar_fallback.dart';
import 'package:front_end/shared/widgets/app_card_action_button.dart';
import 'package:front_end/utils/status_color_helper.dart';
import 'package:front_end/shared/widgets/app_info_pill.dart';
import 'package:front_end/shared/widgets/app_status_chip.dart';
import 'package:front_end/shared/widgets/app_expandable_section.dart';
import 'package:front_end/shared/widgets/app_form_header_card.dart';
import 'package:front_end/shared/widgets/app_tag.dart';

class TreballadorHeaderCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorHeaderCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = colorForTreballadorEstat(profile.estatKey);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TreballadorAvatar(
            imageUrl: profile.fotoUrl,
            fullName: profile.nomComplet,
            size: 78,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nomComplet,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (profile.hasNickname) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.aliasVisible,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppTag(
                      icon: Icons.badge_outlined,
                      label: profile.carrecLabel,
                    ),
                    AppTag(
                      icon: Icons.business_outlined,
                      label: profile.empresaLabel,
                    ),
                    AppTag(
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

class TreballadorListHeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final int? activeCount;
  final int? actiusCount;

  const TreballadorListHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    this.activeCount,
    this.actiusCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppFormHeaderCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.groups_rounded,
      iconContainerSize: 72,
      badges: [
        AppTag(
            icon: Icons.badge_outlined,
            label: count == 1 ? '1 treballador' : '$count treballadors'),
        if (activeCount != null)
          AppTag(
            icon: Icons.filter_alt_outlined,
            label: activeCount == 1 ? '1 visible' : '$activeCount visibles',
            accent: scheme.tertiary,
          ),
        if (actiusCount != null)
          AppTag(
            icon: Icons.verified_user_outlined,
            label: actiusCount == 1 ? '1 actiu' : '$actiusCount actius',
            accent: colorForTreballadorEstat('actiu'),
          ),
      ],
    );
  }
}

class TreballadorListFilterBar extends StatelessWidget {
  final List<String> estatOptions;
  final List<String> carrecOptions;
  final String? selectedEstat;
  final String? selectedCarrec;
  final String selectedSort;
  final ValueChanged<String?> onEstatChanged;
  final ValueChanged<String?> onCarrecChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback? onClearFilters;

  const TreballadorListFilterBar({
    super.key,
    required this.estatOptions,
    required this.carrecOptions,
    required this.selectedEstat,
    required this.selectedCarrec,
    required this.selectedSort,
    required this.onEstatChanged,
    required this.onCarrecChanged,
    required this.onSortChanged,
    this.onClearFilters,
  });

  int get activeFiltersCount {
    var count = 0;
    if (selectedEstat != null && selectedEstat!.trim().isNotEmpty) count++;
    if (selectedCarrec != null && selectedCarrec!.trim().isNotEmpty) count++;
    if (selectedSort != TreballadorSortValues.nomAsc) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Filtres i ordenació',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (activeFiltersCount > 0)
                AppTag(
                  icon: Icons.filter_alt_outlined,
                  label: '$activeFiltersCount actius',
                  accent: scheme.tertiary,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TreballadorDropdownField<String>(
                width: 210,
                label: 'Estat',
                value: selectedEstat,
                onChanged: onEstatChanged,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tots els estats'),
                  ),
                  ...estatOptions.map(
                    (estat) => DropdownMenuItem<String?>(
                      value: estat,
                      child: Text(estat),
                    ),
                  ),
                ],
              ),
              _TreballadorDropdownField<String>(
                width: 230,
                label: 'Càrrec',
                value: selectedCarrec,
                onChanged: onCarrecChanged,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tots els càrrecs'),
                  ),
                  ...carrecOptions.map(
                    (carrec) => DropdownMenuItem<String?>(
                      value: carrec,
                      child: Text(
                        carrec,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              _TreballadorDropdownField<String>(
                width: 220,
                label: 'Ordena per',
                value: selectedSort,
                onChanged: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    onSortChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem<String?>(
                    value: TreballadorSortValues.nomAsc,
                    child: Text('Nom A-Z'),
                  ),
                  DropdownMenuItem<String?>(
                    value: TreballadorSortValues.nomDesc,
                    child: Text('Nom Z-A'),
                  ),
                  DropdownMenuItem<String?>(
                    value: TreballadorSortValues.carrecAsc,
                    child: Text('Càrrec A-Z'),
                  ),
                  DropdownMenuItem<String?>(
                    value: TreballadorSortValues.estatAsc,
                    child: Text('Estat A-Z'),
                  ),
                ],
              ),
            ],
          ),
          if (activeFiltersCount > 0 && onClearFilters != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Neteja filtres'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TreballadorContactCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorContactCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contacte',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (!profile.hasContactInfo)
            _TreballadorEmptyInline(
              text: 'No hi ha dades de contacte disponibles.',
            )
          else ...[
            if ((profile.telefon ?? '').trim().isNotEmpty)
              _TreballadorContactRow(
                icon: Icons.phone_outlined,
                label: 'Telèfon',
                value: profile.telefon!,
              ),
            if ((profile.telefon ?? '').trim().isNotEmpty &&
                (profile.email ?? '').trim().isNotEmpty)
              const SizedBox(height: 12),
            if ((profile.email ?? '').trim().isNotEmpty)
              _TreballadorContactRow(
                icon: Icons.mail_outline,
                label: 'Correu',
                value: profile.email!,
              ),
          ],
        ],
      ),
    );
  }
}

class TreballadorSummaryCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorSummaryCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resum',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Estat',
                value: profile.estatLabel,
              ),
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Tasques',
                value: profile.tasquesCount.toString(),
              ),
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Obres',
                value: profile.obresCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TreballadorOverviewAdminCard extends StatelessWidget {
  final TreballadorProfileData profile;
  final Map<String, dynamic> detail;

  const TreballadorOverviewAdminCard({
    super.key,
    required this.profile,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = colorForTreballadorEstat(profile.estatKey);
    final comentaris = _textOrFallback(
      detail['comentaris'],
      fallback: 'Sense comentaris.',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resum i informació administrativa',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dades principals del treballador',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Estat',
                value: profile.estatLabel,
              ),
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Tasques',
                value: profile.tasquesCount.toString(),
              ),
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Obres',
                value: profile.obresCount.toString(),
              ),
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'DNI / NIE',
                value: _textOrFallback(detail['dni_nie_passaport']),
              ),
              AppInfoPill(
                constraints: const BoxConstraints(minWidth: 104),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                borderRadius: 16,
                label: 'Naixement',
                value: formatDateDynamic(detail['data_naixement']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comentaris',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comentaris,
                  style: TextStyle(
                    color: scheme.onSurface,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class TreballadorListItemCard extends StatelessWidget {
  final TreballadorListItem treballador;
  final VoidCallback? onTap;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool nameOnly;

  final String viewTooltip;
  final String editTooltip;
  final String deleteTooltip;

  final IconData viewIcon;
  final IconData editIcon;
  final IconData deleteIcon;

  const TreballadorListItemCard({
    super.key,
    required this.treballador,
    this.onTap,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.nameOnly = false,
    this.viewTooltip = 'Veure detall',
    this.editTooltip = 'Editar treballador',
    this.deleteTooltip = 'Eliminar treballador',
    this.viewIcon = Icons.visibility_outlined,
    this.editIcon = Icons.edit_outlined,
    this.deleteIcon = Icons.delete_outline,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = colorForTreballadorEstat(treballador.estatKey);
    final statusLabel = treballador.estatLabel;

    final cardRadius = BorderRadius.circular(nameOnly ? 16 : 22);
    final cardPadding = nameOnly
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(16);
    final avatarSize = nameOnly ? 38.0 : 58.0;
    final hasActions =
        !nameOnly && (onView != null || onEdit != null || onDelete != null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          padding: cardPadding,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: cardRadius,
            border: Border.all(
              color: accent.withOpacity(nameOnly ? 0.24 : 0.40),
              width: nameOnly ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                nameOnly ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              _TreballadorAvatar(
                imageUrl: treballador.fotoUrl,
                fullName: treballador.nomComplet,
                size: avatarSize,
              ),
              SizedBox(width: nameOnly ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treballador.nomComplet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: nameOnly ? 14.5 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!nameOnly) ...[
                      const SizedBox(height: 10),
                      Text(
                        treballador.carrecLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (treballador.hasNickname) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@${treballador.nickname!.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SizedBox(width: nameOnly ? 8 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!nameOnly)
                    AppStatusChip(
                      label: statusLabel,
                      color: accent,
                    ),
                  if (hasActions) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onView != null)
                          AppCardActionButton(
                            borderRadius: 10,
                            size: 34,
                            padding: const EdgeInsets.only(left: 4),
                            tooltip: 'Veure detall',
                            icon: Icons.visibility_outlined,
                            onPressed: onView!,
                          ),
                        if (onEdit != null)
                          AppCardActionButton(
                            borderRadius: 10,
                            size: 34,
                            padding: const EdgeInsets.only(left: 4),
                            tooltip: 'Editar treballador',
                            icon: Icons.edit_outlined,
                            onPressed: onEdit!,
                          ),
                        if (onDelete != null)
                          AppCardActionButton(
                            borderRadius: 10,
                            size: 34,
                            padding: const EdgeInsets.only(left: 4),
                            tooltip: 'Eliminar treballador',
                            icon: Icons.delete_outline,
                            onPressed: onDelete!,
                            isDanger: true,
                          ),
                      ],
                    ),
                  ] else if (onTap != null)
                    Padding(
                      padding: EdgeInsets.only(top: nameOnly ? 0 : 12),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TreballadorLoadingCard extends StatelessWidget {
  const TreballadorLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class TreballadorErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TreballadorErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.error.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: scheme.error),
              const SizedBox(width: 10),
              Text(
                'No s’ha pogut carregar el perfil',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Torna-ho a provar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TreballadorListErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TreballadorListErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outline.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: scheme.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'No s’ha pogut carregar el llistat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Torna-ho a provar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class TreballadorSortValues {
  static const String nomAsc = 'nom_asc';
  static const String nomDesc = 'nom_desc';
  static const String carrecAsc = 'carrec_asc';
  static const String estatAsc = 'estat_asc';
}

class _TreballadorDropdownField<T> extends StatelessWidget {
  final String label;
  final double width;
  final T? value;
  final ValueChanged<T?> onChanged;
  final List<DropdownMenuItem<T?>> items;

  const _TreballadorDropdownField({
    required this.label,
    required this.width,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withOpacity(0.22),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: scheme.outline.withOpacity(0.10),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: scheme.outline.withOpacity(0.10),
            ),
          ),
        ),
      ),
    );
  }
}

class _TreballadorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullName;
  final double size;

  const _TreballadorAvatar({
    required this.imageUrl,
    required this.fullName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initialsFromName(fullName);
    final url = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => AppAvatarFallback(
                initials: initials,
              ),
            )
          : AppAvatarFallback(
              initials: initials,
            ),
    );
  }
}

class _TreballadorMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TreballadorMetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TreballadorContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TreballadorEmptyInline extends StatelessWidget {
  final String text;

  const _TreballadorEmptyInline({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: Text(
        text,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

String _textOrFallback(dynamic value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _initialsFromName(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    final first = parts.first;
    return first.isEmpty ? '' : first.substring(0, 1).toUpperCase();
  }

  final first = parts.first.isEmpty ? '' : parts.first.substring(0, 1);
  final second = parts[1].isEmpty ? '' : parts[1].substring(0, 1);
  return '$first$second'.toUpperCase();
}

class TreballadorFormHeaderCard extends StatelessWidget {
  final bool editing;
  final String fullName;
  final String documentLabel;
  final String carrecLabel;
  final String estatLabel;
  final String contactLabel;

  const TreballadorFormHeaderCard({
    super.key,
    required this.editing,
    required this.fullName,
    required this.documentLabel,
    required this.carrecLabel,
    required this.estatLabel,
    required this.contactLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = editing ? scheme.tertiary : scheme.primary;
    final displayName = fullName.trim().isEmpty
        ? (editing ? 'Editar treballador' : 'Nou treballador')
        : fullName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.18),
            scheme.primaryContainer.withOpacity(0.28),
            scheme.surface,
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.24), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.20)),
                ),
                child: Center(
                  child: Text(
                    _initialsFromName(displayName).isEmpty
                        ? 'T'
                        : _initialsFromName(displayName),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing ? 'Edició de treballador' : 'Alta de treballador',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      contactLabel.trim().isEmpty
                          ? 'Sense contacte indicat'
                          : contactLabel.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TreballadorFormBadge(
                icon: Icons.credit_card_rounded,
                label: documentLabel.trim().isEmpty
                    ? 'Document pendent'
                    : documentLabel.trim(),
                color: scheme.primary,
              ),
              _TreballadorFormBadge(
                icon: Icons.work_outline_rounded,
                label: carrecLabel.trim().isEmpty
                    ? 'Sense càrrec'
                    : carrecLabel.trim(),
                color: scheme.tertiary,
              ),
              _TreballadorFormBadge(
                icon: Icons.verified_user_outlined,
                label: estatLabel.trim().isEmpty ? 'Actiu' : estatLabel.trim(),
                color: colorForTreballadorEstat(estatLabel.toLowerCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TreballadorFormDateTile extends StatelessWidget {
  final String title;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isRequired;
  final String emptyText;

  const TreballadorFormDateTile({
    super.key,
    required this.title,
    required this.date,
    required this.onTap,
    this.isRequired = false,
    this.emptyText = 'Selecciona una data',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = isRequired ? scheme.primary : scheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date == null ? emptyText : formatDate(date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_calendar_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class TreballadorFormInfoNotice extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? accent;

  const TreballadorFormInfoNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveAccent = accent ?? scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: effectiveAccent.withOpacity(0.055),
        border: Border.all(color: effectiveAccent.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: effectiveAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TreballadorFormEmptyState extends StatelessWidget {
  final String text;
  final IconData icon;

  const TreballadorFormEmptyState({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TreballadorFormPermissionCard extends StatelessWidget {
  final String title;
  final String? description;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final Widget? child;
  final Color? accent;

  const TreballadorFormPermissionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onSelectedChanged,
    this.description,
    this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveAccent = accent ?? scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? effectiveAccent.withOpacity(0.07)
            : scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? effectiveAccent.withOpacity(0.22)
              : scheme.outline.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: effectiveAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? 'Permís sense nom' : title.trim(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (description != null &&
                        description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: selected,
                onChanged: onSelectedChanged,
              ),
            ],
          ),
          if (selected && child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}

class TreballadorFormPermissionFlagChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const TreballadorFormPermissionFlagChip({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(value ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(value ? 0.22 : 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreballadorFormBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TreballadorFormBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
