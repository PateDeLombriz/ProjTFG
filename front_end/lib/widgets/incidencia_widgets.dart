import 'package:flutter/material.dart';

import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/utils/date_formatter.dart';
import 'package:front_end/shared/widgets/app_card_action_button.dart';
import 'package:front_end/utils/status_color_helper.dart';
import 'package:front_end/shared/widgets/app_info_pill.dart';
import 'package:front_end/shared/widgets/app_status_chip.dart';
import 'package:front_end/shared/widgets/app_form_header_card.dart';
import 'package:front_end/shared/widgets/app_tag.dart';

abstract final class IncidenciaSortValues {
  static const String mesRecents = 'mes_recents';
  static const String mesAntigues = 'mes_antigues';
  static const String criticitatDesc = 'criticitat_desc';
  static const String prioritatDesc = 'prioritat_desc';
  static const String obraAsc = 'obra_asc';
  static const String estatAsc = 'estat_asc';
}
const List<String> listEstats = ['oberta', 'gestionada', 'tancada', 'cancel·lada'];
const List<String> cleanListEstats = ['Oberta', 'Gestionada', 'Tancada', 'Cancel·lada'];
  

/* ─────────────────────── LLISTAT / FILTRES ─────────────────────── */

class IncidenciaListHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final int? activeCount;
  final int? criticalCount;
  final int? pendingCount;
  
  const IncidenciaListHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    this.activeCount,
    this.criticalCount,
    this.pendingCount,
  });
  
  

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppFormHeaderCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.warning_amber_rounded,
      accent: scheme.error,
      iconContainerSize: 72,
      badges: [
        AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.format_list_bulleted_rounded, label: count == 1 ? '1 incidència' : '$count incidències'),
        if (activeCount != null)
          AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.filter_alt_outlined, label: activeCount == 1 ? '1 visible' : '$activeCount visibles', accent: scheme.tertiary),
        if (criticalCount != null)
          AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.crisis_alert_outlined, label: criticalCount == 1 ? '1 crítica' : '$criticalCount crítiques', accent: Colors.red),
        if (pendingCount != null)
          AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.schedule_rounded, label: pendingCount == 1 ? '1 pendent' : '$pendingCount pendents', accent: Colors.orange),
      ],
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
    if (selectedSort != IncidenciaSortValues.mesRecents) count++;
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
                AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tots'),
                  ),
                  DropdownMenuItem<String?>(
                    value: listEstats[0],
                    child: Text(cleanListEstats[0]),
                  ),
                   DropdownMenuItem<String?>(
                    value: listEstats[1],
                    child: Text(cleanListEstats[1]),
                  ),
                   DropdownMenuItem<String?>(
                    value: listEstats[3],
                    child: Text(cleanListEstats[3]),
                  ),
                   DropdownMenuItem<String?>(
                    value: listEstats[2],
                    child: Text(cleanListEstats[2]),
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
                width: 230,
                label: 'Ordena per',
                value: selectedSort,
                onChanged: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    onSortChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem<String?>(
                    value: IncidenciaSortValues.mesRecents,
                    child: Text('Més recents'),
                  ),
                  DropdownMenuItem<String?>(
                    value: IncidenciaSortValues.mesAntigues,
                    child: Text('Més antigues'),
                  ),
                  DropdownMenuItem<String?>(
                    value: IncidenciaSortValues.criticitatDesc,
                    child: Text('Criticitat descendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: IncidenciaSortValues.prioritatDesc,
                    child: Text('Prioritat descendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: IncidenciaSortValues.obraAsc,
                    child: Text('Obra A-Z'),
                  ),
                  DropdownMenuItem<String?>(
                    value: IncidenciaSortValues.estatAsc,
                    child: Text('Estat'),
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
  final VoidCallback? onTap;

  const IncidenciaListItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incidencia = item.incidencia;
    final accent = colorForCriticitat(incidencia.criticitat);
    final colorEstat = colorByEstat(incidencia.estat);
    final obraNom = incidencia.obraNom ?? 'Obra sense nom';
    final estatLabel = _estatLabel(incidencia.estat);
    final categoriaLabel = _categoriaLabel(incidencia.categoria);

    final tags = <Widget>[
      AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        icon: Icons.crisis_alert_outlined,
        label: 'Criticitat ${incidencia.criticitat}',
        accent: accent,
      ),
      AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        icon: Icons.priority_high_rounded,
        label: 'Prioritat ${incidencia.prioritat}',
        accent: colorForPriority(incidencia.prioritat),
      ),
      if (categoriaLabel.trim().isNotEmpty)
        AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          icon: Icons.category_outlined,
          label: categoriaLabel,
          accent: scheme.tertiary,
        ),
    ];

    final infoPills = <Widget>[
      if (incidencia.dataInici != null)
        AppInfoPill(
          label: 'Inici',
          value: formatDate(incidencia.dataInici),
        ),
      if (incidencia.dataFi != null)
        AppInfoPill(
          label: 'Fi',
          value: formatDate(incidencia.dataFi),
        ),
      if (incidencia.idTasca != null)
        AppInfoPill(
          label: 'Tasca',
          value: incidencia.idTasca.toString(),
        ),
      AppInfoPill(
        label: 'ID',
        value: '#${incidencia.id}',
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withOpacity(0.34), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: colorEstat.withOpacity(0.92),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _textOrFallback(
                                        _shortText(incidencia.descripcio, 90),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      obraNom,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppStatusChip(showBorder: true, bgOpacity: 0.10,
                                    label: estatLabel,
                                    color: colorEstat,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: scheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: tags,
                            ),
                          ],
                          if (infoPills.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: infoPills,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: scheme.error,
                  size: 34,
                ),
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
  final String? estatOverride;
  final VoidCallback? onChangeEstat;

  const IncidenciaHeaderCard({
    super.key,
    required this.incidencia,
    this.estatOverride,
    this.onChangeEstat,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = colorForCriticitat(incidencia.criticitat);
    final displayEstat = estatOverride ?? incidencia.estat;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.18)),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Incidència #${incidencia.id}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (onChangeEstat != null) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: onChangeEstat,
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('Estat'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
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
                    AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      icon: Icons.flag_outlined,
                      label: _estatLabel(displayEstat),
                      accent: scheme.primary,
                    ),
                    AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      icon: Icons.priority_high_rounded,
                      label: 'Prioritat ${incidencia.prioritat}',
                    ),
                    AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  final String? estatOverride;

  const IncidenciaCompactInfoPanel({
    super.key,
    required this.incidencia,
    this.estatOverride,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayEstat = estatOverride ?? incidencia.estat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informació general',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppInfoPill(
                label: 'Estat',
                value: _estatLabel(displayEstat),
              ),
              AppInfoPill(
                label: 'Inici',
                value: formatDate(incidencia.dataInici),
              ),
              AppInfoPill(
                label: 'Fi',
                value: formatDate(incidencia.dataFi),
              ),
              AppInfoPill(
                label: 'Prioritat',
                value: incidencia.prioritat.toString(),
              ),
              AppInfoPill(
                label: 'Criticitat',
                value: incidencia.criticitat.toString(),
              ),
              AppInfoPill(
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

class IncidenciaSectionBlock extends StatefulWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Widget child;
  final bool initiallyExpanded;
  final VoidCallback? onAdd;//Esto sirve para añadir un botón de acción en la sección, por ejemplo, para agregar una nueva incidencia o elemento relacionado.
  final String? addTooltip;

  const IncidenciaSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
    this.onAdd,
    this.addTooltip,
  });

  @override
  State<IncidenciaSectionBlock> createState() => _IncidenciaSectionBlockState();
}

class _IncidenciaSectionBlockState extends State<IncidenciaSectionBlock> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final subtitle = widget.count == null
        ? null
        : (widget.count == 1 ? '1 element' : '${widget.count} elements');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (value) {
            setState(() => _expanded = value);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(widget.icon, color: scheme.primary),
          title: Text(
            widget.title,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onAdd != null) ...[
                IconButton(
                  tooltip: widget.addTooltip ?? 'Afegir',
                  onPressed: widget.onAdd,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: scheme.primary,
              ),
            ],
          ),
          children: [widget.child],
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
  final VoidCallback? onEdit;
  final VoidCallback? onUnlink;
  final VoidCallback? onDelete;

  const IncidenciaTascaCard({
    super.key,
    required this.tasca,
    this.onTap,
    this.onEdit,
    this.onUnlink,
    this.onDelete,
  });

  bool get _hasActions =>
      onEdit != null || onUnlink != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = tasca.visibilitatTasca ? Colors.green : Colors.grey;

    final details = <Widget>[
      AppInfoPill(
        label: 'Prioritat',
        value: tasca.prioritat?.toString() ?? '—',
      ),
      AppInfoPill(
        label: 'Inici',
        value: formatDate(tasca.dataInici),
      ),
      AppInfoPill(
        label: 'Fi',
        value: formatDate(tasca.dataFi),
      ),
      AppInfoPill(
        label: 'Visible',
        value: tasca.visibilitatTasca ? 'Sí' : 'No',
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                constraints: const BoxConstraints(minHeight: 112),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.task_alt_outlined,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(
                              tasca.descripcioCurta,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: details,
                            ),
                          ],
                        ),
                      ),
                      if (_hasActions) ...[
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              AppCardActionButton(
                                tooltip: 'Editar tasca',
                                icon: Icons.edit_outlined,
                                onPressed: onEdit!,
                              ),
                            if (onUnlink != null) ...[
                              const SizedBox(height: 6),
                              AppCardActionButton(
                                tooltip: 'Desassociar tasca',
                                icon: Icons.link_off_rounded,
                                onPressed: onUnlink!,
                              ),
                            ],
                            if (onDelete != null) ...[
                              const SizedBox(height: 6),
                              AppCardActionButton(
                                tooltip: 'Eliminar tasca',
                                icon: Icons.delete_outline,
                                isDanger: true,
                                onPressed: onDelete!,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IncidenciaNoTascaPanel extends StatelessWidget {
  final VoidCallback? onAssignExisting;
  final VoidCallback? onCreateNew;

  const IncidenciaNoTascaPanel({
    super.key,
    this.onAssignExisting,
    this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surface,
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
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
              Icons.task_alt_outlined,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sense tasca associada',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Afegeix una tasca existent o crea una nova tasca quan connectem la persistència.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onAssignExisting != null)
                      _IncidenciaActionButton(
                        icon: Icons.playlist_add_check_rounded,
                        label: 'Associar existent',
                        onPressed: onAssignExisting!,
                      ),
                    if (onCreateNew != null)
                      _IncidenciaActionButton(
                        icon: Icons.add_task_rounded,
                        label: 'Crear tasca',
                        onPressed: onCreateNew!,
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

class IncidenciaSolucioCard extends StatelessWidget {
  final IncidenciaSolucioItem solucio;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const IncidenciaSolucioCard({
    super.key,
    required this.solucio,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final isDraft = solucio.id < 0;
    final hasActions = onEdit != null || onDelete != null;

    final metrics = <Widget>[
      AppInfoPill(
        label: 'Eficàcia',
        value: solucio.eficacia?.toString() ?? '—',
      ),
      AppInfoPill(
        label: 'Cost monetari',
        value: solucio.costMonetari?.toString() ?? '—',
      ),
      AppInfoPill(
        label: 'Cost temporal',
        value: solucio.costTemporal?.toString() ?? '—',
      ),
      AppInfoPill(
        label: 'Impacte',
        value: solucio.impacte?.toString() ?? '—',
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                constraints: const BoxConstraints(minHeight: 112),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.build_circle_outlined,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isDraft
                                        ? 'Solució nova'
                                        : 'Solució #${solucio.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                ),
                                if (isDraft)
                                  AppStatusChip(showBorder: true, bgOpacity: 0.10,
                                    label: 'Pendent',
                                    color: scheme.tertiary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _textOrFallback(solucio.descripcio),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: metrics,
                            ),
                          ],
                        ),
                      ),
                      if (hasActions) ...[
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              AppCardActionButton(
                                tooltip: 'Editar solució',
                                icon: Icons.edit_outlined,
                                onPressed: onEdit!,
                              ),
                            if (onDelete != null) ...[
                              const SizedBox(height: 6),
                              AppCardActionButton(
                                tooltip: 'Eliminar solució',
                                icon: Icons.delete_outline,
                                isDanger: true,
                                onPressed: onDelete!,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IncidenciaSolucionsSectionBody extends StatelessWidget {
  final List<IncidenciaSolucioItem> solucions;
  final VoidCallback? onAdd;
  final void Function(IncidenciaSolucioItem item)? onTapItem;
  final void Function(IncidenciaSolucioItem item)? onEdit;
  final void Function(IncidenciaSolucioItem item)? onDelete;

  const IncidenciaSolucionsSectionBody({
    super.key,
    required this.solucions,
    this.onAdd,
    this.onTapItem,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (solucions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IncidenciaEmptyState(
            text: 'Aquesta incidència no té solucions registrades.',
          ),
         //if (onAdd != null) ...[
         //  const SizedBox(height: 10),
         //  _IncidenciaActionButton(
         //    icon: Icons.add_rounded,
         //    label: 'Afegir solució',
         //    onPressed: onAdd!,
         //  ),
          ],
        //],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < solucions.length; i++) ...[
          IncidenciaSolucioCard(
            solucio: solucions[i],
            onTap: onTapItem == null ? null : () => onTapItem!(solucions[i]),
            onEdit: onEdit == null ? null : () => onEdit!(solucions[i]),
            onDelete: onDelete == null ? null : () => onDelete!(solucions[i]),
          ),
          if (i != solucions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class IncidenciaEstatBottomSheet extends StatefulWidget {
  final String? initialEstat;

  const IncidenciaEstatBottomSheet({
    super.key,
    this.initialEstat,
  });

  @override
  State<IncidenciaEstatBottomSheet> createState() =>
      _IncidenciaEstatBottomSheetState();
}

class _IncidenciaEstatBottomSheetState
    extends State<IncidenciaEstatBottomSheet> {
  late String _estat;

  @override
  void initState() {
    super.initState();
    _estat = _normalizeEstat(widget.initialEstat);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outline.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.flag_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Modificar estat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _estat,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Estat de la incidència',
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withOpacity(0.28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items:  [
              DropdownMenuItem(value: listEstats[0], child: Text(cleanListEstats[0])),
              DropdownMenuItem(value: listEstats[1], child: Text(cleanListEstats[1])),
              DropdownMenuItem(value: listEstats[2], child: Text(cleanListEstats[2])),
              DropdownMenuItem(value: listEstats[3], child: Text(cleanListEstats[3])),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _estat = value);
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel·lar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _estat),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _normalizeEstat(String? value) {
    final text = value?.trim().toLowerCase();
    switch (text) {
      case 'oberta':
      case 'gestionada':
      case 'tancada':
      case 'cancel·lada':
        return text!;
      default:
        return 'oberta';
    }
  }
}

class IncidenciaSolucioFormResult {
  final int? idTasca;
  final String descripcio;
  final int costMonetari;
  final int eficacia;
  final int costTemporal;
  final int impacte;

  const IncidenciaSolucioFormResult({
    this.idTasca,
    required this.descripcio,
    required this.costMonetari,
    required this.eficacia,
    required this.costTemporal,
    required this.impacte,
  });
}

class IncidenciaSolucioEditorSheet extends StatefulWidget {
  final IncidenciaSolucioItem? initial;
  final List<TascaOption> tasques;

  const IncidenciaSolucioEditorSheet({
    super.key,
    this.initial,
    this.tasques = const <TascaOption>[],
  });

  @override
  State<IncidenciaSolucioEditorSheet> createState() =>
      _IncidenciaSolucioEditorSheetState();
}

class _IncidenciaSolucioEditorSheetState
    extends State<IncidenciaSolucioEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _eficaciaCtrl;
  late final TextEditingController _costMonetariCtrl;
  late final TextEditingController _costTemporalCtrl;
  late final TextEditingController _impacteCtrl;
  int? _selectedTascaId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedTascaId = initial?.idTasca;
    _descCtrl = TextEditingController(text: initial?.descripcio ?? '');
    _eficaciaCtrl = TextEditingController(
      text: (initial?.eficacia ?? 0).toString(),
    );
    _costMonetariCtrl = TextEditingController(
      text: (initial?.costMonetari ?? 0).toString(),
    );
    _costTemporalCtrl = TextEditingController(
      text: (initial?.costTemporal ?? 0).toString(),
    );
    _impacteCtrl = TextEditingController(
      text: (initial?.impacte ?? 1).toString(),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _eficaciaCtrl.dispose();
    _costMonetariCtrl.dispose();
    _costTemporalCtrl.dispose();
    _impacteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.initial != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.outline.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.build_circle_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      editing ? 'Editar solució' : 'Afegir solució',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: _sheetInputDecoration(
                  context,
                  'Descripció *',
                  Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripció és obligatòria';
                  }
                  return null;
                },
              ),
              if (widget.tasques.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _selectedTascaId,
                  isExpanded: true,
                  decoration: _sheetInputDecoration(
                    context,
                    'Tasca associada',
                    Icons.link_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— Sense tasca —'),
                    ),
                    ...widget.tasques.map(
                      (tasca) => DropdownMenuItem<int?>(
                        value: tasca.id,
                        child: Text(
                          tasca.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTascaId = value);
                  },
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _numberField(context, _eficaciaCtrl, 'Eficàcia'),
                  _numberField(context, _costMonetariCtrl, 'Cost monetari'),
                  _numberField(context, _costTemporalCtrl, 'Cost temporal'),
                  _numberField(context, _impacteCtrl, 'Impacte'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel·lar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(editing ? 'Guardar' : 'Afegir'),
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

  Widget _numberField(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: _sheetInputDecoration(context, label, Icons.numbers_rounded),
      ),
    );
  }

  InputDecoration _sheetInputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withOpacity(0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  int _parseIntOrZero(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  int _parseImpacte(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) return 1;
    return value;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      IncidenciaSolucioFormResult(
        idTasca: _selectedTascaId,
        descripcio: _descCtrl.text.trim(),
        eficacia: _parseIntOrZero(_eficaciaCtrl),
        costMonetari: _parseIntOrZero(_costMonetariCtrl),
        costTemporal: _parseIntOrZero(_costTemporalCtrl),
        impacte: _parseImpacte(_impacteCtrl),
      ),
    );
  }
}

class IncidenciaFormHeaderCard extends StatelessWidget {
  final bool editing;
  final String estat;
  final int criticitat;
  final int prioritat;
  final String? obraLabel;

  const IncidenciaFormHeaderCard({
    super.key,
    required this.editing,
    required this.estat,
    required this.criticitat,
    required this.prioritat,
    this.obraLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = colorForCriticitat(criticitat);
    return AppFormHeaderCard(
      title: editing ? 'Editar incidència' : 'Nova incidència',
      subtitle: editing
          ? 'Actualitza les dades disponibles i gestiona les solucions associades.'
          : 'Registra una incidència i afegeix-hi les solucions necessàries.',
      icon: editing ? Icons.edit_note_rounded : Icons.add_alert_outlined,
      accent: accent,
      accentBorder: true,
      iconContainerSize: 64,
      badges: [
        AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.flag_outlined, label: _estatLabel(estat), accent: scheme.primary),
        AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.crisis_alert_outlined, label: 'Criticitat $criticitat', accent: accent),
        AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.priority_high_rounded, label: 'Prioritat $prioritat', accent: scheme.secondary),
        if (obraLabel != null && obraLabel!.trim().isNotEmpty)
          AppTag(borderRadius: 999, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), icon: Icons.apartment_rounded, label: obraLabel!.trim(), accent: scheme.tertiary),
      ],
    );
  }
}

class IncidenciaPreparedActionSheet extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String primaryLabel;

  const IncidenciaPreparedActionSheet({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.primaryLabel = 'Entesos',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outline.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.32),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withOpacity(0.08)),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded),
              label: Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── PRIVATS ───────────────────────── */

class _IncidenciaActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  const _IncidenciaActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.28)),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

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




String _estatLabel(String? estat) {
  final text = estat?.trim().toLowerCase();
  if (text == null || text.isEmpty) return 'Sense estat';

  switch (text) {
    case 'oberta':
      return 'Oberta';
    case 'gestionada':
      return 'Gestionada';
    case 'tancada':
      return 'Tancada';
    case 'cancel·lada':
      return 'Cancel·lada';
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
