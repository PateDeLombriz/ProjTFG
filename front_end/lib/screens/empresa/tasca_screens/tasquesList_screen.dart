import 'package:flutter/material.dart';
import 'package:front_end/screens/empresa/tasca_screens/tasca_detail_screen.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/services/tasques_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/widgets/tasca_widgets.dart';

/// Pantalla de gestió de tasques.
/// La UI reutilitzable viu a `tasca_widgets.dart`.
/// La lògica HTTP viu a `TascaService`.
class TasquesScreen extends StatefulWidget {
  const TasquesScreen({super.key});

  @override
  State<TasquesScreen> createState() => _TasquesScreenState();
}

class _TasquesScreenState extends State<TasquesScreen> {
  late final TascaService _service;

  final List<Map<String, dynamic>> _tasques = [];

  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service = TascaService(baseUrl: ApiConstants.baseUrl);
    _fetchTasques();
  }

  Future<void> _fetchTasques() async {
    setState(() => _loading = true);

    try {
      final data = await _service.fetchTasques();

      if (!mounted) return;

      setState(() {
        _tasques
          ..clear()
          ..addAll(data);
      });
    } catch (e) {
      if (mounted) {
        _snack('Error al carregar tasques: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteTasca(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tasca'),
        content: const Text('Vols eliminar aquesta tasca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·la'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteTasca(id);
      await _fetchTasques();

      if (mounted) {
        _snack('Tasca eliminada', success: true);
      }
    } catch (e) {
      if (mounted) {
        _snack('Error eliminant tasca: $e');
      }
    }
  }

  void _openTasca(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TascaDetailScreen(tascaId: id),
      ),
    );
  }

  void _editTasca(Map<String, dynamic> tasca) {
    Navigator.pushNamed(
      context,
      '/editTasca',
      arguments: tasca,
    ).then((result) {
      if (result == true) {
        _fetchTasques();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasques'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TascaStatsHeader(tasques: _tasques),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cerca per descripció...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.toLowerCase().trim();
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const AppLoadingIndicator();
    }

    final items = _query.isEmpty
        ? _tasques
        : _tasques.where((tasca) {
            return (tasca['descripcio'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_query);
          }).toList();

    if (items.isEmpty) {
      return const Center(
        child: Text('No hi ha tasques'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTasques,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final tasca = items[index];

          return TascaCard(
            tasca: tasca,
            onOpen: _openTasca,
            onEdit: _editTasca,
            onDelete: _deleteTasca,
          );
        },
      ),
    );
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }
}