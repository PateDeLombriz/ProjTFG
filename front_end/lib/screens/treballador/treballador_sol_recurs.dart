import 'package:flutter/material.dart';

import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/shared/widgets/app_primary_button.dart';

class TreballadorSolRecursForm extends StatefulWidget {
  final int? obraId;
  final String? nomObra;

  const TreballadorSolRecursForm({
    super.key,
    this.obraId,
    this.nomObra,
  });

  @override
  State<TreballadorSolRecursForm> createState() =>
      _TreballadorSolRecursFormState();
}

class _TreballadorSolRecursFormState extends State<TreballadorSolRecursForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantitatCtrl = TextEditingController();
  final _comentariCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  late final TreballadorService _service;
  late Future<_SolRecursFormData> _future;

  int? _obraSeleccionada;
  String? _nomObraSeleccionada;
  int? _recursSeleccionat;
  DateTime? _dataNecessitat;

  String _resourceQuery = '';
  String _resourceTypeFilter = 'tots';

  bool _submitting = false;
  String? _error;

  bool get _hasFixedObra => widget.obraId != null;

  @override
  void initState() {
    super.initState();

    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _obraSeleccionada = widget.obraId;
    _nomObraSeleccionada = widget.nomObra;
    _future = _load();
  }

  @override
  void dispose() {
    _quantitatCtrl.dispose();
    _comentariCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<_SolRecursFormData> _load() async {
    final results = await Future.wait<dynamic>([
      _service.fetchCatalogRecursos(),
      if (!_hasFixedObra) _service.fetchMyObresParticipades(),
    ]);

    return _SolRecursFormData(
      recursos: _asMapList(results[0]),
      obres: _hasFixedObra ? const [] : _asMapList(results[1]),
    );
  }

  Future<void> _reload() async {
    FocusScope.of(context).unfocus();

    final nextFuture = _load();

    setState(() {
      _future = nextFuture;
      _error = null;
    });

    await nextFuture;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNecessitat ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dataNecessitat = picked;
      });
    }
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_obraSeleccionada == null) {
      setState(() {
        _error = 'Selecciona una obra.';
      });
      return;
    }

    if (_recursSeleccionat == null) {
      setState(() {
        _error = 'Selecciona un recurs.';
      });
      return;
    }

    if (_dataNecessitat == null) {
      setState(() {
        _error = 'Selecciona la data de necessitat.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _service.createMySolRecurs({
        'id_obra': _obraSeleccionada,
        'id_recurs': _recursSeleccionat,
        'quantitat': int.parse(_quantitatCtrl.text.trim()),
        'data_necessitat': _dataNecessitat!.toIso8601String().substring(0, 10),
        if (_comentariCtrl.text.trim().isNotEmpty)
          'comentari': _comentariCtrl.text.trim(),
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on TreballadorServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredResources(
    List<Map<String, dynamic>> recursos,
  ) {
    final query = _resourceQuery.trim().toLowerCase();

    return recursos.where((recurs) {
      final nom = _asString(recurs['nom'])?.toLowerCase() ?? '';
      final tipus = _asString(recurs['tipus_recurs'])?.toLowerCase() ?? '';
      final unitats = _asString(recurs['unitats_mesura'])?.toLowerCase() ?? '';

      final normalizedType = _normalizeValue(tipus);

      final matchesType = _resourceTypeFilter == 'tots' ||
          normalizedType == _resourceTypeFilter;

      final matchesQuery = query.isEmpty ||
          nom.contains(query) ||
          tipus.contains(query) ||
          unitats.contains(query);

      return matchesType && matchesQuery;
    }).toList();
  }

  List<(String, String)> _buildResourceTypeOptions(
    List<Map<String, dynamic>> recursos,
  ) {
    final values = <String, String>{};

    for (final recurs in recursos) {
      final raw = _asString(recurs['tipus_recurs']);
      final normalized = _normalizeValue(raw);

      if (normalized == null) continue;

      values[normalized] = _prettyLabel(raw ?? normalized);
    }

    final sorted = values.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return [
      const ('tots', 'Tots'),
      ...sorted.map((entry) => (entry.key, entry.value)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Sol·licitar recurs'),
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<_SolRecursFormData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(
              message: 'Carregant recursos...',
            );
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
              message: 'No s’han rebut dades per crear la sol·licitud.',
              onRetry: _reload,
            );
          }

          final filteredResources = _filteredResources(data.recursos);
          final typeOptions = _buildResourceTypeOptions(data.recursos);

          return Form(
            key: _formKey,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              children: [
                _HeaderCard(
                  nomObra: _nomObraSeleccionada,
                  hasFixedObra: _hasFixedObra,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!_hasFixedObra) ...[
                  _ObraSelectorCard(
                    obres: data.obres,
                    selectedObraId: _obraSeleccionada,
                    onChanged: (obra) {
                      setState(() {
                        _obraSeleccionada = _asIntOrNull(obra?['id']);
                        _nomObraSeleccionada =
                            _asString(obra?['nom']) ?? 'Obra seleccionada';
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (data.recursos.isEmpty)
                  const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Sense recursos disponibles',
                    message:
                        'No hi ha recursos disponibles per crear una sol·licitud.',
                  )
                else ...[
                  _ResourceSelectorCard(
                    recursos: filteredResources,
                    allResourcesCount: data.recursos.length,
                    selectedRecursId: _recursSeleccionat,
                    searchController: _searchCtrl,
                    selectedType: _resourceTypeFilter,
                    typeOptions: typeOptions,
                    onSearchChanged: (value) {
                      setState(() {
                        _resourceQuery = value;
                      });
                    },
                    onTypeChanged: (value) {
                      setState(() {
                        _resourceTypeFilter = value;
                      });
                    },
                    onSelected: (recurs) {
                      setState(() {
                        _recursSeleccionat = _asIntOrNull(recurs['id']);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RequestDetailsCard(
                    quantitatCtrl: _quantitatCtrl,
                    dataNecessitat: _dataNecessitat,
                    onPickDate: _pickDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ComentariCard(controller: _comentariCtrl),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: 'Enviar sol·licitud',
                    icon: Icons.send_rounded,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _enviar,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel·la'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SolRecursFormData {
  final List<Map<String, dynamic>> recursos;
  final List<Map<String, dynamic>> obres;

  const _SolRecursFormData({
    required this.recursos,
    required this.obres,
  });
}

class _HeaderCard extends StatelessWidget {
  final String? nomObra;
  final bool hasFixedObra;

  const _HeaderCard({
    required this.nomObra,
    required this.hasFixedObra,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            Icons.inventory_2_outlined,
            color: scheme.onPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sol·licitud de recurs',
            style: AppTextStyles.headlineMedium.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              height: 1.10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasFixedObra
                ? 'Demana material o eines per a aquesta obra.'
                : 'Selecciona una obra i indica quin recurs necessites.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onPrimary.withOpacity(0.80),
              height: 1.35,
            ),
          ),
          if (nomObra != null && nomObra!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _HeaderPill(
              icon: Icons.apartment_outlined,
              label: nomObra!,
            ),
          ],
        ],
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
            color: scheme.onPrimary.withOpacity(0.88),
            size: 15,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onPrimary.withOpacity(0.90),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObraSelectorCard extends StatelessWidget {
  final List<Map<String, dynamic>> obres;
  final int? selectedObraId;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const _ObraSelectorCard({
    required this.obres,
    required this.selectedObraId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.apartment_outlined,
            title: 'Obra',
            subtitle: 'Selecciona on necessites aquest recurs.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (obres.isEmpty)
            _SoftNotice(
              icon: Icons.info_outline_rounded,
              text:
                  'No hi ha obres disponibles per crear una sol·licitud de recurs.',
              color: scheme.error,
            )
          else
            DropdownButtonFormField<int>(
              value: selectedObraId,
              isExpanded: true,
              decoration: _fieldDecoration(
                context,
                hintText: 'Selecciona una obra',
                icon: Icons.location_city_outlined,
              ),
              items: obres.map((obra) {
                final id = _asIntOrNull(obra['id']);
                final nom = _asString(obra['nom']) ?? 'Obra $id';

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (id) {
                final obra = obres.where((item) {
                  return _asIntOrNull(item['id']) == id;
                }).firstOrNull;

                onChanged(obra);
              },
              validator: (value) {
                if (value == null) return 'Selecciona una obra';
                return null;
              },
            ),
        ],
      ),
    );
  }
}

class _ResourceSelectorCard extends StatelessWidget {
  final List<Map<String, dynamic>> recursos;
  final int allResourcesCount;
  final int? selectedRecursId;
  final TextEditingController searchController;
  final String selectedType;
  final List<(String, String)> typeOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _ResourceSelectorCard({
    required this.recursos,
    required this.allResourcesCount,
    required this.selectedRecursId,
    required this.searchController,
    required this.selectedType,
    required this.typeOptions,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.inventory_2_outlined,
            title: 'Recurs',
            subtitle: '$allResourcesCount recursos disponibles al catàleg.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: _fieldDecoration(
              context,
              hintText: 'Cerca per nom, tipus o unitat',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterGroup(
            title: 'Tipus',
            selected: selectedType,
            options: typeOptions,
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if (recursos.isEmpty)
            const _SoftNotice(
              icon: Icons.filter_list_off_rounded,
              text: 'No hi ha recursos que coincideixin amb els filtres.',
            )
          else
            _ScrollableResourceSelector(
              recursos: recursos,
              selectedRecursId: selectedRecursId,
              onSelected: onSelected,
            ),
          if (selectedRecursId == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Selecciona un recurs per continuar.',
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _ScrollableResourceSelector extends StatelessWidget {
  final List<Map<String, dynamic>> recursos;
  final int? selectedRecursId;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _ScrollableResourceSelector({
    required this.recursos,
    required this.selectedRecursId,
    required this.onSelected,
  });

  static const double _itemHeight = 74;
  static const double _maxVisibleItems = 5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final visibleItems = recursos.length > _maxVisibleItems
        ? _maxVisibleItems
        : recursos.length.toDouble();

    final maxHeight =
        (visibleItems * _itemHeight) + ((visibleItems - 1) * AppSpacing.sm);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.65),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Scrollbar(
          thumbVisibility: recursos.length > _maxVisibleItems,
          child: ListView.separated(
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.xs),
            itemCount: recursos.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final recurs = recursos[index];

              return _ResourceOptionCard(
                recurs: recurs,
                selected: selectedRecursId == _asIntOrNull(recurs['id']),
                onTap: () => onSelected(recurs),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _ResourceOptionCard extends StatelessWidget {
  final Map<String, dynamic> recurs;
  final bool selected;
  final VoidCallback onTap;

  const _ResourceOptionCard({
    required this.recurs,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = _asIntOrNull(recurs['id']);
    final nom = _asString(recurs['nom']) ?? 'Recurs $id';
    final unitats = _asString(recurs['unitats_mesura']);
    final tipus = _asString(recurs['tipus_recurs']);
    final stock = _formatStock(recurs['quantitat_stock'], unitats);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer.withOpacity(0.55)
              : scheme.surfaceContainerHighest.withOpacity(0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: scheme.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (tipus != null) _prettyLabel(tipus),
                          if (unitats != null) unitats,
                          if (stock != '—') 'Stock: $stock',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestDetailsCard extends StatelessWidget {
  final TextEditingController quantitatCtrl;
  final DateTime? dataNecessitat;
  final VoidCallback onPickDate;

  const _RequestDetailsCard({
    required this.quantitatCtrl,
    required this.dataNecessitat,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.edit_note_rounded,
            title: 'Detalls de la sol·licitud',
            subtitle: 'Indica la quantitat i quan ho necessites.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: quantitatCtrl,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              context,
              hintText: 'Número d’unitats',
              icon: Icons.numbers_rounded,
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              final parsed = int.tryParse(text);

              if (text.isEmpty) return 'La quantitat és obligatòria';
              if (parsed == null || parsed <= 0) {
                return 'Introdueix un número enter positiu';
              }

              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data de necessitat',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dataNecessitat == null
                              ? 'Selecciona una data'
                              : _formatDate(dataNecessitat!),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: dataNecessitat == null
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComentariCard extends StatelessWidget {
  final TextEditingController controller;

  const _ComentariCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.notes_outlined,
            title: 'Comentari',
            subtitle: 'Afegeix context si és necessari.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: _fieldDecoration(
              context,
              hintText: 'Motiu o context de la sol·licitud...',
              icon: Icons.edit_outlined,
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
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _SoftNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _SoftNotice({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.70),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: scheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String hintText,
  required IconData icon,
}) {
  final scheme = Theme.of(context).colorScheme;

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withOpacity(0.35),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.primary, width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.error, width: 1.3),
    ),
  );
}

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

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _normalizeValue(String? value) {
  if (value == null) return null;

  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  return normalized.replaceAll(' ', '_').replaceAll('-', '_');
}

String _prettyLabel(String value) {
  final text =
      value.trim().replaceAll('_', ' ').replaceAll('-', ' ').toLowerCase();

  if (text.isEmpty) return '—';

  return text.split(RegExp(r'\s+')).map((part) {
    if (part.isEmpty) return part;
    return '${part[0].toUpperCase()}${part.substring(1)}';
  }).join(' ');
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}

String _formatStock(dynamic value, String? unitats) {
  if (value == null) return '—';

  final text = value.toString().trim();
  if (text.isEmpty) return '—';

  if (unitats == null || unitats.trim().isEmpty) return text;

  return '$text $unitats';
}
