import 'package:flutter/material.dart';

import 'package:front_end/screens/treballador/treballador_sol_recurs.dart';
import 'package:front_end/screens/treballador/treballador_profile_screen.dart';
import 'package:front_end/screens/treballador/registre_horari_screen.dart';
import 'package:front_end/screens/treballador/treballador_home_screen.dart';
import 'package:front_end/screens/treballador/treballador_incidencies_screen.dart';
import 'package:front_end/screens/treballador/treballador_obres_screen.dart';
import 'package:front_end/screens/treballador/treballador_sol_recurs_list_screen.dart';
import 'package:front_end/screens/treballador/treballador_tasques_screen.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/models/app_capabilities.dart';

class TreballadorMainScaffold extends StatefulWidget {
  const TreballadorMainScaffold({super.key});

  @override
  State<TreballadorMainScaffold> createState() =>
      _TreballadorMainScaffoldState();
}

class _TreballadorMainScaffoldState extends State<TreballadorMainScaffold> {
  static const int _homeIndex = 0;
  static const int _tasquesIndex = 1;
  static const int _obresIndex = 2;
  static const int _solRecursIndex = 3;
  static const int _perfilIndex = 4;

  int _currentIndex = _homeIndex;

  AppCapabilities _capabilities = const AppCapabilities.workerDefaults();

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final service = TreballadorService(baseUrl: ApiConstants.baseUrl);
      final permisos = await service.fetchMyPermisos();

      if (!mounted) return;

      setState(() {
        _capabilities = AppCapabilities.fromPermisos(permisos);
      });
    } catch (_) {
      // Manté AppCapabilities.workerDefaults() sense mostrar error.
      // La UI continua usable amb els permisos per defecte del treballador.
    }
  }

  void _goToTab(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _pages => [
        TreballadorHomeScreen(capabilities: _capabilities),
        TreballadorTasquesScreen(capabilities: _capabilities),
        TreballadorObresScreen(capabilities: _capabilities),
        TreballadorSolRecursListScreen(),
        const TreballadorProfileScreen(),
      ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Inici',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment_rounded),
      label: 'Tasques',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.location_city_outlined),
      activeIcon: Icon(Icons.location_city_rounded),
      label: 'Obres',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mark_email_read_outlined),
      activeIcon: Icon(Icons.mark_email_read),
      label: 'Sol·licituds Recurssos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: scheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BottomNavigationBar(
              items: _navItems,
              currentIndex: _currentIndex,
              onTap: _goToTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: scheme.surface,
              elevation: 0,
              selectedItemColor: scheme.primary,
              unselectedItemColor: scheme.onSurfaceVariant,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              showUnselectedLabels: true,
            ),
          ),
        ),
      ),
      floatingActionButton: _TreballadorFabMenu(
        onSelected: _handleFabAction,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _handleFabAction(_TreballadorFabAction action) async {
    switch (action) {
      case _TreballadorFabAction.registreHorari:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RegistreHorariScreen(),
          ),
        );
        break;

      case _TreballadorFabAction.incidencies:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TreballadorIncidenciesScreen(),
          ),
        );
        break;

      case _TreballadorFabAction.solRecurs:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TreballadorSolRecursForm(),
          ),
        );
        break;
      case _TreballadorFabAction.perfil:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TreballadorProfileScreen(),
          ),
        );
    }
  }
}

class _TreballadorFabMenu extends StatelessWidget {
  final ValueChanged<_TreballadorFabAction> onSelected;

  const _TreballadorFabMenu({
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      tooltip: 'Accions del treballador',
      onPressed: () async {
        final selected = await showMenu<_TreballadorFabAction>(
          context: context,
          position: const RelativeRect.fromLTRB(1000, 1000, 16, 100),
          surfaceTintColor: scheme.surfaceTint,
          items: [
            _menuItem(
              context,
              value: _TreballadorFabAction.registreHorari,
              icon: Icons.access_time_rounded,
              text: 'Fitxar entrada / sortida',
              description: 'Obrir el registre horari',
            ),
            _menuItem(
              context,
              value: _TreballadorFabAction.incidencies,
              icon: Icons.report_problem_outlined,
              text: 'Incidències',
              description: 'Consultar o revisar incidències',
            ),
            _menuItem(
              context,
              value: _TreballadorFabAction.solRecurs,
              icon: Icons.inventory_2_outlined,
              text: 'Sol·licitar recurs',
              description: 'Demanar material o eines',
            ),
            _menuItem(
              context,
              value: _TreballadorFabAction.perfil,
              icon: Icons.person_outline,
              text: 'El meu perfil',
              description: 'Veure dades personals i laborals',
            ),
          ],
        );

        if (selected != null) {
          onSelected(selected);
        }
      },
      child: const Icon(Icons.add_rounded),
    );
  }

  PopupMenuItem<_TreballadorFabAction> _menuItem(
    BuildContext context, {
    required _TreballadorFabAction value,
    required IconData icon,
    required String text,
    required String description,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuItem<_TreballadorFabAction>(
      value: value,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.25,
                    ),
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

enum _TreballadorFabAction {
  registreHorari,
  incidencies,
  solRecurs,
  perfil,
}
