import 'package:flutter/material.dart';

import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/services/sol_recurs_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_search_field.dart';
import 'package:front_end/widgets/sol_recurs_widgets.dart';

class RecursosScreen extends StatefulWidget {
  const RecursosScreen({super.key});

  @override
  State<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends State<RecursosScreen> {
  late final SolRecursService _service;
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _query = '';
  String? _selectedTipus;
  String _selectedSort = _RecursSortValues.nomAsc;
  List<RecursOption> _recursos = const [];

  @override
  void initState() {
    super.initState();
    _service = SolRecursService(baseUrl: ApiConstants.baseUrl);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    return _query.trim().isNotEmpty ||
        (_selectedTipus?.trim().isNotEmpty == true) ||
        _selectedSort != _RecursSortValues.nomAsc;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchRecursOptions();
      if (!mounted) return;
      setState(() {
        _recursos = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _selectedTipus = null;
      _selectedSort = _RecursSortValues.nomAsc;
      _searchController.clear();
    });
  }

  List<RecursOption> _filteredItems() {
    final query = _query.trim().toLowerCase();
    final tipus = _selectedTipus?.trim().toLowerCase();

    final items = _recursos.where((item) {
      if (query.isNotEmpty) {
        final values = [
          item.nom,
          item.unitat,
          item.tipus ?? '',
          item.stock?.toString() ?? '',
        ];
        if (!values.any((value) => value.toLowerCase().contains(query))) {
          return false;
        }
      }

      if (tipus != null && tipus.isNotEmpty) {
        if ((item.tipus ?? '').trim().toLowerCase() != tipus) return false;
      }

      return true;
    }).toList();

    switch (_selectedSort) {
      case _RecursSortValues.stockAsc:
        items.sort((a, b) => _stockValue(a).compareTo(_stockValue(b)));
        break;
      case _RecursSortValues.stockDesc:
        items.sort((a, b) => _stockValue(b).compareTo(_stockValue(a)));
        break;
      case _RecursSortValues.tipusAsc:
        items.sort((a, b) {
          final byType = (a.tipus ?? '').toLowerCase().compareTo((b.tipus ?? '').toLowerCase());
          if (byType != 0) return byType;
          return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
        });
        break;
      case _RecursSortValues.nomDesc:
        items.sort((a, b) => b.nom.toLowerCase().compareTo(a.nom.toLowerCase()));
        break;
      case _RecursSortValues.nomAsc:
      default:
        items.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        break;
    }

    return items;
  }

  double _stockValue(RecursOption item) => item.stock ?? 0;

  List<String> _tipusOptions() {
    final values = _recursos
        .map((item) => item.tipus?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  Future<void> _deleteRecurs(RecursOption recurs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar recurs'),
          content: Text('Vols eliminar ${recurs.nom}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·la'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    try {
      await _service.deleteRecurs(recurs.id);
      if (!mounted) return;
      _snack('Recurs eliminat.', success: true);
      await _load();
    } catch (error) {
      if (!mounted) return;
      _snack('Error eliminant el recurs: $error');
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredItems();

    return Scaffold(
      backgroundColor: scheme.primaryContainer.withOpacity(0.06),
      appBar: AppBar(
        title: const Text('Recursos'),
        actions: [
          IconButton(
            tooltip: 'Recarrega',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Neteja filtres',
            onPressed: _hasActiveFilters ? _clearFilters : null,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _RecursosHeaderCard(
              total: _recursos.length,
              visible: filtered.length,
              lowStock: _recursos.where((item) => _stockValue(item) < 10).length,
              tipusCount: _tipusOptions().length,
            ),
            const SizedBox(height: 14),
            AppSearchField(
              controller: _searchController,
              hintText: 'Cerca per recurs, obra, estat o proveïdor',
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                setState(() {
                  _query = '';
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(height: 14),
            _RecursosFilterBar(
              tipusOptions: _tipusOptions(),
              selectedTipus: _selectedTipus,
              selectedSort: _selectedSort,
              onTipusChanged: (value) => setState(() => _selectedTipus = value),
              onSortChanged: (value) => setState(() => _selectedSort = value),
              onClearFilters: _hasActiveFilters ? _clearFilters : null,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const SolRecursLoadingCard()
            else if (_error != null)
              SolRecursListErrorState(
                message: _error!,
                onRetry: _load,
              )
            else if (_recursos.isEmpty)
              const AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No hi ha recursos',
                message: 'Encara no hi ha cap recurs registrat.',
              )
            else if (filtered.isEmpty)
              const AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Cap recurs coincideix',
                message: 'Prova amb una altra cerca, tipus o ordenació.',
              )
            else
              ...List.generate(filtered.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filtered.length - 1 ? 0 : 12,
                  ),
                  child: _RecursCard(
                    recurs: filtered[index],
                    onEdit: () {
                      Navigator.pushNamed(
                        context,
                        '/editRecurs',
                        arguments: filtered[index],
                      );
                    },
                    onDelete: () => _deleteRecurs(filtered[index]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

abstract final class _RecursSortValues {
  static const nomAsc = 'nom_asc';
  static const nomDesc = 'nom_desc';
  static const stockAsc = 'stock_asc';
  static const stockDesc = 'stock_desc';
  static const tipusAsc = 'tipus_asc';
}

class _RecursosHeaderCard extends StatelessWidget {
  final int total;
  final int visible;
  final int lowStock;
  final int tipusCount;

  const _RecursosHeaderCard({
    required this.total,
    required this.visible,
    required this.lowStock,
    required this.tipusCount,
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.warehouse_outlined, color: scheme.primary, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catàleg de recursos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consulta i gestiona els materials, eines i recursos disponibles per a les obres.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderTag(icon: Icons.inventory_2_outlined, label: '$total recursos'),
                    _HeaderTag(icon: Icons.filter_alt_outlined, label: '$visible visibles', accent: scheme.tertiary),
                    _HeaderTag(icon: Icons.warning_amber_rounded, label: '$lowStock baix stock', accent: Colors.orange),
                    _HeaderTag(icon: Icons.category_outlined, label: '$tipusCount tipus', accent: scheme.secondary),
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

class _HeaderTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _HeaderTag({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecursosFilterBar extends StatelessWidget {
  final List<String> tipusOptions;
  final String? selectedTipus;
  final String selectedSort;
  final ValueChanged<String?> onTipusChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback? onClearFilters;

  const _RecursosFilterBar({
    required this.tipusOptions,
    required this.selectedTipus,
    required this.selectedSort,
    required this.onTipusChanged,
    required this.onSortChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filtres i ordenació',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (onClearFilters != null)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Neteja'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String?>(
                  value: selectedTipus,
                  decoration: _smallInputDecoration(context, 'Tipus'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tots'),
                    ),
                    ...tipusOptions.map(
                      (tipus) => DropdownMenuItem<String?>(
                        value: tipus,
                        child: Text(tipus),
                      ),
                    ),
                  ],
                  onChanged: onTipusChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: selectedSort,
                  decoration: _smallInputDecoration(context, 'Ordena per'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: _RecursSortValues.nomAsc,
                      child: Text('Nom A-Z'),
                    ),
                    DropdownMenuItem<String>(
                      value: _RecursSortValues.nomDesc,
                      child: Text('Nom Z-A'),
                    ),
                    DropdownMenuItem<String>(
                      value: _RecursSortValues.stockAsc,
                      child: Text('Stock baix primer'),
                    ),
                    DropdownMenuItem<String>(
                      value: _RecursSortValues.stockDesc,
                      child: Text('Stock alt primer'),
                    ),
                    DropdownMenuItem<String>(
                      value: _RecursSortValues.tipusAsc,
                      child: Text('Tipus'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecursCard extends StatelessWidget {
  final RecursOption recurs;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RecursCard({
    required this.recurs,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentForType(context, recurs.tipus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withOpacity(0.26), width: 1.2),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconForType(recurs.tipus), color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurs.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RecursPill(label: 'Stock', value: _stockLabel(recurs)),
                        _RecursPill(label: 'Unitat', value: recurs.unitat.isEmpty ? '-' : recurs.unitat),
                        if (recurs.tipus?.trim().isNotEmpty == true)
                          _RecursPill(label: 'Tipus', value: recurs.tipus!.trim()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
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

class _RecursPill extends StatelessWidget {
  final String label;
  final String value;

  const _RecursPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}

InputDecoration _smallInputDecoration(BuildContext context, String label) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: scheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );
}

String _stockLabel(RecursOption recurs) {
  final stock = recurs.stock;
  if (stock == null) return '-';
  final text = stock == stock.roundToDouble() ? stock.toInt().toString() : stock.toStringAsFixed(2);
  return '$text ${recurs.unitat}'.trim();
}

IconData _iconForType(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'material':
      return Icons.layers_outlined;
    case 'maquinaria':
    case 'maquinària':
      return Icons.agriculture_outlined;
    case 'personal':
      return Icons.people_alt_outlined;
    default:
      return Icons.category_outlined;
  }
}

Color _accentForType(BuildContext context, String? type) {
  final scheme = Theme.of(context).colorScheme;
  switch ((type ?? '').toLowerCase()) {
    case 'material':
      return scheme.primary;
    case 'maquinaria':
    case 'maquinària':
      return Colors.orange;
    case 'personal':
      return scheme.tertiary;
    default:
      return scheme.secondary;
  }
}
