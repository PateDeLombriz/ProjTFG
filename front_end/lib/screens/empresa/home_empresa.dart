//FET

import 'package:flutter/material.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/screens/empresa/obra_screens/obra_profile_screen.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/widgets/empresa_widgets.dart';
import 'package:front_end/shared/widgets/app_notification_bell.dart';

/// Pantalla principal per a empreses amb llistat d'obres, estadístiques i filtres.
/// Estètica i UX alineades amb la resta de pantalles (bordes arrodonits, colors de tema,
/// validacions, RefreshIndicator, targetes riques i chips d'estat).
class HomeEmpresa extends StatefulWidget {
  const HomeEmpresa({super.key});

  @override
  State<HomeEmpresa> createState() => _HomeEmpresaState();
}

class _HomeEmpresaState extends State<HomeEmpresa> {
  static final _baseUrl = ApiConstants.baseUrl;
  static const _allFilter = 'Totes';
  static const _sortNameAsc = 'Nom A-Z';
  static const _sortNameDesc = 'Nom Z-A';
  static const _sortCityAsc = 'Ciutat A-Z';
  static const _sortStatus = 'Estat';
  static const _sortOptions = <String>[
    _sortNameAsc,
    _sortNameDesc,
    _sortCityAsc,
    _sortStatus,
  ];

  static List<Map<String, dynamic>> _obres = [];
  bool _loading = true;
  String _statusFilter = _allFilter;
  String _cityFilter = _allFilter;
  String _sortOption = _sortNameAsc;
  final ObraService _obraService = ObraService(baseUrl: _baseUrl);

  @override
  void initState() {
    super.initState();
    _loadObres();
  }

  Future<void> _loadObres() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final obres = await _obraService.fetchMyEmpresaObres();

      if (!mounted) return;
      setState(() {
        _obres = obres;
        _loading = false;
      });
    } on ObraServiceException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Error al carregar les obres: $e');
    }
  }

  //──────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestió d\'Obres'),
        actions: const [
          AppNotificationBell(),
          SizedBox(width: 4),
          EmpresaProfileDropdown(),
          SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsHeader(obres: _obres), // cuadrats amb informacoi estadstiques
            const SizedBox(height: 20), //Eslai entre estadstiques i filtres
            _filterRow(
                scheme), //Aixo es el row de filtres, on pots seleccionar per estat de l'obra
            const SizedBox(
                height:
                    12), //Aixo es el eslai entre els filtres i el llistat d'obres
            Expanded(
                child:
                    _buildList()), //Aixo es el llistat d'obres, que es refresca cada cop que entres a la pantalla o fas pull to refresh
          ],
        ),
      ),
    );
  }

  //───────────────────── Widgets auxiliars ──────────────────────
  Widget _filterRow(ColorScheme scheme) {
    final statusOptions = _buildOptions(_obres.map(_obraEstat));
    final cityOptions = _buildOptions(_obres.map(_obraCiutat));

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final fieldWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _dropdownField(
                scheme: scheme,
                label: 'Estat',
                icon: Icons.flag_rounded,
                value: statusOptions.contains(_statusFilter)
                    ? _statusFilter
                    : _allFilter,
                options: statusOptions,
                onChanged: (v) => setState(() => _statusFilter = v ?? _allFilter),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _dropdownField(
                scheme: scheme,
                label: 'Ciutat',
                icon: Icons.location_city_rounded,
                value: cityOptions.contains(_cityFilter) ? _cityFilter : _allFilter,
                options: cityOptions,
                onChanged: (v) => setState(() => _cityFilter = v ?? _allFilter),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _dropdownField(
                scheme: scheme,
                label: 'Ordena per',
                icon: Icons.sort_rounded,
                value: _sortOption,
                options: _sortOptions,
                onChanged: (v) => setState(() => _sortOption = v ?? _sortNameAsc),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dropdownField({
    required ColorScheme scheme,
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : options.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildList() {
    if (_loading) return const AppLoadingIndicator();

    final items = _filteredAndSortedObres();

    if (items.isEmpty) {
      return const Center(child: Text('No hi ha obres'));
    }

    return RefreshIndicator(
      onRefresh: _loadObres,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _ObraCard(obra: items[i], onTap: _openObra),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredAndSortedObres() {
    final items = _obres.where((obra) {
      final matchesStatus = _statusFilter == _allFilter ||
          _sameFilterValue(_obraEstat(obra), _statusFilter);
      final matchesCity = _cityFilter == _allFilter ||
          _sameFilterValue(_obraCiutat(obra), _cityFilter);
      return matchesStatus && matchesCity;
    }).toList();

    items.sort((a, b) {
      switch (_sortOption) {
        case _sortNameDesc:
          return _compareText(_obraNom(b), _obraNom(a));
        case _sortCityAsc:
          return _compareText(_obraCiutat(a), _obraCiutat(b));
        case _sortStatus:
          final byStatus = _statusRank(_obraEstat(a)).compareTo(_statusRank(_obraEstat(b)));
          return byStatus == 0 ? _compareText(_obraNom(a), _obraNom(b)) : byStatus;
        case _sortNameAsc:
        default:
          return _compareText(_obraNom(a), _obraNom(b));
      }
    });

    return items;
  }

  List<String> _buildOptions(Iterable<String> rawValues) {
    final values = rawValues
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != '—')
        .toSet()
        .toList()
      ..sort(_compareText);

    return [_allFilter, ...values];
  }

  bool _sameFilterValue(String a, String b) {
    return _normalizeText(a) == _normalizeText(b);
  }

  //───────────────────── Navegació ──────────────────────
  void _openObra(Map<String, dynamic> obra) async {
    
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ObraProfileScreen(
          obraId: obra['id_obra'],
          baseUrl: _baseUrl,
        ),
      ),
    );
    if (updated == true) _loadObres();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

//──────────────────────── ESTADÍSTIQUES ────────────────────────
class _StatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> obres;
  const _StatsHeader({required this.obres});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    int countByStatus(String status) {
      final normalizedStatus = _normalizeText(status);
      return obres
          .where((obra) => _normalizeText(_obraEstat(obra)) == normalizedStatus)
          .length;
    }

    final stats = [
      _ObraStat(
        label: 'Planificació',
        value: countByStatus('planificacio'),
        icon: Icons.event_note_rounded,
        color: Colors.blueGrey,
      ),
      _ObraStat(
        label: 'En curs',
        value: countByStatus('en curs'),
        icon: Icons.construction_rounded,
        color: Colors.green,
      ),
      _ObraStat(
        label: 'Aturada',
        value: countByStatus('aturada'),
        icon: Icons.pause_circle_filled_rounded,
        color: Colors.red,
      ),
      _ObraStat(
        label: 'Finalitzada',
        value: countByStatus('finalitzada'),
        icon: Icons.check_circle_rounded,
        color: Colors.orange,
      ),
    ];

    Widget statPill(_ObraStat stat) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: stat.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: stat.color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, size: 16, color: stat.color),
            const SizedBox(width: 6),
            Text(
              stat.value.toString(),
              style: TextStyle(
                color: stat.color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              stat.label,
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;

            final totalWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    size: 19,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obres.length.toString(),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Obres totals',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            );

            final statsWidget = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              children: stats.map(statPill).toList(),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  totalWidget,
                  const SizedBox(height: 10),
                  statsWidget,
                ],
              );
            }

            return Row(
              children: [
                totalWidget,
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 34,
                  color: scheme.outlineVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: statsWidget,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ObraStat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _ObraStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

//──────────────────────── TARGETA OBRA ─────────────────────────
class _ObraCard extends StatelessWidget {
  final Map<String, dynamic> obra;
  final void Function(Map<String, dynamic>) onTap;
  const _ObraCard({required this.obra, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nom = _obraNom(obra);
    final estat = _obraEstat(obra);
    final ubicacio = _obraUbicacioLabel(obra);

    Color _color(String s) {
      switch (_normalizeText(s)) {
        case 'en curs':
        return Colors.green;  
        case 'finalitzada':
          return Colors.orange;
        case 'planificacio':
          return Colors.grey;
        case 'aturada':
          return Colors.red;
        default:
          return scheme.primary;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(obra),
        child: Padding(
          //eL PADDING DE LA TARGETA, QUE ES EL QUE FA QUE EL CONTINGUT NO TOQUI LES BORDES I QUEDI MÉS AGRADABLE A LA VISTA
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  //Aixo es la caixa de l'icona, que té un color de fons i una icona dins
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.house_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ubicacio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _statusChip(estat, _color(estat)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

Map<String, dynamic> _obraInfo(Map<String, dynamic> obra) {
  final raw = obra['obra_info'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}

Map<String, dynamic> _obraUbicacioInfo(Map<String, dynamic> obra) {
  final raw = _obraInfo(obra)['ubicacio_info'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}

String _obraNom(Map<String, dynamic> obra) {
  return _cleanText(_obraInfo(obra)['nom'], fallback: '—');
}

String _obraEstat(Map<String, dynamic> obra) {
  return _cleanText(_obraInfo(obra)['estat'], fallback: 'Sense estat');
}

String _obraCiutat(Map<String, dynamic> obra) {
  return _cleanText(_obraUbicacioInfo(obra)['ciutat']);
}

String _obraAdreca(Map<String, dynamic> obra) {
  return _cleanText(_obraUbicacioInfo(obra)['adreca']);
}

String _obraUbicacioLabel(Map<String, dynamic> obra) {
  final adreca = _obraAdreca(obra);
  final ciutat = _obraCiutat(obra);

  if (adreca.isNotEmpty && ciutat.isNotEmpty) return '$adreca, $ciutat';
  if (adreca.isNotEmpty) return adreca;
  if (ciutat.isNotEmpty) return ciutat;
  return 'Sense ubicació';
}

String _cleanText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _normalizeText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('á', 'a')
      .replaceAll('è', 'e')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ò', 'o')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');
}

int _compareText(String a, String b) {
  return _normalizeText(a).compareTo(_normalizeText(b));
}

int _statusRank(String value) {
  switch (_normalizeText(value)) {
    case 'planificacio':
      return 0;
    case 'en curs':
      return 1;
    case 'aturada':
      return 2;
    case 'finalitzada':
      return 3;
    default:
      return 99;
  }
}
