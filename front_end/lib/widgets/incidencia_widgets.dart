import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/incidencia/incidenciaDetail_screen.dart';

/* ─────────────────────── LLISTAT / FILTRES ─────────────────────── */

class IncidenciaListHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;

  const IncidenciaListHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: scheme.primary,
              size: 32,
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
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _IncidenciaTag(
                      icon: Icons.list_alt_outlined,
                      label: count == 1 ? '1 incidència' : '$count incidències',
                    ),
                    _IncidenciaTag(
                      icon: Icons.business_outlined,
                      label: 'Context empresa',
                      accent: scheme.tertiary,
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

class IncidenciaSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const IncidenciaSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cerca per descripció, obra, estat o categoria',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Neteja cerca',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.55)),
        ),
      ),
    );
  }
}

class IncidenciaFilterBar extends StatelessWidget {
  final List<IncidenciaObraFilterOption> obres;
  final int? selectedObraId;
  final String? selectedEstat;
  final int? selectedPrioritat;
  final String? selectedCriticitat;
  final String selectedSort;
  final ValueChanged<int?> onObraChanged;
  final ValueChanged<String?> onEstatChanged;
  final ValueChanged<int?> onPrioritatChanged;
  final ValueChanged<String?> onCriticitatChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback? onClearFilters;

  const IncidenciaFilterBar({
    super.key,
    required this.obres,
    required this.selectedObraId,
    required this.selectedEstat,
    required this.selectedPrioritat,
    required this.selectedCriticitat,
    required this.selectedSort,
    required this.onObraChanged,
    required this.onEstatChanged,
    required this.onPrioritatChanged,
    required this.onCriticitatChanged,
    required this.onSortChanged,
    this.onClearFilters,
  });

  int get activeFiltersCount {
    var count = 0;
    if (selectedObraId != null) count++;
    if (selectedEstat != null && selectedEstat!.trim().isNotEmpty) count++;
    if (selectedPrioritat != null) count++;
    if (selectedCriticitat != null && selectedCriticitat!.trim().isNotEmpty) {
      count++;
    }
    if (selectedSort != _IncidenciaSortValues.mesRecents) count++;
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
              Icon(
                Icons.tune_rounded,
                color: scheme.primary,
              ),
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
                _IncidenciaTag(
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
              _IncidenciaDropdownField<int>(
                width: 250,
                label: 'Obra',
                value: selectedObraId,
                onChanged: onObraChanged,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Totes les obres'),
                  ),
                  ...obres.map(
                    (obra) => DropdownMenuItem<int?>(
                      value: obra.id,
                      child: Text(
                        obra.nom,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              _IncidenciaDropdownField<String>(
                width: 190,
                label: 'Estat',
                value: selectedEstat,
                onChanged: onEstatChanged,
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tots'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'pendent',
                    child: Text('Pendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'en_curs',
                    child: Text('En curs'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'resolta',
                    child: Text('Resolta'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'tancada',
                    child: Text('Tancada'),
                  ),
                ],
              ),
              _IncidenciaDropdownField<int>(
                width: 170,
                label: 'Prioritat',
                value: selectedPrioritat,
                onChanged: onPrioritatChanged,
                items: const [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Totes'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 1,
                    child: Text('1'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 2,
                    child: Text('2'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 3,
                    child: Text('3'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 4,
                    child: Text('4'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 5,
                    child: Text('5'),
                  ),
                ],
              ),
              _IncidenciaDropdownField<String>(
                width: 190,
                label: 'Criticitat',
                value: selectedCriticitat,
                onChanged: onCriticitatChanged,
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Totes'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'alta',
                    child: Text('Alta'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'mitjana',
                    child: Text('Mitjana'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'baixa',
                    child: Text('Baixa'),
                  ),
                ],
              ),
              _IncidenciaDropdownField<String>(
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
                    value: _IncidenciaSortValues.mesRecents,
                    child: Text('Més recents'),
                  ),
                  DropdownMenuItem<String?>(
                    value: _IncidenciaSortValues.mesAntigues,
                    child: Text('Més antigues'),
                  ),
                  DropdownMenuItem<String?>(
                    value: _IncidenciaSortValues.criticitatDesc,
                    child: Text('Criticitat descendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: _IncidenciaSortValues.prioritatDesc,
                    child: Text('Prioritat descendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: _IncidenciaSortValues.obraAsc,
                    child: Text('Obra A-Z'),
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

class IncidenciaListItemCard extends StatelessWidget {
  final IncidenciaListItem item;

  const IncidenciaListItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incidencia = item.incidencia;
    final accent = _criticitatColor(incidencia.criticitat);

    final obraNom = incidencia.obraNom ?? 'No sambem el nom de l\'obra';
    final estatLabel = _estatLabel(incidencia.estat);
    final categoriaLabel = _categoriaLabel(incidencia.categoria);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidenciaProfileScreen(incidenciaId: incidencia.id))),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outline.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 16,
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
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        obraNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Incidència #${incidencia.id}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _textOrFallback(_shortText(incidencia.descripcio, 180)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IncidenciaTag(
                  icon: Icons.flag_outlined,
                  label: estatLabel,
                ),
                _IncidenciaTag(
                  icon: Icons.crisis_alert_outlined,
                  label: 'Criticitat ${incidencia.criticitat}',
                  accent: accent,
                ),
                _IncidenciaTag(
                  icon: Icons.priority_high_rounded,
                  label: 'Prioritat ${incidencia.prioritat}',
                  accent: scheme.secondary,
                ),
                _IncidenciaTag(
                  icon: Icons.category_outlined,
                  label: categoriaLabel,
                  accent: scheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _IncidenciaInfoPill(
                  label: 'Obra',
                  value: obraNom,
                ),
                _IncidenciaInfoPill(
                  label: 'Inici',
                  value: _formatDate(incidencia.dataInici),
                ),
                _IncidenciaInfoPill(
                  label: 'Fi',
                  value: _formatDate(incidencia.dataFi),
                ),
                _IncidenciaInfoPill(
                  label: 'Tasca',
                  value: incidencia.idTasca?.toString() ?? 'Sense tasca',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IncidenciaListEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const IncidenciaListEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class IncidenciaListErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const IncidenciaListErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.error.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: scheme.error,
                size: 34,
              ),
              const SizedBox(height: 14),
              const Text(
                'No s’han pogut carregar les incidències',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => onRetry!(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Torna-ho a provar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────── DETALL EXISTENT ─────────────────────── */

class IncidenciaHeaderCard extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaHeaderCard({
    super.key,
    required this.incidencia,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _criticitatColor(incidencia.criticitat);

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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: accent,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incidència #${incidencia.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _textOrFallback(incidencia.descripcio),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _IncidenciaTag(
                      icon: Icons.flag_outlined,
                      label: _estatLabel(incidencia.estat),
                    ),
                    _IncidenciaTag(
                      icon: Icons.priority_high_rounded,
                      label: 'Prioritat ${incidencia.prioritat}',
                    ),
                    _IncidenciaTag(
                      icon: Icons.crisis_alert_outlined,
                      label: 'Criticitat ${incidencia.criticitat}',
                      accent: accent,
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

class IncidenciaCompactInfoPanel extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaCompactInfoPanel({
    super.key,
    required this.incidencia,
  });

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
          Text(
            'Informació general',
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
              _IncidenciaInfoPill(
                label: 'Estat',
                value: _estatLabel(incidencia.estat),
              ),
              _IncidenciaInfoPill(
                label: 'Inici',
                value: _formatDate(incidencia.dataInici),
              ),
              _IncidenciaInfoPill(
                label: 'Fi',
                value: _formatDate(incidencia.dataFi),
              ),
              _IncidenciaInfoPill(
                label: 'Prioritat',
                value: incidencia.prioritat.toString(),
              ),
              _IncidenciaInfoPill(
                label: 'Criticitat',
                value: incidencia.criticitat.toString(),
              ),
              _IncidenciaInfoPill(
                label: 'Categoria',
                value: _categoriaLabel(incidencia.categoria),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IncidenciaSectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Widget child;
  final bool initiallyExpanded;

  const IncidenciaSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final subtitle = count == null
        ? null
        : (count == 1 ? '1 element' : '$count elements');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: scheme.primary),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
          children: [child],
        ),
      ),
    );
  }
}

class IncidenciaEmptyState extends StatelessWidget {
  final String text;

  const IncidenciaEmptyState({
    super.key,
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

class IncidenciaObraCard extends StatelessWidget {
  final Obra obra;
  final VoidCallback? onTap;

  const IncidenciaObraCard({
    super.key,
    required this.obra,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _IncidenciaRelationCard(
      title: obra.nom,
      subtitle: obra.hasDescription ? obra.descripcio : null,
      icon: Icons.apartment_rounded,
      chips: [
        _IncidenciaRelationChip(
          icon: Icons.flag_outlined,
          label: _textOrFallback(obra.estat),
        ),
        _IncidenciaRelationChip(
          icon: Icons.location_on_outlined,
          label: obra.locationLabel,
        ),
      ],
      onTap: onTap,
    );
  }
}

class IncidenciaTascaCard extends StatelessWidget {
  final Tasca tasca;
  final VoidCallback? onTap;

  const IncidenciaTascaCard({
    super.key,
    required this.tasca,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _IncidenciaRelationCard(
      title: tasca.etiqueta,
      subtitle: tasca.descripcioCurta,
      icon: Icons.task_alt_outlined,
      chips: [
        _IncidenciaRelationChip(
          icon: Icons.assignment_outlined,
          label: tasca.descripcioCurta,
        ),
        _IncidenciaRelationChip(
          icon: Icons.visibility_outlined,
          label: tasca.visibilitatTasca ? 'Visible' : 'Oculta',
        ),
      ],
      onTap: onTap,
    );
  }
}

class IncidenciaSolucioCard extends StatelessWidget {
  final IncidenciaSolucioItem solucio;
  final VoidCallback? onTap;

  const IncidenciaSolucioCard({
    super.key,
    required this.solucio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solució #${solucio.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _textOrFallback(solucio.descripcio),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IncidenciaInfoPill(
                  label: 'Eficàcia',
                  value: solucio.eficacia?.toString() ?? '—',
                ),
                _IncidenciaInfoPill(
                  label: 'Cost monetari',
                  value: solucio.costMonetari?.toString() ?? '—',
                ),
                _IncidenciaInfoPill(
                  label: 'Cost temporal',
                  value: solucio.costTemporal?.toString() ?? '—',
                ),
                _IncidenciaInfoPill(
                  label: 'Impacte',
                  value: solucio.impacte?.toString() ?? '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IncidenciaSolucionsSectionBody extends StatelessWidget {
  final List<IncidenciaSolucioItem> solucions;
  final void Function(IncidenciaSolucioItem item)? onTapItem;

  const IncidenciaSolucionsSectionBody({
    super.key,
    required this.solucions,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (solucions.isEmpty) {
      return const IncidenciaEmptyState(
        text: 'Aquesta incidència no té solucions registrades.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < solucions.length; i++) ...[
          IncidenciaSolucioCard(
            solucio: solucions[i],
            onTap: onTapItem == null ? null : () => onTapItem!(solucions[i]),
          ),
          if (i != solucions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/* ───────────────────────── PRIVATS ───────────────────────── */

class _IncidenciaDropdownField<T> extends StatelessWidget {
  final String label;
  final double width;
  final T? value;
  final ValueChanged<T?> onChanged;
  final List<DropdownMenuItem<T?>> items;

  const _IncidenciaDropdownField({
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

class _IncidenciaRelationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<_IncidenciaRelationChip> chips;
  final VoidCallback? onTap;

  const _IncidenciaRelationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidenciaRelationChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IncidenciaRelationChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidenciaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _IncidenciaTag({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidenciaInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _IncidenciaInfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
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

abstract final class _IncidenciaSortValues {
  static const String mesRecents = 'mes_recents';
  static const String mesAntigues = 'mes_antigues';
  static const String criticitatDesc = 'criticitat_desc';
  static const String prioritatDesc = 'prioritat_desc';
  static const String obraAsc = 'obra_asc';
}

Color _criticitatColor(int criticitat) {
  if (criticitat >= 7) return Colors.red;
  if (criticitat >= 4) return Colors.orange;
  return Colors.green;
}

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

String _estatLabel(String? estat) {
  final text = estat?.trim().toLowerCase();
  if (text == null || text.isEmpty) return 'Sense estat';

  switch (text) {
    case 'pendent':
      return 'Pendent';
    case 'en_curs':
    case 'en curs':
      return 'En curs';
    case 'resolta':
      return 'Resolta';
    case 'tancada':
      return 'Tancada';
    default:
      return estat!.trim();
  }
}

String _categoriaLabel(int? categoria) {
  switch (categoria) {
    case 1:
      return 'Material';
    case 2:
      return 'Tècnica';
    case 3:
      return 'Seguretat';
    case 4:
      return 'Planificació';
    default:
      return 'Sense categoria';
  }
}


String _shortText(String? text, int maxLength) {
  final value = text?.trim();
  if (value == null || value.isEmpty) return '—';
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 3)}...';
}

String _textOrFallback(String? text) {
  final value = text?.trim();
  if (value == null || value.isEmpty) return '—';
  return value;
}