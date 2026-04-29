
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/empresa/tasca_screens/tasca_detail_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

class TreballadorTasquesScreen extends StatefulWidget {
  const TreballadorTasquesScreen({super.key});

  @override
  State<TreballadorTasquesScreen> createState() =>
      _TreballadorTasquesScreenState();
}

class _TreballadorTasquesScreenState
    extends State<TreballadorTasquesScreen> {
  late final TreballadorService _service;
  late Future<List<Map<String, dynamic>>> _future;

  String _filterEstat = 'tots';

  static const _estats = [
    ('tots', 'Totes'),
    ('pendent', 'Pendents'),
    ('en_curs', 'En curs'),
    ('finalitzada_pendent_revisio', 'Pend. revisió'),
    ('finalitzada', 'Finalitzades'),
  ];

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _apiBase);
    _future = _service.fetchMyTasques();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchMyTasques();
    });
    await _future;
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> tasques,
  ) {
    if (_filterEstat == 'tots') return tasques;
    return tasques
        .where((t) => (t['estat'] ?? '') == _filterEstat)
        .toList();
  }

  void _openTasca(BuildContext context, Map<String, dynamic> tasca) {
    final id = tasca['id'];
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TascaDetailScreen(
          tascaId: id as int,
          capabilities: const TascaProfileCapabilities.treballador(),
        ),
      ),
    ).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    // CANVI 1: AppBar sense colors explícits → usa el tema per defecte (= empresa)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Les meves tasques'),
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant tasques...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);

          return Column(
            children: [
              _FilterBar(
                selected: _filterEstat,
                options: _estats,
                onChanged: (value) {
                  setState(() {
                    _filterEstat = value;
                  });
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: filtered.isEmpty
                      ? _emptyState(all.isEmpty)
                      : _TaskList(
                          tasques: filtered,
                          onTap: (t) => _openTasca(context, t),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(bool noData) {
    if (noData) {
      return const AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Cap tasca assignada',
        message: 'Encara no tens cap tasca assignada.',
      );
    }
    return const AppEmptyState(
      icon: Icons.filter_list_off_rounded,
      title: 'Sense resultats',
      message: 'No hi ha tasques amb l\'estat seleccionat.',
    );
  }
}

// ───────────────────────── FILTRE ─────────────────────────

class _FilterBar extends StatelessWidget {
  final String selected;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // CANVI 2: fons clar en lloc de blau fosc
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.xs,
          AppSpacing.screenHorizontal,
          AppSpacing.xs,
        ),
        child: Row(
          children: options.map((opt) {
            final (key, label) = opt;
            final isSelected = selected == key;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => onChanged(key),
                selectedColor: scheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ───────────────────────── LLISTAT ─────────────────────────

class _TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasques;
  final void Function(Map<String, dynamic>) onTap;

  const _TaskList({required this.tasques, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.xxxl,
      ),
      itemCount: tasques.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      // CANVI 3: passa onTap per navegar al detall
      itemBuilder: (context, index) => TascaWorkerCard(
        tasca: tasques[index],
        onTap: () => onTap(tasques[index]),
      ),
    );
  }
}
