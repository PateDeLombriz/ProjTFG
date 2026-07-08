import 'package:flutter/material.dart';

import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/utils/date_formatter.dart';
import 'package:front_end/shared/widgets/app_info_pill.dart';
import 'package:front_end/shared/widgets/app_form_header_card.dart';
import 'package:front_end/shared/widgets/app_tag.dart';

abstract final class SolRecursStatusValues {
  static const String pendent = 'pendent';
  static const String aprovada = 'aprovada';
  static const String rebutjada = 'rebutjada';
}

abstract final class SolRecursEntregaFilter {
  static const String pendent = 'pendent';
  static const String entregat = 'entregat';
}

abstract final class SolRecursSortValues {
  static const String dataNecessitatAsc = 'data_necessitat_asc';
  static const String dataNecessitatDesc = 'data_necessitat_desc';
  static const String dataCreacioDesc = 'data_creacio_desc';
  static const String recursAsc = 'recurs_asc';
  static const String obraAsc = 'obra_asc';
  static const String aprovacioAsc = 'aprovacio_asc';
}

class SolRecursListHeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final int? activeCount;
  final int? pendentsCount;
  final int? entregatsCount;

  const SolRecursListHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    this.activeCount,
    this.pendentsCount,
    this.entregatsCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppFormHeaderCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.inventory_2_outlined,
      iconContainerSize: 72,
      badges: [
        AppTag(labelUsesAccent: false, icon: Icons.format_list_bulleted_rounded, label: count == 1 ? '1 sol·licitud' : '$count sol·licituds'),
        if (activeCount != null)
          AppTag(labelUsesAccent: false, icon: Icons.filter_alt_outlined, label: activeCount == 1 ? '1 visible' : '$activeCount visibles', accent: scheme.tertiary),
        if (pendentsCount != null)
          AppTag(labelUsesAccent: false, icon: Icons.schedule_rounded, label: pendentsCount == 1 ? '1 pendent' : '$pendentsCount pendents', accent: Colors.orange),
        if (entregatsCount != null)
          AppTag(labelUsesAccent: false, icon: Icons.check_circle_outline_rounded, label: entregatsCount == 1 ? '1 entregat' : '$entregatsCount entregats', accent: Colors.green),
      ],
    );
  }
}

class SolRecursListFilterBar extends StatelessWidget {
  final List<String> obraOptions;
  final String? selectedAprovacio;
  final String? selectedEntrega;
  final String? selectedObra;
  final String selectedSort;
  final ValueChanged<String?> onAprovacioChanged;
  final ValueChanged<String?> onEntregaChanged;
  final ValueChanged<String?> onObraChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback? onClearFilters;

  const SolRecursListFilterBar({
    super.key,
    required this.obraOptions,
    required this.selectedAprovacio,
    required this.selectedEntrega,
    required this.selectedObra,
    required this.selectedSort,
    required this.onAprovacioChanged,
    required this.onEntregaChanged,
    required this.onObraChanged,
    required this.onSortChanged,
    this.onClearFilters,
  });

  int get activeFiltersCount {
    var count = 0;
    if (selectedAprovacio != null && selectedAprovacio!.trim().isNotEmpty) {
      count++;
    }
    if (selectedEntrega != null && selectedEntrega!.trim().isNotEmpty) {
      count++;
    }
    if (selectedObra != null && selectedObra!.trim().isNotEmpty) {
      count++;
    }
    if (selectedSort != SolRecursSortValues.dataNecessitatAsc) count++;
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
                AppTag(labelUsesAccent: false,
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
              _SolRecursDropdownField<String>(
                width: 210,
                label: 'Aprovació',
                value: selectedAprovacio,
                onChanged: onAprovacioChanged,
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Totes'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursStatusValues.pendent,
                    child: Text('Pendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursStatusValues.aprovada,
                    child: Text('Aprovada'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursStatusValues.rebutjada,
                    child: Text('Rebutjada'),
                  ),
                ],
              ),
              _SolRecursDropdownField<String>(
                width: 210,
                label: 'Entrega',
                value: selectedEntrega,
                onChanged: onEntregaChanged,
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Totes'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursEntregaFilter.pendent,
                    child: Text('Pendent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursEntregaFilter.entregat,
                    child: Text('Entregat'),
                  ),
                ],
              ),
              _SolRecursDropdownField<String>(
                width: 240,
                label: 'Obra',
                value: selectedObra,
                onChanged: onObraChanged,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Totes les obres'),
                  ),
                  ...obraOptions.map(
                    (obra) => DropdownMenuItem<String?>(
                      value: obra,
                      child: Text(
                        obra,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              _SolRecursDropdownField<String>(
                width: 240,
                label: 'Ordena per',
                value: selectedSort,
                onChanged: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    onSortChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem<String?>(
                    value: SolRecursSortValues.dataNecessitatAsc,
                    child: Text('Necessitat antiga'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursSortValues.dataNecessitatDesc,
                    child: Text('Necessitat recent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursSortValues.dataCreacioDesc,
                    child: Text('Creació recent'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursSortValues.recursAsc,
                    child: Text('Recurs A-Z'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursSortValues.obraAsc,
                    child: Text('Obra A-Z'),
                  ),
                  DropdownMenuItem<String?>(
                    value: SolRecursSortValues.aprovacioAsc,
                    child: Text('Aprovació'),
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

class SolRecursSummaryCard extends StatelessWidget {
  final SolRecurs sollicitud;

  const SolRecursSummaryCard({
    super.key,
    required this.sollicitud,
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
              AppInfoPill(bgOpacity: 0.45,
                label: 'Aprovació',
                value: sollicitud.estatAprovacioLabel,
              ),
              AppInfoPill(bgOpacity: 0.45,
                label: 'Entrega',
                value: sollicitud.estatLabel,
              ),
              AppInfoPill(bgOpacity: 0.45,
                label: 'Quantitat',
                value: sollicitud.quantitatLabel,
              ),
              AppInfoPill(bgOpacity: 0.45,
                label: 'Obra',
                value: sollicitud.obraLabel,
              ),
              AppInfoPill(bgOpacity: 0.45,
                label: 'Recurs',
                value: sollicitud.recursLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SolRecursDatesCard extends StatelessWidget {
  final SolRecurs sollicitud;

  const SolRecursDatesCard({
    super.key,
    required this.sollicitud,
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
            'Dates',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.event_available_outlined,
            label: 'Necessitat',
            value: formatDate(sollicitud.dataNecessitat),
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.local_shipping_outlined,
            label: 'Entrega',
            value: formatDate(sollicitud.dataEntrega),
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.history_rounded,
            label: 'Creació',
            value: formatDateTime(sollicitud.dataCreacio),
          ),
        ],
      ),
    );
  }
}

class SolRecursProviderCard extends StatelessWidget {
  final SolRecurs sollicitud;

  const SolRecursProviderCard({
    super.key,
    required this.sollicitud,
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
            'Proveïdor i comentari',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SolRecursDateRow(
            icon: Icons.storefront_outlined,
            label: 'Proveïdor',
            value: sollicitud.proveidorLabel,
          ),
          const SizedBox(height: 12),
          if (sollicitud.hasComentari)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                sollicitud.comentari!.trim(),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            )
          else
            const _SolRecursEmptyInline(
              text: 'No hi ha comentari afegit.',
            ),
        ],
      ),
    );
  }
}

class SolRecursListItemCard extends StatelessWidget {
  final SolRecurs sollicitud;
  final VoidCallback? onTap;
  final VoidCallback? onAprovar;
  final VoidCallback? onRebutjar;

  const SolRecursListItemCard({
    super.key,
    required this.sollicitud,
    this.onTap,
    this.onAprovar,
    this.onRebutjar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentColor(context);
    final hasActions = onAprovar != null || onRebutjar != null;

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
            border: Border.all(color: accent.withOpacity(0.40), width: 1.4),
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
              _SolRecursLeadingBadge(
                icon: _leadingIcon(),
                color: accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sollicitud.recursLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SolRecursAprovacioChip(sollicitud: sollicitud),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sollicitud.obraLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppTag(labelUsesAccent: false,
                          icon: Icons.straighten_rounded,
                          label: sollicitud.quantitatLabel,
                          accent: accent,
                        ),
                        AppTag(labelUsesAccent: false,
                          icon: sollicitud.hasEntrega
                              ? Icons.local_shipping_outlined
                              : Icons.hourglass_bottom_rounded,
                          label: sollicitud.estatLabel,
                          accent: sollicitud.hasEntrega ? Colors.green : Colors.orange,
                        ),
                        AppTag(labelUsesAccent: false,
                          icon: Icons.event_available_outlined,
                          label: 'Necessitat: ${formatDate(sollicitud.dataNecessitat)}',
                        ),
                        if ((sollicitud.recurs?.tipusRecurs ?? '').trim().isNotEmpty)
                          AppTag(labelUsesAccent: false,
                            icon: Icons.category_outlined,
                            label: sollicitud.recurs!.tipusRecurs!.trim(),
                          ),
                      ],
                    ),
                    if (sollicitud.hasComentari) ...[
                      const SizedBox(height: 10),
                      Text(
                        _shortText(sollicitud.comentari!, maxLength: 80),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (hasActions) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (onRebutjar != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Rebutja'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: scheme.error,
                                  side: BorderSide(
                                    color: scheme.error.withOpacity(0.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: onRebutjar,
                              ),
                            ),
                          if (onRebutjar != null && onAprovar != null)
                            const SizedBox(width: 8),
                          if (onAprovar != null)
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Aprova'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: onAprovar,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _leadingIcon() {
    if (sollicitud.esAprovada) return Icons.check_circle_outline_rounded;
    if (sollicitud.esRebutjada) return Icons.cancel_outlined;
    return Icons.schedule_rounded;
  }

  Color _accentColor(BuildContext context) {
    if (sollicitud.esAprovada) return Colors.green;
    if (sollicitud.esRebutjada) return Theme.of(context).colorScheme.error;

    final necessitat = sollicitud.dataNecessitat;
    if (necessitat != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(necessitat.year, necessitat.month, necessitat.day);

      if (due.isBefore(today)) return Colors.red;
      if (due.difference(today).inDays <= 2) return Colors.orange;
    }

    return Theme.of(context).colorScheme.primary;
  }
}

class SolRecursDetailBottomSheet extends StatefulWidget {
  final SolRecurs sollicitud;
  final Future<void> Function(String estat) onSaveEstat;

  const SolRecursDetailBottomSheet({
    super.key,
    required this.sollicitud,
    required this.onSaveEstat,
  });

  @override
  State<SolRecursDetailBottomSheet> createState() => _SolRecursDetailBottomSheetState();
}

class _SolRecursDetailBottomSheetState extends State<SolRecursDetailBottomSheet> {
  late String _selectedEstat;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEstat = widget.sollicitud.estat;
  }

  bool get _hasChanges => _selectedEstat != widget.sollicitud.estat;

  Future<void> _save() async {
    if (_saving || !_hasChanges) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSaveEstat(_selectedEstat);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outline.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SolRecursLeadingBadge(
                      icon: Icons.inventory_2_outlined,
                      color: _statusColor(context, widget.sollicitud.estat),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sollicitud.recursLabel,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.sollicitud.obraLabel,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tanca',
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: scheme.outline.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: scheme.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Estat editable',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusPreviewChip(estat: _selectedEstat),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SolRecursDropdownField<String>(
                        width: double.infinity,
                        label: 'Aprovació',
                        value: _selectedEstat,
                        onChanged: _saving
                            ? (_) {}
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedEstat = value;
                                  _errorMessage = null;
                                });
                              },
                        items: const [
                          DropdownMenuItem<String>(
                            value: SolRecursStatusValues.pendent,
                            child: Text('Pendent'),
                          ),
                          DropdownMenuItem<String>(
                            value: SolRecursStatusValues.aprovada,
                            child: Text('Aprovada'),
                          ),
                          DropdownMenuItem<String>(
                            value: SolRecursStatusValues.rebutjada,
                            child: Text('Rebutjada'),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: scheme.error,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SolRecursSummaryCard(sollicitud: widget.sollicitud),
                const SizedBox(height: 12),
                SolRecursDatesCard(sollicitud: widget.sollicitud),
                const SizedBox(height: 12),
                SolRecursProviderCard(sollicitud: widget.sollicitud),
                const SizedBox(height: 12),
                _ResourceInfoCard(sollicitud: widget.sollicitud),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel·la'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving || !_hasChanges ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Guardant...' : 'Guarda canvis'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SolRecursLoadingCard extends StatelessWidget {
  const SolRecursLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 160,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
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

class SolRecursListErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SolRecursListErrorState({
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

class _ResourceInfoCard extends StatelessWidget {
  final SolRecurs sollicitud;

  const _ResourceInfoCard({required this.sollicitud});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tipus = sollicitud.recurs?.tipusRecurs?.trim();
    final unitats = sollicitud.recurs?.unitatsMesura?.trim();

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
            'Informació del recurs',
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
              AppInfoPill(bgOpacity: 0.45,
                label: 'ID recurs',
                value: sollicitud.idRecurs.toString(),
              ),
              if (tipus != null && tipus.isNotEmpty)
                AppInfoPill(bgOpacity: 0.45,label: 'Tipus', value: tipus),
              if (unitats != null && unitats.isNotEmpty)
                AppInfoPill(bgOpacity: 0.45,label: 'Unitats', value: unitats),
              if (sollicitud.id_treballador != null)
                AppInfoPill(bgOpacity: 0.45,
                  label: 'Treballador',
                  value: '#${sollicitud.id_treballador}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPreviewChip extends StatelessWidget {
  final String estat;

  const _StatusPreviewChip({required this.estat});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, estat);
    final label = _statusLabel(estat);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SolRecursLeadingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SolRecursLeadingBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }
}

class _SolRecursAprovacioChip extends StatelessWidget {
  final SolRecurs sollicitud;

  const _SolRecursAprovacioChip({required this.sollicitud});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, sollicitud.estat);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        sollicitud.estatAprovacioLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class _SolRecursDateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SolRecursDateRow({
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
            color: scheme.primary,
            size: 20,
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
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SolRecursEmptyInline extends StatelessWidget {
  final String text;

  const _SolRecursEmptyInline({
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

class _SolRecursDropdownField<T> extends StatelessWidget {
  final String label;
  final double width;
  final T? value;
  final ValueChanged<T?> onChanged;
  final List<DropdownMenuItem<T?>> items;

  const _SolRecursDropdownField({
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
            borderSide: BorderSide(color: scheme.outline.withOpacity(0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outline.withOpacity(0.10)),
          ),
        ),
      ),
    );
  }
}

String _shortText(String value, {required int maxLength}) {
  final text = value.trim();
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

String _statusLabel(String estat) {
  switch (estat) {
    case SolRecursStatusValues.aprovada:
      return 'Aprovada';
    case SolRecursStatusValues.rebutjada:
      return 'Rebutjada';
    case SolRecursStatusValues.pendent:
    default:
      return 'Pendent';
  }
}

Color _statusColor(BuildContext context, String estat) {
  final scheme = Theme.of(context).colorScheme;

  switch (estat) {
    case SolRecursStatusValues.aprovada:
      return Colors.green;
    case SolRecursStatusValues.rebutjada:
      return scheme.error;
    case SolRecursStatusValues.pendent:
    default:
      return Colors.orange;
  }
}


class SolRecursFormHeaderCard extends StatelessWidget {
  final bool batchMode;
  final bool editing;
  final int? lineCount;

  const SolRecursFormHeaderCard({
    super.key,
    required this.batchMode,
    required this.editing,
    this.lineCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppFormHeaderCard(
      title: batchMode
          ? 'Nou lot de sol·licituds'
          : editing
              ? 'Editar sol·licitud'
              : 'Nova sol·licitud',
      subtitle: batchMode
          ? 'Crea diverses peticions de recursos per a la mateixa obra.'
          : editing
              ? 'Actualitza les dades principals de la petició de recurs.'
              : 'Registra una petició de material o recurs associada a una obra.',
      icon: batchMode ? Icons.playlist_add_rounded : Icons.inventory_2_outlined,
      iconContainerSize: 62,
      badges: [
        AppTag(
          labelUsesAccent: false,
          icon: batchMode ? Icons.view_list_rounded : Icons.edit_note_rounded,
          label: batchMode ? 'Mode lot' : editing ? 'Mode edició' : 'Mode creació',
          accent: scheme.primary,
        ),
        if (lineCount != null)
          AppTag(
            labelUsesAccent: false,
            icon: Icons.format_list_numbered_rounded,
            label: lineCount == 1 ? '1 línia' : '$lineCount línies',
            accent: scheme.tertiary,
          ),
      ],
    );
  }
}

class SolRecursFormSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final int? count;
  final VoidCallback? onAdd;
  final String? addTooltip;
  final bool initiallyExpanded;

  const SolRecursFormSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.onAdd,
    this.addTooltip,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = count == null
        ? null
        : (count == 1 ? '1 element' : '$count elements');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAdd != null)
                IconButton(
                  tooltip: addTooltip ?? 'Afegir',
                  visualDensity: VisualDensity.compact,
                  onPressed: onAdd,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: scheme.primary,
                  ),
                ),
              Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}

class SolRecursFormDateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool requiredField;

  const SolRecursFormDateTile({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withOpacity(0.20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: scheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requiredField ? '$label *' : label,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date == null ? 'Selecciona una data' : formatDate(date),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class SolRecursDraftCard extends StatelessWidget {
  final SolRecursDraft draft;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SolRecursDraftCard({
    super.key,
    required this.draft,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SolRecursLeadingBadge(
                icon: Icons.inventory_2_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.recurs.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppTag(labelUsesAccent: false,
                          icon: Icons.numbers_rounded,
                          label: '${draft.quantitat} ${draft.recurs.unitat}',
                          accent: scheme.primary,
                        ),
                        AppTag(labelUsesAccent: false,
                          icon: Icons.event_rounded,
                          label: formatDate(draft.dataNecessitat),
                          accent: scheme.tertiary,
                        ),
                        if (draft.proveidor?.trim().isNotEmpty == true)
                          AppTag(labelUsesAccent: false,
                            icon: Icons.storefront_outlined,
                            label: draft.proveidor!.trim(),
                            accent: scheme.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Eliminar línia',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SolRecursDraftEditorSheet extends StatefulWidget {
  final List<RecursOption> recursos;
  final SolRecursDraft? initial;

  const SolRecursDraftEditorSheet({
    super.key,
    required this.recursos,
    this.initial,
  });

  @override
  State<SolRecursDraftEditorSheet> createState() => _SolRecursDraftEditorSheetState();
}

class _SolRecursDraftEditorSheetState extends State<SolRecursDraftEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  RecursOption? _recurs;
  final _quantCtrl = TextEditingController();
  final _comentCtrl = TextEditingController();
  final _provCtrl = TextEditingController();
  DateTime? _dataNecessitat;
  DateTime? _dataEntrega;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _recurs = initial.recurs;
      _quantCtrl.text = initial.quantitat.toString();
      _comentCtrl.text = initial.comentari ?? '';
      _provCtrl.text = initial.proveidor ?? '';
      _dataNecessitat = initial.dataNecessitat;
      _dataEntrega = initial.dataEntrega;
    }
  }

  @override
  void dispose() {
    _quantCtrl.dispose();
    _comentCtrl.dispose();
    _provCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNeedDate() async {
    final picked = await _pickDate(context, _dataNecessitat);
    if (picked != null) setState(() => _dataNecessitat = picked);
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await _pickDate(context, _dataEntrega);
    if (picked != null) setState(() => _dataEntrega = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_dataNecessitat == null) return;
    Navigator.of(context).pop(
      SolRecursDraft(
        recurs: _recurs!,
        quantitat: int.parse(_quantCtrl.text),
        dataNecessitat: _dataNecessitat!,
        dataEntrega: _dataEntrega,
        comentari: _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
        proveidor: _provCtrl.text.trim().isEmpty ? null : _provCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                        color: scheme.outline.withOpacity(0.30),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _SolRecursLeadingBadge(
                        icon: Icons.add_box_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.initial == null ? 'Afegir línia' : 'Editar línia',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<RecursOption>(
                    value: _recurs,
                    decoration: _inputDecoration(context, 'Recurs *', Icons.inventory_2_outlined),
                    items: widget.recursos
                        .map(
                          (r) => DropdownMenuItem<RecursOption>(
                            value: r,
                            child: Text('${r.nom}${r.unitat.isEmpty ? '' : ' (${r.unitat})'}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _recurs = value),
                    validator: (value) => value == null ? 'Selecciona un recurs' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(context, 'Quantitat *', Icons.numbers_rounded),
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0) return 'Entra un enter > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SolRecursFormDateTile(
                    label: 'Data necessitat',
                    date: _dataNecessitat,
                    requiredField: true,
                    onTap: _pickNeedDate,
                  ),
                  const SizedBox(height: 12),
                  SolRecursFormDateTile(
                    label: 'Data entrega',
                    date: _dataEntrega,
                    onTap: _pickDeliveryDate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _provCtrl,
                    decoration: _inputDecoration(context, 'Proveïdor', Icons.storefront_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _comentCtrl,
                    decoration: _inputDecoration(context, 'Comentari', Icons.notes_rounded),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel·la'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _dataNecessitat == null ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Desa'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String label, IconData icon) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: scheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );
}

Future<DateTime?> _pickDate(BuildContext context, DateTime? current) {
  return showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
}
