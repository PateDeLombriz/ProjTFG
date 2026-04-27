import 'package:flutter/material.dart';
import 'package:front_end/models/treballador_models.dart';

class TreballadorHeaderCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorHeaderCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusAccentColor(profile.estatKey);

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
                    _TreballadorTag(
                      icon: Icons.badge_outlined,
                      label: profile.carrecLabel,
                    ),
                    _TreballadorTag(
                      icon: Icons.business_outlined,
                      label: profile.empresaLabel,
                    ),
                    _TreballadorTag(
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 34,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TreballadorTag(
                      icon: Icons.badge_outlined,
                      label: count == 1 ? '1 treballador' : '$count treballadors',
                    ),
                    if (activeCount != null)
                      _TreballadorTag(
                        icon: Icons.filter_alt_outlined,
                        label: activeCount == 1
                            ? '1 visible'
                            : '$activeCount visibles',
                        accent: scheme.tertiary,
                      ),
                    if (actiusCount != null)
                      _TreballadorTag(
                        icon: Icons.verified_user_outlined,
                        label: actiusCount == 1
                            ? '1 actiu'
                            : '$actiusCount actius',
                        accent: _statusAccentColor('actiu'),
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

class TreballadorSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const TreballadorSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = controller.text.trim().isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cerca per nom, àlies, càrrec o estat',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasValue
            ? IconButton(
                tooltip: 'Neteja cerca',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),
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
                _TreballadorTag(
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
              _TreballadorInfoPill(
                label: 'Estat',
                value: profile.estatLabel,
              ),
              _TreballadorInfoPill(
                label: 'Tasques',
                value: profile.tasquesCount.toString(),
              ),
              _TreballadorInfoPill(
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

class TreballadorListItemCard extends StatelessWidget {
  final TreballadorListItem treballador;
  final VoidCallback? onTap;

  const TreballadorListItemCard({
    super.key,
    required this.treballador,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _statusAccentColor(treballador.estatKey);
    final statusLabel = treballador.estatLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withOpacity(0.40), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TreballadorAvatar(
                imageUrl: treballador.fotoUrl,
                fullName: treballador.nomComplet,
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treballador.nomComplet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TreballadorStatusChip(
                    label: statusLabel,
                    color: accent,
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
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

class TreballadorListEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const TreballadorListEmptyState({
    super.key,
    this.title = 'No hi ha treballadors',
    this.message = 'Encara no hi ha cap treballador disponible per mostrar.',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 42,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              errorBuilder: (_, __, ___) => _AvatarFallback(
                initials: initials,
              ),
            )
          : _AvatarFallback(
              initials: initials,
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (initials.isEmpty) {
      return Icon(
        Icons.person,
        color: scheme.primary,
        size: 34,
      );
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _TreballadorTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _TreballadorTag({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

class _TreballadorStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TreballadorStatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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

class _TreballadorInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _TreballadorInfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

Color _statusAccentColor(String statusKey) {
  switch (statusKey) {
    case 'actiu':
      return Colors.green;
    case 'baixa':
      return Colors.orange;
    case 'acomiadat':
      return Colors.red;
    default:
      return Colors.grey;
  }
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