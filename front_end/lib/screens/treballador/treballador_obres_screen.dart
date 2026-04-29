
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorObresScreen extends StatefulWidget {
  const TreballadorObresScreen({super.key});

  @override
  State<TreballadorObresScreen> createState() => _TreballadorObresScreenState();
}

class _TreballadorObresScreenState extends State<TreballadorObresScreen> {
  late final TreballadorService _service;
  late Future<List<Map<String, dynamic>>> _future;
  String _filterEstat = 'Totes';

  static const _estats = ['Totes', 'Res Firmat', 'En execució', 'Finalitzada'];

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _apiBase);
    _future = _service.fetchMyObresParticipades();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchMyObresParticipades());
    await _future;
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> obres) {
    if (_filterEstat == 'Totes') return obres;
    return obres.where((o) => (o['estat'] ?? '') == _filterEstat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Les meves obres'),
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
            return const AppLoadingIndicator(message: 'Carregant obres...');
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
              _EstatFilterRow(
                selected: _filterEstat,
                options: _estats,
                onChanged: (v) => setState(() => _filterEstat = v),
                scheme: scheme,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: filtered.isEmpty
                      ? AppEmptyState(
                          icon: Icons.location_city_outlined,
                          title: all.isEmpty
                              ? 'Cap obra assignada'
                              : 'Sense resultats',
                          message: all.isEmpty
                              ? 'Encara no participes en cap obra.'
                              : 'No hi ha obres amb l\'estat seleccionat.',
                        )
                      : _ObraList(obres: filtered),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── FILTRE ─────────────────────────

class _EstatFilterRow extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final ColorScheme scheme;

  const _EstatFilterRow({
    required this.selected,
    required this.options,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: options.map((opt) {
            final isSelected = selected == opt;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(opt),
                selected: isSelected,
                onSelected: (_) => onChanged(opt),
                selectedColor: scheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color:
                      isSelected ? scheme.primary : scheme.outlineVariant,
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

class _ObraList extends StatelessWidget {
  final List<Map<String, dynamic>> obres;
  const _ObraList({required this.obres});

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
      itemCount: obres.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _ObraCard(obra: obres[i]),
    );
  }
}

// ───────────────────────── TARGETA OBRA ─────────────────────────

class _ObraCard extends StatelessWidget {
  final Map<String, dynamic> obra;
  const _ObraCard({required this.obra});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estat = '${obra['estat'] ?? 'Sense estat'}';
    final nom = '${obra['nom'] ?? '—'}';
    final dataInici = obra['data_inici'] != null
        ? _formatDate(obra['data_inici'].toString())
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.house_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (dataInici != null)
                    Text(
                      'Inici: $dataInici',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  _EstatChip(estat: estat, scheme: scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return date;
    }
  }
}

class _EstatChip extends StatelessWidget {
  final String estat;
  final ColorScheme scheme;
  const _EstatChip({required this.estat, required this.scheme});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (estat) {
      case 'En execució':
        color = Colors.orange;
        break;
      case 'Finalitzada':
        color = Colors.green;
        break;
      case 'Res Firmat':
        color = Colors.grey;
        break;
      default:
        color = scheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estat,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
