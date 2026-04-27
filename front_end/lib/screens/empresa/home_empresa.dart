//FET

import 'package:flutter/material.dart';
import 'package:front_end/dialogs/notifications_dropdown.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/screens/obra_screens/obra_profile_screen.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/widgets/empresa_widgets.dart';
import 'package:front_end/dialogs/notifications_modal.dart';

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
  static List<Map<String, dynamic>> _obres = [];
  bool _loading = true;
  String _statusFilter = 'Totes';
  final ObraService _obraService = ObraService(baseUrl: _baseUrl);
  
  // Notificaciones de ejemplo
  late List<NotificationItem> _notifications;
  @override
  void initState() {
    super.initState();
    _loadObres();
    _initializeNotifications();
  }
  
  void _initializeNotifications() {
    _notifications = [
      NotificationItem(
        id: 1,
        title: 'Incidència prioritària',
        message: 'Nova incidència crítica a l\'obra Edifici Centre',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: NotificationType.incidencia,
      ),
      NotificationItem(
        id: 2,
        title: 'Tasca assignada',
        message: 'Se t\'ha assignat la tasca: Revisió de seguretat',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.tasca,
      ),
      NotificationItem(
        id: 3,
        title: 'Obra finalitzada',
        message: 'L\'obra Centre Comercial ha estat finalitzada',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.obra,
        isRead: true,
      ),
      NotificationItem(
        id: 4,
        title: 'Nou treballador',
        message: 'Joan García s\'ha afegit al teu equip',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: NotificationType.treballador,
        isRead: true,
      ),
    ];
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => _showNotificationsDropdown(),
              ),
              // Badge de notificaciones no leídas
              if (_notifications.any((n) => !n.isRead))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _notifications.where((n) => !n.isRead).length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          const EmpresaProfileDropdown(),
          const SizedBox(width: 12),
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
    return Row(
      children: [
        const Text('Filtra per estat:'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: scheme.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['Totes', 'Res Firmat', 'En execució', 'Finalitzada']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _statusFilter = v ?? 'Totes'),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final items = _statusFilter == 'Totes'
        ? _obres
        : _obres.where((o) {
            final info = (o['obra_info'] as Map<String, dynamic>?) ?? {};
            return info['estat'] == _statusFilter;
          }).toList();

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

  //───────────────────── Navegació ──────────────────────
  void _openObra(Map<String, dynamic> obra) async {
    print('Obra seleccionada: $obra');
    print(obra['ObraId']);
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ObraProfileScreen(obraId: obra['id_obra'], baseUrl: _baseUrl)),
    );
    if (updated == true) _loadObres();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showNotificationsDropdown() {
    showNotificationsDropdown(
      context,
      notifications: _notifications,
      onMarkAllAsRead: () {
        setState(() {
          for (var notification in _notifications) {
            notification.isRead = true;
          }
        });
        _snack('Totes les notificacions marcades com a llegides');
      },
    );
  }
}

//──────────────────────── ESTADÍSTIQUES ────────────────────────
class _StatsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> obres;
  const _StatsHeader({required this.obres});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exec = obres.where((o) {
      final info = (o['obra_info'] as Map<String, dynamic>?) ?? {};
      return info['estat'] == 'En execució';
    }).length;

    final fin = obres.where((o) {
      final info = (o['obra_info'] as Map<String, dynamic>?) ?? {};
      return info['estat'] == 'Finalitzada';
    }).length;
    Card _stat(String label, int value, IconData icon, Color color) {
      return Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 100,
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.onPrimary),
              const SizedBox(height: 6),
              Text(value.toString(),
                  style: TextStyle(
                      color: scheme.onPrimary, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      color: scheme.onPrimary.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat('Totals', obres.length, Icons.business, scheme.primary),
        _stat('Execució', exec, Icons.construction, Colors.orange),
        _stat('Finalitz.', fin, Icons.check_circle, Colors.green),
      ],
    );
  }
}

//──────────────────────── TARGETA OBRA ─────────────────────────
class _ObraCard extends StatelessWidget {
  final Map<String, dynamic> obra;
  final void Function(Map<String, dynamic>) onTap;
  const _ObraCard({required this.obra, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = (obra['obra_info'] as Map<String, dynamic>?) ?? {};
    final estat = '${info['estat'] ?? 'Sense estat'}';

    Color _color(String s) {
      switch (s) {
        case ('En curs' || 'EN CURS'):
          return Colors.orange;
        case 'Finalitzada' || 'FINALITZADA':
          return Colors.green;
        case 'Res Firmat' || 'RES FIRMAT':
          return Colors.grey;
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
                      info['nom'] ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        _ubicacioSimple(info['ubicacio_info']['adreca'] +
                            ", " +
                            info['ubicacio_info']['ciutat']), //abans ubicacio
                        style: TextStyle(color: scheme.onSurfaceVariant)),
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

  String _ubicacioSimple(dynamic v) {
    if (v is String) return v.trim().isEmpty ? 'NO string' : v;
    return v.toString();
  }
}
